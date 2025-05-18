`timescale 1ns / 1ps
`include "../include/fixed_point.vh"

module Perceptron #(
  parameter WIDTH = `FP_WIDTH, // Bit width
  parameter N = 4 // Vector dimensionality
)(
  input  logic signed [WIDTH-1:0] x[N], // Input vector
  input  logic signed [WIDTH-1:0] w[N], // Weight vector
  input  logic signed [WIDTH-1:0] b,  // Bias
  output logic signed [WIDTH-1:0] y // Activated value
);
  logic signed [WIDTH-1:0] dp_out;
  logic signed [WIDTH-1:0] pre_activation;

  DotProduct #(
    .WIDTH(WIDTH),
    .N(N)
  ) dot (
    .a(x), .b(w), .out(dp_out)
  );

  assign pre_activation = dp_out + b;

  // Instantiate the activation module of your choice
  ReLU #(.WIDTH(WIDTH)) act (
    .in(pre_activation),
    .out(y)
  );
endmodule
