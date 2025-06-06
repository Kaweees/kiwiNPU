`timescale 1ns / 1ps
`include "../include/width.svh"
`include "../include/perceptron_testcases.svh"

module tb_perceptron ();
  // Declare test bench parameters
  localparam CLK_PERIOD = 10;  // Clock period in ns (100MHz clock)
  localparam PIPELINE_STAGES = 3;  // Number of pipeline stages in the Perceptron

  // Declare test bench input/output signals
  logic sCLK, sRST_N;
  logic signed [`DATA_WIDTH - 1 : 0] sX_arr[`N], sW_arr[`N], sB, sY;
  logic signed [`N * `DATA_WIDTH - 1 : 0] sX, sW;  // Packed vectors

  // Pack the arrays into bit vectors
  always_comb begin
    for (int i = 0; i < `N; i++) begin
      sX[i*`DATA_WIDTH+:`DATA_WIDTH] = sX_arr[i];
      sW[i*`DATA_WIDTH+:`DATA_WIDTH] = sW_arr[i];
    end
  end

  // Instantiate the Perceptron module
  Perceptron #(
    .N(`N)
  ) DUT (
    .clk  (sCLK),
    .rst_n(sRST_N),
    .x    (sX),
    .w    (sW),
    .b    (sB),
    .y    (sY)
  );

  // Clock generation
  initial begin
    sCLK = 1'b1;  // Start simulation with positive edge
    // Toggle the clock every 5 ns
    forever #(CLK_PERIOD / 2) sCLK = ~sCLK;
  end

  initial begin
    // Initialize signals
    sCLK   = 1'b0;
    sRST_N = 1'b0;
    init_perceptron_test_cases();

    // Reset for a few clock cycles
    @(posedge sCLK);
    sRST_N = 1'b1;  // Release reset

    // Run through all test cases
    for (int i = 0; i < NUM_PERCEPTRON_TEST; i++) begin
      // Load test vectors
      for (int j = 0; j < `N; j++) begin
        sX_arr[j] = perceptron_test_x[i][j];
        sW_arr[j] = perceptron_test_w[i][j];
      end
      sB = perceptron_test_b[i];

      // Wait for clock edge and check results
      for (int stage = 0; stage < PIPELINE_STAGES; stage++) begin
        @(posedge sCLK);
      end
      if (sY !== perceptron_test_expected[i]) begin
        $error({"Test case %03d failed: Expected %0d'b%b (%03d), Got %0d'b%b ", "(%03d)"}, i,
                 `DATA_WIDTH, perceptron_test_expected[i], perceptron_test_expected[i],
                 `DATA_WIDTH, sY, sY);
      end else begin
        $display("Test case %03d passed: Perceptron(%0d'b%b, %0d'b%b) = %0d'b%b", i, `DATA_WIDTH,
                 sX, `DATA_WIDTH, sW, `DATA_WIDTH, sY);
      end
    end

    $display("All tests completed!");
    $finish();  // Terminate simulation
  end

  // Waveform dump
  initial begin
    $dumpfile("tb_perceptron.vcd");
    $dumpvars(0, tb_perceptron);
  end
endmodule
