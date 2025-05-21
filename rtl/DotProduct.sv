`timescale 1ns / 1ps
`include "../include/width.svh"

module DotProduct #(
  parameter int N = 4, // Data dimensionality
)(
  input  logic signed [`DATA_WIDTH-1:0] x[N], // First vector
  input  logic signed [`DATA_WIDTH-1:0] w[N], // Second vector
  output logic signed [`ACC_WIDTH-1:0] out // Dot product result
);
  always_comb begin
    out = 0;
    for (int i = 0; i < N; i++) begin
      out += x[i] * w[i];
    end
  end
endmodule
