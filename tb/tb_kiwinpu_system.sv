`include "../include/width.svh"
`include "../include/dotproduct_testcases.svh"
`include "../include/perceptron_testcases.svh"

module tb_kiwinpu_system;

  // Parameters
  localparam int IN_N = `N;
  localparam int HIDDEN_N = `M;
  localparam int OUT_N = `N;
  localparam int DATA_WIDTH = `DATA_WIDTH;
  localparam int ACC_WIDTH = `ACC_WIDTH;

  // Clock and reset
  logic                               clk;
  logic                               rst_n;

  // SPI Interface
  logic                               flash_csb;
  logic                               flash_clk;
  logic                               flash_io0_oe;
  logic                               flash_io1_oe;
  logic                               flash_io2_oe;
  logic                               flash_io3_oe;
  logic                               flash_io0_do;
  logic                               flash_io1_do;
  logic                               flash_io2_do;
  logic                               flash_io3_do;
  logic                               flash_io0_di;
  logic                               flash_io1_di;
  logic                               flash_io2_di;
  logic                               flash_io3_di;

  // Input/Output vectors
  logic signed [ IN_N*DATA_WIDTH-1:0] in_vec;
  logic signed [OUT_N*DATA_WIDTH-1:0] out_vec;

  // Test vectors
  logic signed [ IN_N*DATA_WIDTH-1:0] test_inputs     [10];
  logic signed [OUT_N*DATA_WIDTH-1:0] expected_outputs[10];

  // Instantiate KiwiNPU_System
  KiwiNPU_System #(
    .IN_N      (IN_N),
    .HIDDEN_N  (HIDDEN_N),
    .OUT_N     (OUT_N),
    .DATA_WIDTH(DATA_WIDTH),
    .ACC_WIDTH (ACC_WIDTH)
  ) dut (
    .clk         (clk),
    .rst_n       (rst_n),
    .flash_csb   (flash_csb),
    .flash_clk   (flash_clk),
    .flash_io0_oe(flash_io0_oe),
    .flash_io1_oe(flash_io1_oe),
    .flash_io2_oe(flash_io2_oe),
    .flash_io3_oe(flash_io3_oe),
    .flash_io0_do(flash_io0_do),
    .flash_io1_do(flash_io1_do),
    .flash_io2_do(flash_io2_do),
    .flash_io3_do(flash_io3_do),
    .flash_io0_di(flash_io0_di),
    .flash_io1_di(flash_io1_di),
    .flash_io2_di(flash_io2_di),
    .flash_io3_di(flash_io3_di),
    .in_vec      (in_vec),
    .out_vec     (out_vec)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test stimulus
  initial begin
    // Initialize test vectors
    init_dotproduct_test_cases();
    init_perceptron_test_cases();

    // Initialize SPI flash memory with test weights
    initialize_spi_flash();

    // Reset sequence
    rst_n = 0;
    #100;
    rst_n = 1;
    #100;

    // Wait for weights to be loaded
    wait (dut.weight_loader.weights_ready);
    #100;

    // Run test cases
    for (int i = 0; i < 10; i++) begin
      // Apply test input
      in_vec = test_inputs[i];
      #100;

      // Check output
      if (out_vec !== expected_outputs[i]) begin
        $display("Test case %0d failed", i);
        $display("Expected: %h", expected_outputs[i]);
        $display("Got: %h", out_vec);
        $finish;
      end
      #100;
    end

    $display("All test cases passed!");
    $finish;
  end

  // Task to initialize SPI flash memory
  task initialize_spi_flash;
    // Initialize SPI flash with test weights
    // This is a simplified version - you'll need to implement the actual SPI flash model
    // based on your specific flash memory device

    // Wait for chip select to be asserted
    @(posedge flash_csb);

    // Send test weights
    // First layer weights
    for (int i = 0; i < HIDDEN_N * IN_N * DATA_WIDTH / 8; i++) begin
      // Simulate SPI flash response
      flash_io0_di = 1'b1;  // Dummy data
      @(posedge flash_clk);
    end

    // First layer biases
    for (int i = 0; i < HIDDEN_N * DATA_WIDTH / 8; i++) begin
      flash_io0_di = 1'b1;  // Dummy data
      @(posedge flash_clk);
    end

    // Second layer weights
    for (int i = 0; i < OUT_N * HIDDEN_N * DATA_WIDTH / 8; i++) begin
      flash_io0_di = 1'b1;  // Dummy data
      @(posedge flash_clk);
    end

    // Second layer biases
    for (int i = 0; i < OUT_N * DATA_WIDTH / 8; i++) begin
      flash_io0_di = 1'b1;  // Dummy data
      @(posedge flash_clk);
    end
  endtask

  // Monitor for debugging
  initial begin
    $monitor("Time=%0t rst_n=%b in_vec=%h out_vec=%h", $time, rst_n, in_vec, out_vec);
  end

endmodule
