// Ensure width definitions are included
`include "../include/width.svh"

module KiwiNPU_System #(
  parameter int IN_N = `N,
  parameter int HIDDEN_N = `M,
  parameter int OUT_N = `N,
  parameter int DATA_WIDTH = `DATA_WIDTH,
  parameter int ACC_WIDTH = (8 * 2 + $clog2(`N))
) (
  input logic clk,
  input logic rst_n,

  // SPI Interface
  output logic flash_csb,
  output logic flash_clk,
  output logic flash_io0_oe,
  output logic flash_io1_oe,
  output logic flash_io2_oe,
  output logic flash_io3_oe,
  output logic flash_io0_do,
  output logic flash_io1_do,
  output logic flash_io2_do,
  output logic flash_io3_do,
  input  logic flash_io0_di,
  input  logic flash_io1_di,
  input  logic flash_io2_di,
  input  logic flash_io3_di,

  // Input/Output vectors
  input  logic signed [ IN_N*DATA_WIDTH-1:0] in_vec,
  output logic signed [OUT_N*DATA_WIDTH-1:0] out_vec
);

  // Weight and bias signals
  logic signed [ HIDDEN_N*IN_N*DATA_WIDTH-1:0] weights1;
  logic signed [      HIDDEN_N*DATA_WIDTH-1:0] biases1;
  logic signed [OUT_N*HIDDEN_N*DATA_WIDTH-1:0] weights2;
  logic signed [         OUT_N*DATA_WIDTH-1:0] biases2;
  logic                                        weights_ready;

  // Instantiate WeightLoader
  WeightLoader #(
    .IN_N      (IN_N),
    .HIDDEN_N  (HIDDEN_N),
    .OUT_N     (OUT_N),
    .DATA_WIDTH(DATA_WIDTH)
  ) weight_loader (
    .clk          (clk),
    .rst_n        (rst_n),
    .flash_csb    (flash_csb),
    .flash_clk    (flash_clk),
    .flash_io0_oe (flash_io0_oe),
    .flash_io1_oe (flash_io1_oe),
    .flash_io2_oe (flash_io2_oe),
    .flash_io3_oe (flash_io3_oe),
    .flash_io0_do (flash_io0_do),
    .flash_io1_do (flash_io1_do),
    .flash_io2_do (flash_io2_do),
    .flash_io3_do (flash_io3_do),
    .flash_io0_di (flash_io0_di),
    .flash_io1_di (flash_io1_di),
    .flash_io2_di (flash_io2_di),
    .flash_io3_di (flash_io3_di),
    .weights1     (weights1),
    .biases1      (biases1),
    .weights2     (weights2),
    .biases2      (biases2),
    .weights_ready(weights_ready)
  );

  // Instantiate KiwiNPU
  KiwiNPU #(
    .IN_N      (IN_N),
    .HIDDEN_N  (HIDDEN_N),
    .OUT_N     (OUT_N),
    .DATA_WIDTH(DATA_WIDTH),
    .ACC_WIDTH (ACC_WIDTH)
  ) kiwi_npu (
    .clk     (clk),
    .rst_n   (rst_n & weights_ready),  // Only enable NPU when weights are ready
    .in_vec  (in_vec),
    .weights1(weights1),
    .biases1 (biases1),
    .weights2(weights2),
    .biases2 (biases2),
    .out_vec (out_vec)
  );

endmodule
