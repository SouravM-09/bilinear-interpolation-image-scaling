`timescale 1ns / 1ps

module image_scaler_fsm #(
    parameter W_IN     = 500,
    parameter H_IN     = 500,
    parameter W_OUT    = 1000,
    parameter H_OUT    = 1000,
    parameter CHANNELS = 3
)(
    input wire clk,
    input wire rst_n,
    input wire start,

    output reg [31:0] rd_addr,
    input wire [CHANNELS*8-1:0] pixel_in,

    output reg [31:0] wr_addr,
    output reg [CHANNELS*8-1:0] pixel_out,
    output reg wr_en,
    output reg done
);

    // ================================
    // Compile-time Q8.8 scale factors
    // ================================
    localparam [31:0] SCALE_X = (W_IN << 8) / W_OUT;
    localparam [31:0] SCALE_Y = (H_IN << 8) / H_OUT;

    // ================================
    // FSM States
    // ================================
    localparam S_IDLE        = 0,
               S_INIT_Y      = 1,
               S_INIT_X      = 2,
               S_CALC_COORDS = 3,

               S_F0_ADDR = 4,  S_F0_WAIT = 5,  S_F0_DATA = 6,
               S_F1_ADDR = 7,  S_F1_WAIT = 8,  S_F1_DATA = 9,
               S_F2_ADDR = 10, S_F2_WAIT = 11, S_F2_DATA = 12,
               S_F3_ADDR = 13, S_F3_WAIT = 14, S_F3_DATA = 15,

               S_COMPUTE = 16,
               S_NEXT_X  = 17,
               S_NEXT_Y  = 18,
               S_DONE    = 19;

    reg [4:0] state;

    // Coordinates
    reg [31:0] x_out, y_out;
    reg [31:0] x_acc, y_acc;

    integer x0, y0, x1, y1;
    reg [7:0] a, b;
    integer k;

    // Pixel storage
    reg [7:0] p00 [0:CHANNELS-1];
    reg [7:0] p10 [0:CHANNELS-1];
    reg [7:0] p01 [0:CHANNELS-1];
    reg [7:0] p11 [0:CHANNELS-1];

    reg signed [31:0] res [0:CHANNELS-1];

    // ================================
    // FSM
    // ================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            done  <= 0;
            wr_en <= 0;
            x_out <= 0;
            y_out <= 0;
            x_acc <= 0;
            y_acc <= 0;
        end
        else begin
            case(state)

            S_IDLE: begin
                done <= 0;
                if (start)
                    state <= S_INIT_Y;
            end

            S_INIT_Y: begin
                y_out <= 0;
                y_acc <= 0;
                state <= S_INIT_X;
            end

            S_INIT_X: begin
                x_out <= 0;
                x_acc <= 0;
                state <= S_CALC_COORDS;
            end

            S_CALC_COORDS: begin
                x0 = x_acc >> 8;
                y0 = y_acc >> 8;

                if (x0 >= W_IN-1) x0 = W_IN-2;
                if (y0 >= H_IN-1) y0 = H_IN-2;

                x1 = x0 + 1;
                y1 = y0 + 1;

                a <= x_acc[7:0];
                b <= y_acc[7:0];

                state <= S_F0_ADDR;
            end

            // =============================
            // Fetch p00
            // =============================
            S_F0_ADDR: begin
                rd_addr <= y0 * W_IN + x0;
                state   <= S_F0_WAIT;
            end

            S_F0_WAIT: begin
                state <= S_F0_DATA;
            end

            S_F0_DATA: begin
                for (k=0; k<CHANNELS; k=k+1)
                    p00[k] <= pixel_in[k*8 +: 8];
                state <= S_F1_ADDR;
            end

            // =============================
            // Fetch p10
            // =============================
            S_F1_ADDR: begin
                rd_addr <= y0 * W_IN + x1;
                state   <= S_F1_WAIT;
            end

            S_F1_WAIT: begin
                state <= S_F1_DATA;
            end

            S_F1_DATA: begin
                for (k=0; k<CHANNELS; k=k+1)
                    p10[k] <= pixel_in[k*8 +: 8];
                state <= S_F2_ADDR;
            end

            // =============================
            // Fetch p01
            // =============================
            S_F2_ADDR: begin
                rd_addr <= y1 * W_IN + x0;
                state   <= S_F2_WAIT;
            end

            S_F2_WAIT: begin
                state <= S_F2_DATA;
            end

            S_F2_DATA: begin
                for (k=0; k<CHANNELS; k=k+1)
                    p01[k] <= pixel_in[k*8 +: 8];
                state <= S_F3_ADDR;
            end

            // =============================
            // Fetch p11
            // =============================
            S_F3_ADDR: begin
                rd_addr <= y1 * W_IN + x1;
                state   <= S_F3_WAIT;
            end

            S_F3_WAIT: begin
                state <= S_F3_DATA;
            end

            S_F3_DATA: begin
                for (k=0; k<CHANNELS; k=k+1)
                    p11[k] <= pixel_in[k*8 +: 8];
                state <= S_COMPUTE;
            end

            // =============================
            // Bilinear Interpolation
            // =============================
            S_COMPUTE: begin
                for (k=0; k<CHANNELS; k=k+1) begin
                    res[k] = ((256-a)*(256-b)*p00[k] +
                              a*(256-b)*p10[k] +
                              (256-a)*b*p01[k] +
                              a*b*p11[k] + 32768) >> 16;

                    if (res[k] > 255)
                        res[k] = 255;

                    pixel_out[k*8 +: 8] <= res[k][7:0];
                end

                wr_addr <= y_out * W_OUT + x_out;
                wr_en   <= 1;
                state   <= S_NEXT_X;
            end

            S_NEXT_X: begin
                wr_en <= 0;
                x_acc <= x_acc + SCALE_X;

                if (x_out < W_OUT-1) begin
                    x_out <= x_out + 1;
                    state <= S_CALC_COORDS;
                end
                else
                    state <= S_NEXT_Y;
            end

            S_NEXT_Y: begin
                y_acc <= y_acc + SCALE_Y;

                if (y_out < H_OUT-1) begin
                    y_out <= y_out + 1;
                    state <= S_INIT_X;
                end
                else
                    state <= S_DONE;
            end

            S_DONE: begin
                done <= 1;
            end

            endcase
        end
    end

endmodule
