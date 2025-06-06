`timescale 1ns / 1ps
`include "../include/width.svh"
`include "../include/layer_testcases.svh"

// Function to get layer size must be defined before the module
function automatic int get_layer_size(int idx);
  int sizes[`NUM_LAYERS] = `LAYER_SIZES;  // Define the array explicitly
  return sizes[idx];
endfunction

module tb_layer ();
  // Declare test bench parameters
  localparam CLK_PERIOD = 10;  // Clock period in ns (100MHz clock)
  localparam PIPELINE_STAGES = 2;  // Number of pipeline stages in the Perceptron
  localparam OUT_N = get_layer_size(1);  // Get LAYER_SIZES[1]

  // Declare test bench input/output signals
  logic sCLK, sRST_N;
  logic signed [             `DATA_WIDTH - 1 : 0] sX_arr                [   `N];
  logic signed [             `DATA_WIDTH - 1 : 0] sW_arr                [   `N] [OUT_N];
  logic signed [             `DATA_WIDTH - 1 : 0] sB_arr                [OUT_N];
  logic signed [             `DATA_WIDTH - 1 : 0] sY_arr                [OUT_N];
  logic signed [        `N * `DATA_WIDTH - 1 : 0] sX;  // Packed vectors
  logic signed [OUT_N * `N * `DATA_WIDTH - 1 : 0] sW;  // Packed vectors
  logic signed [OUT_N * `DATA_WIDTH - 1 : 0] sB, sY;  // Packed vectors
  logic signed [OUT_N * `DATA_WIDTH - 1 : 0] sY_expected;  // Packed vectors

  // Pack the input vectors into bit vectors
  always_comb begin
    for (int i = 0; i < `N; i++) begin
      sX[i*`DATA_WIDTH+:`DATA_WIDTH] = sX_arr[i];
    end
  end

  // Pack the weights into bit vector
  always_comb begin
    for (int i = 0; i < OUT_N; i++) begin
      for (int j = 0; j < `N; j++) begin
        sW[(i*`N+j)*`DATA_WIDTH+:`DATA_WIDTH] = sW_arr[j][i];
      end
    end
  end

  // Pack the biases into bit vector
  always_comb begin
    for (int i = 0; i < OUT_N; i++) begin
      sB[i*`DATA_WIDTH+:`DATA_WIDTH] = sB_arr[i];
    end
  end

  // Instantiate the Layer module
  Layer #(
    .IN_N      (`N),
    .OUT_N     (OUT_N),
    .DATA_WIDTH(`DATA_WIDTH),
    .ACC_WIDTH (`ACC_WIDTH)
  ) DUT (
    .clk    (sCLK),
    .rst_n  (sRST_N),
    .in_vec (sX),
    .weights(sW),
    .biases (sB),
    .out_vec(sY)
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
    init_layer_test_cases();

    // Reset for a few clock cycles
    @(posedge sCLK);
    sRST_N = 1'b1;  // Release reset

    // Run through all test cases
    for (int i = 0; i < NUM_LAYER_TEST; i++) begin
      // Load test vectors
      for (int j = 0; j < `N; j++) begin
        sX_arr[j] = layer_test_x[i][j];
        for (int k = 0; k < OUT_N; k++) begin
          sW_arr[j][k] = layer_test_w[i][j][k];
        end
      end
      for (int j = 0; j < OUT_N; j++) begin
        sB_arr[j]                               = layer_test_b[i][j];
        sY_expected[j*`DATA_WIDTH+:`DATA_WIDTH] = layer_test_expected[i][j];
      end

      // Wait for clock edge and check results
      for (int stage = 0; stage < PIPELINE_STAGES; stage++) begin
        @(posedge sCLK);
      end

      // Check each output separately
      for (int j = 0; j < OUT_N; j++) begin
        if (sY[j*`DATA_WIDTH+:`DATA_WIDTH] !== sY_expected[j*`DATA_WIDTH+:`DATA_WIDTH]) begin
          $error("Test case %03d output %d failed: Expected %0d'b%b (%03d), Got %0d'b%b (%03d)", i,
                 j, `DATA_WIDTH, sY_expected[j*`DATA_WIDTH+:`DATA_WIDTH],
                 sY_expected[j*`DATA_WIDTH+:`DATA_WIDTH], `DATA_WIDTH,
                 sY[j*`DATA_WIDTH+:`DATA_WIDTH], sY[j*`DATA_WIDTH+:`DATA_WIDTH]);
        end else begin
          $display("Test case %03d output %d passed: Got %0d'b%b", i, j, `DATA_WIDTH,
                   sY[j*`DATA_WIDTH+:`DATA_WIDTH]);
        end
      end
    end

    $display("All tests completed!");
    $finish();  // Terminate simulation
  end

  // Waveform dump
  initial begin
    $dumpfile("tb_layer.vcd");
    $dumpvars(0, tb_layer);
  end
endmodule
