`timescale 1ns / 1ps
`include "../include/width.svh"

module kiwiNPU #(
  parameter int IN_N = `N,         // Input vector size
  parameter int HIDDEN_N = `M,    // Hidden layer size
  parameter int OUT_N = `N,       // Output vector size
  parameter int DATA_WIDTH = `DATA_WIDTH,
  parameter int ACC_WIDTH = `ACC_WIDTH
)(
  input logic clk, // System clock
  input logic rst_n, // Asynchronous reset (active low)
  // Input vector
  input logic signed [DATA_WIDTH-1:0] in_vec [IN_N],
  // Weights and biases for first (input->hidden) layer
  input logic signed [DATA_WIDTH-1:0] weights1 [HIDDEN_N][IN_N],
  input logic signed [DATA_WIDTH-1:0] biases1 [HIDDEN_N],
  // Weights and biases for second (hidden->output) layer
  input logic signed [DATA_WIDTH-1:0] weights2 [OUT_N][HIDDEN_N],
  input logic signed [DATA_WIDTH-1:0] biases2 [OUT_N],
  // Output vector
  output logic signed [DATA_WIDTH-1:0] out_vec [OUT_N]
);
  // Intermediate signal for hidden layer output
  logic signed [DATA_WIDTH-1:0] hidden_vec [HIDDEN_N];

  // First layer: input -> hidden
  Layer #(
    .IN_N(IN_N),
    .OUT_N(HIDDEN_N),
    .DATA_WIDTH(DATA_WIDTH),
    .ACC_WIDTH(ACC_WIDTH)
  ) u_layer1 (
    .clk(clk),
    .rst_n(rst_n),
    .in_vec(in_vec),
    .weights(weights1),
    .biases(biases1),
    .out_vec(hidden_vec)
  );

  // Second layer: hidden -> output
  Layer #(
    .IN_N(HIDDEN_N),
    .OUT_N(OUT_N),
    .DATA_WIDTH(DATA_WIDTH),
    .ACC_WIDTH(ACC_WIDTH)
  ) u_layer2 (
    .clk(clk),
    .rst_n(rst_n),
    .in_vec(hidden_vec),
    .weights(weights2),
    .biases(biases2),
    .out_vec(out_vec)
  );

endmodule
