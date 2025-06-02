`timescale 1ns / 1ps
`include "../include/width.svh"

module tb_relu ();
  // Declare test bench parameters
  localparam CLK_PERIOD = 10;  // Clock period in ns (100MHz clock)

  // Declare test bench input/output signals
  logic sCLK;
  logic signed [`DATA_WIDTH - 1 : 0] sIN, sOUT;

  // Instantiate the ReLU module
  ReLU DUT (
    .in (sIN),
    .out(sOUT)
  );  // Device Under Testing (DUT)

  // Clock generation
  initial begin
    sCLK = 1'b1;  // Start simulation with positive edge
    // Toggle the clock every 5 ns
    forever #(CLK_PERIOD / 2) sCLK = ~sCLK;
  end

  initial begin
    // Initialize signals
    sCLK = 0;
    sIN  = 0;

    // Test cases
    begin
      // Test Case 1: Positive number
      sIN = 8'h01;  // Some positive number
      @(posedge sCLK);
      if (sOUT !== sIN) begin
        $error("Test Case 1 failed: Expected 0x%0h, Got 0x%0h", sIN, sOUT);
      end else begin
        $display("Test Case 1 passed: ReLU(0x%0h) = 0x%0h", sIN, sOUT);
      end

      // Test Case 2: Zero
      sIN = 8'h00;
      @(posedge sCLK);
      if (sOUT !== sIN) begin
        $error("Test Case 2 failed: Expected 0x%0h, Got 0x%0h", sIN, sOUT);
      end else begin
        $display("Test Case 2 passed: ReLU(0x%0h) = 0x%0h", sIN, sOUT);
      end

      // Test Case 3: Negative number
      sIN = 8'hFF;  // Some negative number (MSB=1)
      @(posedge sCLK);
      if (sOUT !== 8'h00) begin
        $error("Test Case 3 failed: Expected 0x%0h, Got 0x%0h", 8'h00, sOUT);
      end else begin
        $display("Test Case 3 passed: ReLU(%0h) = %0h", sIN, sOUT);
      end
    end

    $display("All tests completed!");
    $finish();  // Terminate simulation
  end

  // Waveform dump
  initial begin
    $dumpfile("tb_relu.vcd");
    $dumpvars(0, tb_relu);
  end
endmodule
