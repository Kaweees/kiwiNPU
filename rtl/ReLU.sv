`timescale 1ns / 1ps
`include "../include/fixed_point.vh"

module ReLU #(
  parameter WIDTH = `FP_WIDTH // Bit width
) (
  input logic signed [WIDTH-1:0] in, // Pre-activated value
  output logic signed [WIDTH-1:0] out // Activated value
);

  // ReLU activation function: max(0, x)
  assign out = (in[WIDTH-1]) ? 0 : in;
endmodule

