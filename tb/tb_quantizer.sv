`timescale 1ns / 1ps
`include "../include/width.svh"
`include "../include/quantizer_testcases.svh"

module tb_quantizer;
  // Declare test bench parameters
  localparam CLK_PERIOD = 10; // Clock period in ns (100MHz clock)

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
  end

  initial begin
    // Initialize signals
    sCLK = 1'b0;
    sIN = 'b0;
    init_quantizer_test_cases();

    // Run through all test cases
    for (int i = 0; i < NUM_QUANTIZER_TEST; i++) begin
      sIN = quantizer_test_input[i];

      // Wait for clock edge and check results
      @(posedge sCLK);
      if (sOUT !== quantizer_test_expected[i]) begin
        $error("Test case %03d failed: Expected %0d'b%b (%03d), Got %0d'b%b (%03d)", i, `DATA_WIDTH, quantizer_test_expected[i], quantizer_test_expected[i], `DATA_WIDTH, sOUT, sOUT);
      end else begin
        $display("Test case %03d passed: Quantizer(%0d'b%b) = %0d'b%b", i, `ACC_WIDTH, sIN, `DATA_WIDTH, sOUT);
      end
    end

    $display("All tests completed!");
    $finish(); // Terminate simulation
  end

  // Waveform dump
  initial begin
    $dumpfile("tb_quantizer.vcd");
    $dumpvars(0, tb_quantizer);
  end
endmodule
