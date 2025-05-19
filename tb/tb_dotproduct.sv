`timescale 1ns / 1ps
`include "../include/dotproduct_testcases.svh"

module tb_dotproduct();
  // Declare test bench parameters
  localparam CLK_PERIOD = 10; // Clock period in ns (100MHz clock)
  localparam WIDTH = 8; // Bit width
  localparam N = 4; // Vector dimensionality

  // Declare test bench input/output signals
  logic sCLK;
  logic signed [WIDTH-1:0] sA[N], sB[N], sOUT;

  // Instantiate the DotProduct module
  DotProduct #(
    .WIDTH(WIDTH),
    .N(N)
  ) DUT (
    .a(sA),
    .b(sB),
    .out(sOUT)
  ); // Device Under Testing (DUT)

  // Clock generation
  initial begin
    sCLK = 1'b1;  // Start simulation with positive edge
    // Toggle the clock every 5 ns
    forever #(CLK_PERIOD / 2) sCLK = ~sCLK;
  end

  initial begin
    // Initialize signals
    sCLK = 0;
    sA = {8'h00, 8'h00, 8'h00, 8'h00};
    sB = {8'h00, 8'h00, 8'h00, 8'h00};

    // Test cases
    begin
      // Test Case 1: Zero
      sA = {8'h00, 8'h00, 8'h00, 8'h00};
      sB = {8'h00, 8'h00, 8'h00, 8'h00};
      @(posedge sCLK);
      if (sOUT !== 8'h00) begin
        $error("Test Case 1 failed: Expected 0x%0h, Got 0x%0h", 8'h00, sOUT);
      end else begin
        $display("Test Case 1 passed: ReLU(0x%0h) = 0x%0h", sA, sOUT);
      end

      // Test Case 2: Positive number
      sA = {8'h03, 8'h01, 8'h01, 8'h02};
      sB = {8'h03, 8'h01, 8'h02, 8'h01};
      @(posedge sCLK);
      if (sOUT !== 8'h0E) begin
        $error("Test Case 2 failed: Expected 0x%0h, Got 0x%0h", 8'h0E, sOUT);
      end else begin
        $display("Test Case 2 passed: ReLU(0x%0h) = 0x%0h", sA, sOUT);
      end

      // Test Case 3: Negative number
      sA = {8'hFF, 8'hFF, 8'hFF, 8'hFF};
      sB = {8'hFF, 8'hFF, 8'hFF, 8'hFF};
      @(posedge sCLK);
      if (sOUT !== 8'h04) begin
        $error("Test Case 3 failed: Expected 0x%0h, Got 0x%0h", 8'h04, sOUT);
      end else begin
        $display("Test Case 3 passed: ReLU(%0h) = %0h", sA, sOUT);
      end
    end

    $display("All tests completed!");
    $finish(); // Terminate simulation
  end

  // Waveform dump
  initial begin
    $dumpfile("tb_dotproduct.vcd");
    $dumpvars(0, tb_dotproduct);
  end
endmodule
