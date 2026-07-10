`timescale 1ns / 1ps

module bilinear_scaler #(
    // Default parameters (can be overridden during instantiation)
    parameter W_IN     = 500,
    parameter H_IN     = 500,
    parameter W_OUT    = 250,
    parameter H_OUT    = 250,
    parameter CHANNELS = 3    // 1 for Grayscale, 3 for RGB
)(
    input  wire                   clk,
    input  wire                   rst_n, // Active-low reset
    input  wire                   start,

    // =======================================================
    // UPDATED: Dual-Port Memory Read Interface (Input Image)
    // =======================================================
    output reg  [31:0]            rd_addr_a,
    output reg  [31:0]            rd_addr_b,
    input  wire [(CHANNELS*8)-1:0] pixel_in_a,
    input  wire [(CHANNELS*8)-1:0] pixel_in_b,

    // Memory Write Interface (Output Image)
    output reg  [31:0]            wr_addr,
    output reg  [(CHANNELS*8)-1:0] pixel_out,
    output reg                    wr_en,
    
    // Status
    output reg                    done
);

    // =========================================================================
    // Compile-Time Constant Scale Factors (Q24.8 format)
    // =========================================================================
    localparam [31:0] SCALE_X = (W_IN << 8) / W_OUT;
    localparam [31:0] SCALE_Y = (H_IN << 8) / H_OUT;

    // =========================================================================
    // Internal Registers
    // =========================================================================
    reg [31:0] x_out, y_out;
    reg [31:0] x_acc, y_acc;
    
    // Fractional weights (8-bit)
    reg [7:0] a, b;
    
    // Bounding box integer coordinates
    reg [31:0] x0, y0, x1, y1;

    // Pixel storage registers
    reg [(CHANNELS*8)-1:0] p00, p10, p01, p11;
    reg [(CHANNELS*8)-1:0] pixel_top, pixel_bot;

    // Loop variable for color channels
    integer k;

    // =========================================================================
    // Optimized FSM State Encoding
    // =========================================================================
    localparam S_IDLE                 = 4'd0,
               S_CALC_COORDS          = 4'd1,
               
               // Dual-Port Fetch States
               S_FETCH_ROW0           = 4'd2,
               S_WAIT_ROW0            = 4'd3,
               S_LATCH_ROW0_WAIT_ROW1 = 4'd4,
               S_LATCH_ROW1           = 4'd5,
               
               // Separable Math Datapath
               S_INTERP_H             = 4'd6,
               S_INTERP_V             = 4'd7,
               
               // Control States
               S_NEXT_PIXEL           = 4'd8,
               S_DONE                 = 4'd9;

    reg [3:0] state;

    // =========================================================================
    // FSM and Datapath Logic
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_IDLE;
            done      <= 0;
            wr_en     <= 0;
            x_out     <= 0;
            y_out     <= 0;
            x_acc     <= 0;
            y_acc     <= 0;
            rd_addr_a <= 0;
            rd_addr_b <= 0;
        end else begin
            case(state)
                
                S_IDLE: begin
                    done  <= 0;
                    wr_en <= 0;
                    if (start) begin
                        x_out <= 0;
                        y_out <= 0;
                        x_acc <= 0;
                        y_acc <= 0;
                        state <= S_CALC_COORDS;
                    end
                end

                S_CALC_COORDS: begin
                    // 1. Extract integer coordinates
                    x0 = x_acc >> 8;
                    y0 = y_acc >> 8;

                    // 2. Extract fractional weights
                    a <= x_acc[7:0];
                    b <= y_acc[7:0];

                    // 3. Boundary clamping
                    if (x0 >= W_IN - 1) begin
                        x0 = W_IN - 1;
                        x1 = W_IN - 1;
                    end else begin
                        x1 = x0 + 1;
                    end

                    if (y0 >= H_IN - 1) begin
                        y0 = H_IN - 1;
                        y1 = H_IN - 1;
                    end else begin
                        y1 = y0 + 1;
                    end

                    state <= S_FETCH_ROW0;
                end
                
                // =============================================================
                // Memory Fetch Phase (Dual-Port)
                // =============================================================
                S_FETCH_ROW0: begin
                    rd_addr_a <= y0 * W_IN + x0; // Top-left
                    rd_addr_b <= y0 * W_IN + x1; // Top-right
                    state     <= S_WAIT_ROW0;
                end

                S_WAIT_ROW0: begin
                    rd_addr_a <= y1 * W_IN + x0; // Bottom-left
                    rd_addr_b <= y1 * W_IN + x1; // Bottom-right
                    state     <= S_LATCH_ROW0_WAIT_ROW1;
                end

                S_LATCH_ROW0_WAIT_ROW1: begin
                    p00 <= pixel_in_a;
                    p10 <= pixel_in_b;
                    state <= S_LATCH_ROW1;
                end

                S_LATCH_ROW1: begin
                    p01 <= pixel_in_a;
                    p11 <= pixel_in_b;
                    state <= S_INTERP_H;
                end

                // =============================================================
                // Math Phase (Separable 1D Interpolation)
                // =============================================================
                S_INTERP_H: begin
                    // Interpolate Horizontally using (255 - a) for strict 8-bit limit
                    // Adding +128 ensures nearest-integer rounding before shifting
                    for (k = 0; k < CHANNELS; k = k + 1) begin
                        pixel_top[k*8 +: 8] <= (( (255 - a) * p00[k*8 +: 8] ) + ( a * p10[k*8 +: 8] ) + 128) >> 8;
                        pixel_bot[k*8 +: 8] <= (( (255 - a) * p01[k*8 +: 8] ) + ( a * p11[k*8 +: 8] ) + 128) >> 8;
                    end
                    state <= S_INTERP_V;
                end

                S_INTERP_V: begin
                    // Interpolate Vertically
                    for (k = 0; k < CHANNELS; k = k + 1) begin
                        pixel_out[k*8 +: 8] <= (( (255 - b) * pixel_top[k*8 +: 8] ) + ( b * pixel_bot[k*8 +: 8] ) + 128) >> 8;
                    end
                    
                    wr_addr <= y_out * W_OUT + x_out;
                    wr_en   <= 1;
                    state   <= S_NEXT_PIXEL;
                end

                // =============================================================
                // Control Phase
                // =============================================================
                S_NEXT_PIXEL: begin
                    wr_en <= 0; // De-assert write enable immediately
                    
                    // Increment X Accumulator
                    x_acc <= x_acc + SCALE_X;
                    
                    if (x_out < W_OUT - 1) begin
                        x_out <= x_out + 1;
                        state <= S_CALC_COORDS;
                    end else begin
                        // End of row: Reset X, Increment Y Accumulator
                        x_out <= 0;
                        x_acc <= 0;
                        y_acc <= y_acc + SCALE_Y;
                        
                        if (y_out < H_OUT - 1) begin
                            y_out <= y_out + 1;
                            state <= S_CALC_COORDS;
                        end else begin
                            // End of image
                            state <= S_DONE;
                        end
                    end
                end

                S_DONE: begin
                    done <= 1;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule       
