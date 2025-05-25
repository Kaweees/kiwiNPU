`timescale 1ns / 1ps
`include "../include/width.svh"

module Perceptron #(
  parameter int N = 4, // Data dimensionality
  parameter int DATA_WIDTH = `DATA_WIDTH, // Data width
  parameter int ACC_WIDTH = `ACC_WIDTH // Accumulator width
)(
  input logic clk, // System clock
  input logic rst_n, // Asynchronous reset (active low)
  input logic signed [DATA_WIDTH-1:0] x[N], // Input vector
  input logic signed [DATA_WIDTH-1:0] w[N], // Weight vector
  input logic signed [DATA_WIDTH-1:0] b, // Bias
  output logic signed [DATA_WIDTH-1:0] y // Activated value
);
  // Pipeline registers for each stage
  logic signed [ACC_WIDTH-1:0] dp_result; // Result from the dot product
  logic signed [ACC_WIDTH-1:0] sum; // Sum of the dot product and bias
  logic signed [DATA_WIDTH-1:0] pre; // Pre-activation value
  logic signed [DATA_WIDTH-1:0] relu_out; // ReLU output

  // Pipeline stage 1: Dot product calculation
  DotProduct #(
    .N(N),
    .DATA_WIDTH(DATA_WIDTH),
    .ACC_WIDTH(ACC_WIDTH)
  ) dot (
    .x(x),
    .w(w),
    .dp(dp_result)
  );

  // Pipeline stage 2: Add bias to dot product result
  assign sum = dp_result + $signed({{(ACC_WIDTH-DATA_WIDTH){b[DATA_WIDTH-1]}}, b});

  // Quantize the sum to the data width
  Quantizer #(
    .DATA_WIDTH(DATA_WIDTH),
    .ACC_WIDTH(ACC_WIDTH)
  ) quant (
    .in(sum),
    .out(pre)
  );

  // Pipeline stage 3: Apply activation function
  ReLU #(
    .DATA_WIDTH(DATA_WIDTH)
  ) act (
    .in(pre),
    .out(relu_out)
  );

  // Pipeline registers for each stage
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      y <= '0;
    end else begin
      y <= relu_out;
      $display("[Perceptron DEBUG] dp_result=%0d, sum=%0d, pre=%0d, relu_out=%0d, y=%0d", dp_result, sum, pre, relu_out, y);
    end
  end

endmodule
