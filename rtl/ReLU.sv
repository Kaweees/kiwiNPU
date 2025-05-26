`timescale 1ns / 1ps
`include "../include/width.svh"

module ReLU #(
  parameter int DATA_WIDTH = `DATA_WIDTH
) (
  input logic signed [DATA_WIDTH-1:0] in, // Pre-activated value
  output logic signed [DATA_WIDTH-1:0] out // Activated value
);

  // ReLU activation function: max(0, x)
  always_comb begin
    if (in[DATA_WIDTH-1]) begin
      out = '0;
    end else begin
      out = in;
    end
  end
endmodule
