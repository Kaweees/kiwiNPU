`include "../include/width.svh"

module Layer #(
  parameter int IN_N = 16, // Input vector dimensionality
  parameter int OUT_N = 8, // Output vector dimensionality
  parameter int DATA_WIDTH = `DATA_WIDTH, // Data width
  parameter int ACC_WIDTH = `ACC_WIDTH // Accumulator width
)(
  input logic clk, // System clock
  input logic rst_n, // Asynchronous reset (active low)
  input logic signed [DATA_WIDTH-1:0] in_vec [IN_N], // Input vector
  input logic signed [DATA_WIDTH-1:0] weights [OUT_N][IN_N], // Weights
  input logic signed [DATA_WIDTH-1:0] biases [OUT_N], // Biases
  output logic signed [DATA_WIDTH-1:0] out_vec [OUT_N] // Output vector
);
  genvar i;
  generate
    for (i = 0; i < OUT_N; i++) begin : gen_neurons
      Perceptron #(
        .N(IN_N),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
      )
        u_neuron (
          .clk (clk),
          .rst_n (rst_n),
          .x    (in_vec),
          .w    (weights[i]),
          .b    (biases[i]),
          .y    (out_vec[i])
        );
    end
  endgenerate
endmodule
