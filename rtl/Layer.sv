`include "../include/width.svh"

module Layer #(
  parameter int IN_N = 16,  // Input vector dimensionality
  parameter int OUT_N = 8,  // Output vector dimensionality
  parameter int DATA_WIDTH = `DATA_WIDTH,  // Data width
  parameter int ACC_WIDTH = `ACC_WIDTH  // Accumulator width
) (
  input  logic                                    clk,      // System clock
  input  logic                                    rst_n,    // Asynchronous reset (active low)
  input  logic signed [      IN_N*DATA_WIDTH-1:0] in_vec,   // Packed input vector (bus)
  input  logic signed [OUT_N*IN_N*DATA_WIDTH-1:0] weights,  // Flattened weights
  input  logic signed [     OUT_N*DATA_WIDTH-1:0] biases,   // Flattened biases
  output logic signed [     OUT_N*DATA_WIDTH-1:0] out_vec   // Packed output vector (bus)
);
  // Unpack input vector
  genvar i;
  generate
    for (i = 0; i < OUT_N; i++) begin : gen_neurons
      Perceptron #(
        .N         (IN_N),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH (ACC_WIDTH)
      ) u_neuron (
        .clk  (clk),
        .rst_n(rst_n),
        .x    (in_vec),
        .w    (weights[i*IN_N*DATA_WIDTH+:IN_N*DATA_WIDTH]),
        .b    (biases[i*DATA_WIDTH+:DATA_WIDTH]),
        .y    (out_vec[i*DATA_WIDTH+:DATA_WIDTH])
      );
    end
  endgenerate
endmodule
