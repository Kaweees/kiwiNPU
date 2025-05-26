`timescale 1ns / 1ps
`include "../include/width.svh"

module DotProduct #(
  parameter int N = 4, // Data dimensionality
  parameter DATA_WIDTH = `DATA_WIDTH, // Data width
  parameter ACC_WIDTH = `ACC_WIDTH // Accumulator width
)(
  input  logic signed [DATA_WIDTH-1:0] x[N], // First vector
  input  logic signed [DATA_WIDTH-1:0] w[N], // Second vector
  output logic signed [ACC_WIDTH-1:0] dp // Dot product result
);
  always_comb begin
    dp = '0;
    for (int i = 0; i < N; i++) begin
      dp += x[i] * w[i];
      $display("[Perceptron DEBUG] x[%0d]=%0d, w[%0d]=%0d, dp=%0d", i, x[i], i, w[i], dp);
    end
  end
endmodule
