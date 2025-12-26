`timescale 1ns / 1ps
`include "../include/width.svh"
`include "../include/preactivation_testcases.svh"

module tb_preactivation ();
  // Declare test bench parameters
  localparam CLK_PERIOD = 10;  // Clock period in ns (100MHz clock)

  // Declare test bench input/output signals
  logic sCLK, sRST_N;
  logic signed [`DATA_WIDTH - 1 : 0] sX_arr[`N], sW_arr[`N];
  logic signed [`N * `DATA_WIDTH - 1 : 0] sX, sW;  // Packed vectors
  logic signed [`DATA_WIDTH - 1 : 0] sB;
  logic signed [ `ACC_WIDTH - 1 : 0] sOUT;

  // Pack the arrays into bit vectors
  always_comb begin
    for (int i = 0; i < `N; i++) begin
      sX[i*`DATA_WIDTH+:`DATA_WIDTH] = sX_arr[i];
      sW[i*`DATA_WIDTH+:`DATA_WIDTH] = sW_arr[i];
    end
  end

  // Instantiate the PreActivation module
  PreActivation #(
    .N         (`N),
    .DATA_WIDTH(`DATA_WIDTH),
    .ACC_WIDTH (`ACC_WIDTH)
  ) DUT (
    // .clk  (sCLK),    // Add clock connection
    // .rst_n(sRST_N),    // Add reset connection (active low, tied high for now)
    .x  (sX),
    .w  (sW),
    .b  (sB),
    .pre(sOUT)
  );  // Device Under Testing (DUT)

  // Clock generation
  initial begin
    sCLK   = 1'b1;  // Start simulation with positive edge
    sRST_N = 1'b1;  // Reset is active low
    // Toggle the clock every 5 ns
    forever #(CLK_PERIOD / 2) sCLK = ~sCLK;
  end

  initial begin
    // Initialize signals
    sCLK   = 1'b0;
    sRST_N = 1'b0;
    init_preactivation_test_cases();

    // Run through all test cases
    for (int i = 0; i < NUM_PREACTIVATION_TEST; i++) begin
      // Load test vectors
      for (int j = 0; j < `N; j++) begin
        sX_arr[j] = preactivation_test_x[i][j];
        sW_arr[j] = preactivation_test_w[i][j];
      end
      sB = preactivation_test_b[i];  // Load bias

      // Wait for clock edge and check results
      @(posedge sCLK);
      if (sOUT !== preactivation_test_expected[i]) begin
        $error({"Test case %03d failed: Expected %0d'b%b (%03d), Got %0d'b%b ", "(%03d)"}, i,
                 `ACC_WIDTH, preactivation_test_expected[i], preactivation_test_expected[i],
                 `ACC_WIDTH, sOUT, sOUT);
      end else begin
        $display("Test case %03d passed: PreActivation(%0d'b%b, %0d'b%b) = %0d'b%b", i,
                 `DATA_WIDTH, sX, `DATA_WIDTH, sW, `ACC_WIDTH, sOUT);
      end
    end

    $display("All tests completed!");
    $finish();  // Terminate simulation
  end

  // Waveform dump
  initial begin
    $dumpfile("tb_preactivation.vcd");
    $dumpvars(0, tb_preactivation);
  end
endmodule
