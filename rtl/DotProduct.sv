`timescale 1ns / 1ps
`include "../include/fixed_point.vh"

module DotProduct #(
  parameter WIDTH = `FP_WIDTH, // Bit width
  parameter N = 4 // Vector dimensionality
)(
  input  logic signed [WIDTH-1:0] a[N], // First vector
  input  logic signed [WIDTH-1:0] b[N], // Second vector
  output logic signed [WIDTH-1:0] out // Dot product result
);
  always_comb begin
    out = 0;
    for (int i = 0; i < N; i++) begin
      out += a[i] * b[i];
    end
  end
endmodule
