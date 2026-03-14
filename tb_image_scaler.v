`timescale 1ns / 1ps

module tb_image_scaler;

    // ==========================================
    // CONFIGURATION
    // ==========================================
    parameter W_IN     = 500;
    parameter H_IN     = 500;
    parameter W_OUT    = 1000;
    parameter H_OUT    = 1000;
    parameter CHANNELS = 3;   // 1 = Gray, 3 = RGB

    localparam BIT_WIDTH = CHANNELS * 8;

    // ==========================================
    // SIGNALS
    // ==========================================
    reg clk;
    reg rst_n;
    reg start;
    wire done;

    wire [31:0] rd_addr;
    wire [BIT_WIDTH-1:0] rd_data;
    wire [31:0] wr_addr;
    wire [BIT_WIDTH-1:0] wr_data;
    wire wr_en;

    // ==========================================
    // SIMULATED BRAM
    // ==========================================
    reg [BIT_WIDTH-1:0] img_in  [0:W_IN*H_IN-1];
    reg [BIT_WIDTH-1:0] img_out [0:W_OUT*H_OUT-1];

    reg [BIT_WIDTH-1:0] rd_data_reg;

    integer i;

    // ==========================================
    // Instantiate UUT
    // ==========================================
    image_scaler_fsm #(
        .W_IN(W_IN),
        .H_IN(H_IN),
        .W_OUT(W_OUT),
        .H_OUT(H_OUT),
        .CHANNELS(CHANNELS)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .rd_addr(rd_addr),
        .pixel_in(rd_data),
        .wr_addr(wr_addr),
        .pixel_out(wr_data),
        .wr_en(wr_en),
        .done(done)
    );

    // ==========================================
    // 1-CYCLE SYNCHRONOUS READ (REAL BRAM MODEL)
    // ==========================================
    always @(posedge clk) begin
        if (rd_addr < W_IN*H_IN)
            rd_data_reg <= img_in[rd_addr];
        else
            rd_data_reg <= {BIT_WIDTH{1'b0}};
    end

    assign rd_data = rd_data_reg;

    // ==========================================
    // WRITE LOGIC
    // ==========================================
    always @(posedge clk) begin
        if (wr_en) begin
            if (wr_addr < W_OUT*H_OUT)
                img_out[wr_addr] <= wr_data;
        end
    end

    // ==========================================
    // CLOCK (100 MHz)
    // ==========================================
    always #5 clk = ~clk;

    // ==========================================
    // MAIN TEST
    // ==========================================
    initial begin

        // Initialize
        clk   = 0;
        rst_n = 0;
        start = 0;

        // Clear memories
        $display("Clearing memory...");
        for (i = 0; i < W_IN*H_IN; i = i + 1)
            img_in[i] = 0;

        for (i = 0; i < W_OUT*H_OUT; i = i + 1)
            img_out[i] = 0;

        // Load input image
        if (CHANNELS == 3) begin
            $display("Loading RGB input...");
            $readmemh("input_rgb.hex", img_in);
        end
        else begin
            $display("Loading Grayscale input...");
            $readmemh("gray_input.hex", img_in);
        end

        #100;
        rst_n = 1;

        #20;
        start = 1;

        #10;
        start = 0;

        $display("Scaling started...");

        wait(done);

        $display("Scaling finished.");

        // Save output
        if (CHANNELS == 3)
            $writememh("output_rgb.hex", img_out);
        else
            $writememh("output_gray.hex", img_out);

        $display("Output saved.");
        $finish;
    end

endmodule
