`timescale 1ns / 1ps
`include "../include/perceptron_testcases.svh"
`include "../include/width.svh"

module tb_perceptron();
  // Declare test bench parameters
  localparam CLK_PERIOD = 10; // Clock period in ns (100MHz clock)
  localparam N = 4; // Vector dimensionality

  // Declare test bench input/output signals
  logic sCLK, sRST_N;
  logic signed [`DATA_WIDTH-1:0] sX[N], sW[N], sB, sY;

  // Instantiate the Perceptron module
  Perceptron #(
    .N(N)
  ) DUT (
    .clk(sCLK),
    .rst_n(sRST_N),
    .x(sX),
    .w(sW),
    .b(sB),
    .y(sY)
  );

  // Clock generation
  initial begin
    sCLK = 1'b1;  // Start simulation with positive edge
    // Toggle the clock every 5 ns
    forever #(CLK_PERIOD / 2) sCLK = ~sCLK;
  end

  initial begin
    // Initialize signals
    sCLK = 0;
    sRST_N = 0;
    init_perceptron_test_cases();

    // Reset for a few clock cycles
    @(posedge sCLK);
    sRST_N = 1;  // Release reset

    // Run through all test cases
    for (int i = 0; i < NUM_PERCEPTRON_TEST; i++) begin
      // Load test vectors
      for (int j = 0; j < N; j++) begin
        sX[j] = perceptron_test_x[i][j];
        sW[j] = perceptron_test_w[i][j];
      end
      sB = perceptron_test_b[i];

      // Wait for clock edge and check results
      @(posedge sCLK);
      @(posedge sCLK);  // Extra cycle to allow for processing

      if (sY !== perceptron_test_expected[i]) begin
        $error("Test case %0d failed: Expected 0x%0h, Got 0x%0h", i, perceptron_test_expected[i], sY);
      end else begin
        $display("Test case %0d passed: Perceptron output = 0x%0h", i, sY);
      end
    end

    $display("All tests completed!");
    $finish(); // Terminate simulation
  end

  // Waveform dump
  initial begin
    $dumpfile("tb_perceptron.vcd");
    $dumpvars(0, tb_perceptron);
  end
endmodule
