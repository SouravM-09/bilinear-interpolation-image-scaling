`timescale 1ns / 1ps

module tb_bilinear_scaler();

    // =========================================================================
    // Master Testbench Parameters
    // =========================================================================
    // We use a small image for simulation so it finishes quickly.
    localparam TB_W_IN     = 500;
    localparam TB_H_IN     = 500;
    localparam TB_W_OUT    = 250;
    localparam TB_H_OUT    = 250;
    localparam TB_CHANNELS = 3; // 3 for RGB, 1 for Grayscale

    // =========================================================================
    // DUT Signals
    // =========================================================================
    reg                               clk;
    reg                               rst_n;
    reg                               start;

    wire [31:0]                       rd_addr_a;
    wire [31:0]                       rd_addr_b;
    wire [(TB_CHANNELS*8)-1:0]        pixel_in_a;
    wire [(TB_CHANNELS*8)-1:0]        pixel_in_b;

    wire [31:0]                       wr_addr;
    wire [(TB_CHANNELS*8)-1:0]        pixel_out;
    wire                              wr_en;
    wire                              done;

    // =========================================================================
    // Simulated Memory (Block RAM)
    // =========================================================================
    // Memory arrays to hold the input and output images
    reg [(TB_CHANNELS*8)-1:0] ram_in  [0:(TB_W_IN * TB_H_IN)-1];
    reg [(TB_CHANNELS*8)-1:0] ram_out [0:(TB_W_OUT * TB_H_OUT)-1];

    // Simulate Dual-Port Read (Continuous assignment fetches data immediately)
    // In a real FPGA, Block RAM has a 1-cycle delay, but this is functionally equivalent
    // for our FSM which waits a cycle anyway.
    assign pixel_in_a = ram_in[rd_addr_a];
    assign pixel_in_b = ram_in[rd_addr_b];

    // Simulate Single-Port Write
    always @(posedge clk) begin
        if (wr_en) begin
            ram_out[wr_addr] <= pixel_out;
        end
    end

    // =========================================================================
    // Instantiate the Design Under Test (DUT)
    // =========================================================================
    bilinear_scaler #(
        .W_IN(TB_W_IN),
        .H_IN(TB_H_IN),
        .W_OUT(TB_W_OUT),
        .H_OUT(TB_H_OUT),
        .CHANNELS(TB_CHANNELS)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        
        .rd_addr_a(rd_addr_a),
        .rd_addr_b(rd_addr_b),
        .pixel_in_a(pixel_in_a),
        .pixel_in_b(pixel_in_b),
        
        .wr_addr(wr_addr),
        .pixel_out(pixel_out),
        .wr_en(wr_en),
        .done(done)
    );

    // =========================================================================
    // Clock Generation
    // =========================================================================
    // Generates a 100MHz clock (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // =========================================================================
    // Main Test Sequence
    // =========================================================================
    initial begin
        // 1. Initialize Inputs
        rst_n = 0;
        start = 0;

        // 2. Load the input image hex file into the simulated RAM
        // (We will need a python script to generate this file!)
        $readmemh("input_image.hex", ram_in);
        
        $display("Starting Bilinear Scaler Simulation...");

        // 3. Release Reset and apply Start pulse
        #20;
        rst_n = 1;
        #10;
        start = 1;
        #10;
        start = 0; // Start is just a 1-cycle pulse

        // 4. Wait for the module to finish
        // We use a timeout just in case the FSM gets stuck, so it doesn't run forever
        wait(done == 1'b1);
        $display("Scaling Complete!");

        // 5. Dump the simulated output RAM into a new hex file
        $writememh("output_image.hex", ram_out);
        $display("Output written to output_image.hex");

        // 6. End Simulation
        #20;
        $finish;
    end

endmodule
