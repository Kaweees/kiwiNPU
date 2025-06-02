`timescale 1ns / 1ps
`include "../include/dotproduct_testcases.svh"
`include "../include/width.svh"

module tb_dotproduct();
  // Declare test bench parameters
  localparam CLK_PERIOD = 10; // Clock period in ns (100MHz clock)

  // Declare test bench input/output signals
  logic sCLK;
  logic signed [`DATA_WIDTH - 1 : 0] sX_arr[`N], sW_arr[`N];
  logic signed [`N * `DATA_WIDTH - 1 : 0] sX, sW;  // Packed vectors
  logic signed [`ACC_WIDTH - 1 : 0] sOUT;

  // Pack the arrays into bit vectors
  always_comb begin
    for (int i = 0; i < `N; i++) begin
      sX[i*`DATA_WIDTH+:`DATA_WIDTH] = sX_arr[i];
      sW[i*`DATA_WIDTH+:`DATA_WIDTH] = sW_arr[i];
    end
  end

  // Instantiate the DotProduct module
  DotProduct #(
    .N(`N)
  ) DUT (
    .x(sX),
    .w(sW),
    .dp(sOUT)
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
    init_dotproduct_test_cases();

    // Run through all test cases
    for (int i = 0; i < NUM_DOT_PRODUCT_TEST; i++) begin
      // Load test vectors
      for (int j = 0; j < `N; j++) begin
        sX_arr[j] = dotproduct_test_x[i][j];
      end

      // Wait for clock edge and check results
      @(posedge sCLK);
      if (sOUT !== dotproduct_test_expected[i]) begin
        $error("Test case %03d failed: Expected %0d'b%b (%03d), Got %0d'b%b (%03d)", i, `ACC_WIDTH, dotproduct_test_expected[i], dotproduct_test_expected[i], `ACC_WIDTH, sOUT, sOUT);
      end else begin
        $display("Test case %03d passed: DotProduct(%0d'b%b, %0d'b%b) = %0d'b%b", i, `DATA_WIDTH, sX, `DATA_WIDTH, sW, `ACC_WIDTH, sOUT);
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
