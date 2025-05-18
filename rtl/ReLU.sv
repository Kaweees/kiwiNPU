`timescale 1ns / 1ps
`include "../include/fixed_point.vh"

module ReLU #(parameter WIDTH = `FP_WIDTH) (
  input logic signed [WIDTH-1:0] x,
  output logic signed [WIDTH-1:0] y
);
  assign y = (x[WIDTH-1]) ? 0 : x;
endmodule
