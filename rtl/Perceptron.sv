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
  logic signed [ ACC_WIDTH-1:0] dp_result;  // Result from the dot product
  logic signed [ ACC_WIDTH-1:0] sum;  // Sum of the dot product and bias
  logic signed [DATA_WIDTH-1:0] pre;  // Pre-activation value
  logic signed [DATA_WIDTH-1:0] relu_out;  // ReLU output

  // Pipeline stage 1: Dot product calculation
  DotProduct #(
    .N         (N),
    .DATA_WIDTH(DATA_WIDTH),
    .ACC_WIDTH (ACC_WIDTH)
  ) dot (
    .x (x),
    .w (w),
    .dp(dp_result)
  );

  // Pipeline stage 2: Add bias to dot product result
  assign sum = dp_result + $signed({{(ACC_WIDTH - DATA_WIDTH) {b[DATA_WIDTH-1]}}, b});

  // Quantize the sum to the data width
  Quantizer #(
    .DATA_WIDTH(DATA_WIDTH),
    .ACC_WIDTH (ACC_WIDTH)
  ) quant (
    .in (sum),
    .out(pre)
  );

  // Pipeline stage 3: Apply activation function
  ReLU #(
    .DATA_WIDTH(DATA_WIDTH)
  ) act (
    .in (pre),
    .out(relu_out)
  );

  // Pipeline registers for each stage
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      y <= '0;
    end else begin
      y <= relu_out;
      $display("[Perceptron DEBUG] dp_result=%0d, sum=%0d, pre=%0d, relu_out=%0d, y=%0d",
               dp_result, sum, pre, relu_out, y);
    end
  end
endmodule
