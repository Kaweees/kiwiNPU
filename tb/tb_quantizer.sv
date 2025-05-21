`timescale 1ns / 1ps
`include "../include/width.svh"

module tb_quantizer;
  // Declare test bench parameters
  localparam CLK_PERIOD = 10; // Clock period in ns (100MHz clock)
  localparam N = 4; // Vector dimensionality

  // Declare test bench input/output signals
  logic sCLK;
  logic signed [`ACC_WIDTH-1:0] sIN;
  logic signed [`DATA_WIDTH-1:0] sOUT;

  // Instantiate the Quantizer module
  Quantizer DUT (
    .in(sIN),
    .out(sOUT)
  ); // Device Under Testing (DUT)

  // Clock generation
  initial begin
    sCLK = 1'b1;  // Start simulation with positive edge
    // Toggle the clock every 5 ns
    forever #(CLK_PERIOD / 2) sCLK = ~sCLK;
  end;

  initial begin
    // Initialize signals
    sCLK = 0;
    sIN = 0;

    // Test cases
    begin
      // Test case 1: Overflowed positive number
      sIN = 16'h7FFF;
      @(posedge sCLK);
      if (sOUT !== 8'h7F) begin
        $error("Test case 1 failed: Expected 0x%0h, Got 0x%0h", 8'h7F, sOUT);
      end else begin
        $display("Test case 1 passed: Quantizer(0x%0h) = 0x%0h", sIN, sOUT);
      end

      // Test case 2: Overflowed negative number
      sIN = 16'h8000;
      @(posedge sCLK);
      if (sOUT !== 8'h80) begin
        $error("Test case 2 failed: Expected 0x%0h, Got 0x%0h", 8'h80, sOUT);
      end else begin
        $display("Test case 2 passed: Quantizer(0x%0h) = 0x%0h", sIN, sOUT);
      end

      // Test case 3: Non-overflowing positive number
      sIN = 16'h0042;  // 66 in decimal
      @(posedge sCLK);
      if (sOUT !== 8'h42) begin
        $error("Test case 2 failed: Expected 0x%0h, Got 0x%0h", 8'h42, sOUT);
      end else begin
        $display("Test case 2 passed: Quantizer(0x%0h) = 0x%0h", sIN, sOUT);
      end

      // Test case 4: Non-overflowing negative number
      sIN = 16'hFFD6;
      @(posedge sCLK);
      if (sOUT !== 8'hD6) begin
        $error("Test case 3 failed: Expected 0x%0h, Got 0x%0h", 8'hD6, sOUT);
      end else begin
        $display("Test case 3 passed: Quantizer(0x%0h) = 0x%0h", sIN, sOUT);
      end

      // Test case 5: Negative number
      sIN = 16'h8000;
      @(posedge sCLK);
      if (sOUT !== 8'h80) begin
        $error("Test case 4 failed: Expected 0x%0h, Got 0x%0h", 8'hFF, sOUT);
      end else begin
        $display("Test case 4 passed: Quantizer(0x%0h) = 0x%0h", sIN, sOUT);
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
