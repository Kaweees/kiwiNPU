`include "../include/width.svh"

module Perceptron #(
  parameter int N = `N,  // Data dimensionality
  parameter int DATA_WIDTH = `DATA_WIDTH,  // Data width
  parameter int ACC_WIDTH = (DATA_WIDTH * 2 + $clog2(N))  // Accumulator width
) (
  input  logic                           clk,    // System clock
  input  logic                           rst_n,  // Asynchronous reset (active low)
  input  logic signed [N*DATA_WIDTH-1:0] x,      // packed input vector
  input  logic signed [N*DATA_WIDTH-1:0] w,      // packed weights
  input  logic signed [  DATA_WIDTH-1:0] b,      // bias
  output logic signed [  DATA_WIDTH-1:0] y       // Activated value
);
  // Unpack x and w into arrays for internal use
  logic signed [DATA_WIDTH-1:0] x_arr[N];
  logic signed [DATA_WIDTH-1:0] w_arr[N];
  genvar i;
  generate
    for (i = 0; i < N; i++) begin
      assign x_arr[i] = x[i*DATA_WIDTH+:DATA_WIDTH];
      assign w_arr[i] = w[i*DATA_WIDTH+:DATA_WIDTH];
    end
  endgenerate

  // Pipeline registers for each stage
  logic signed [ACC_WIDTH-1:0] pre;  // Pre-activation value
  logic signed [DATA_WIDTH-1:0] pre_quantized;  // Quantized pre-activation value
  logic signed [DATA_WIDTH-1:0] relu_out;  // ReLU output

  // Pipeline stage 1: Pre-activation calculation
  PreActivation #(
    .N         (N),
    .DATA_WIDTH(DATA_WIDTH),
    .ACC_WIDTH (ACC_WIDTH)
  ) pre_activation (
    .clk (clk),
    .rst_n(rst_n),
    .x (x),
    .w (w),
    .b (b),
    .pre(pre)
  );

  // Pipeline stage 2: Quantize and apply activation function
  Quantizer #(
    .DATA_WIDTH(DATA_WIDTH),
    .ACC_WIDTH (ACC_WIDTH)
  ) quant (
    .in (pre),
    .out(pre_quantized)
  );

  ReLU #(
    .DATA_WIDTH(DATA_WIDTH)
  ) act (
    .in (pre_quantized),
    .out(relu_out)
  );

  // Pipeline registers for each stage
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      y <= '0;
    end else begin
      y <= relu_out;
      $display("[Perceptron DEBUG] pre=%0d, relu_out=%0d, y=%0d", pre, relu_out, y);
    end
  end
endmodule
