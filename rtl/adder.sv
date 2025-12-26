`timescale 1ns / 1ps

module adder (
  input  logic       clk,
  input  logic [7:0] a,
  input  logic [7:0] b,
  output logic [7:0] y
);
  always_ff @(posedge clk) y <= a + b;
endmodule
