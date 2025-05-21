`timescale 1ns / 1ps
`include "../include/dotproduct_testcases.svh"
`include "../include/width.svh"

module tb_dotproduct();
  // Declare test bench parameters
  localparam CLK_PERIOD = 10; // Clock period in ns (100MHz clock)
  localparam N = 4; // Vector dimensionality

  // Declare test bench input/output signals
  logic sCLK;
  logic signed [`DATA_WIDTH-1:0] sX[N], sW[N];
  logic signed [`ACC_WIDTH-1:0] sOUT;

  // Instantiate the DotProduct module
  DotProduct #(
    .N(N)
  ) DUT (
    .x(sX),
    .w(sW),
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
    init_dotproduct_test_cases();

    // Run through all test cases
    for (int i = 0; i < NUM_DOT_PRODUCT_TEST; i++) begin
      // Load test vectors
      for (int j = 0; j < N; j++) begin
        sX[j] = dotproduct_test_x[i][j];
        sW[j] = dotproduct_test_w[i][j];
      end

      // Wait for clock edge and check results
      @(posedge sCLK);
      if (sOUT !== dotproduct_test_expected[i]) begin
        $error("Test case 0x%0d failed: Expected 0x%0h, Got 0x%0h", i, dotproduct_test_expected[i], sOUT);
      end else begin
        $display("Test case 0x%0d passed: Dot product = 0x%0h", i, sOUT);
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
