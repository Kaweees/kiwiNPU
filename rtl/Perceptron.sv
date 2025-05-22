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
  logic signed [`ACC_WIDTH-1:0] dp_result; // Result from the dot product
  logic signed [`ACC_WIDTH-1:0] acc_with_bias; // Accumulator with bias added
  logic signed [`DATA_WIDTH-1:0] pre; // Pre-activation value

  DotProduct #(
    .N(N),
    .DATA_WIDTH(DATA_WIDTH),
    .ACC_WIDTH(ACC_WIDTH)
  ) dot (
    .x(x),
    .w(w),
    .dp(dp_result_comb)
  );

  // Add bias to dot product result
  always_comb begin
    acc_with_bias = dp_result + $signed({{(`ACC_WIDTH-`DATA_WIDTH){b[`DATA_WIDTH-1]}}, b});
  end

  Quantizer quant (
    .in(acc_with_bias),
    .out(pre)
  );

  ReLU act (
    .in(pre),
    .out(y)
  );
endmodule
