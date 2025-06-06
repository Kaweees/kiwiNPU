`include "../include/width.svh"

module KiwiNPU #(
  parameter int NUM_LAYERS = `NUM_LAYERS,  // Number of layers in the network
  parameter int LAYER_SIZES [0:NUM_LAYERS-1] = `LAYER_SIZES,  // Size of each layer
  parameter int DATA_WIDTH = `DATA_WIDTH
) (
  input logic clk,  // System clock
  input logic rst_n,  // Asynchronous reset (active low)
  // Input vector (packed bus)
  input logic signed [LAYER_SIZES[0]*DATA_WIDTH-1:0] in_vec,  // Input vector
  // Weights and biases for each layer
  input logic signed [LAYER_SIZES[NUM_LAYERS-1]*DATA_WIDTH-1:0] weights,  // Weights
  input logic signed [LAYER_SIZES[NUM_LAYERS-1]*DATA_WIDTH-1:0] biases,  // Biases
  // Output vector (packed bus)
  output logic signed [LAYER_SIZES[NUM_LAYERS-1]*DATA_WIDTH-1:0] out_vec
);
  // Internal signals for layer outputs
  logic signed [LAYER_SIZES[NUM_LAYERS-1]*DATA_WIDTH-1:0] layer_outputs;

  // Generate layers
  genvar i;
  generate
    for (i = 1; i < NUM_LAYERS; i++) begin : gen_layers
      Layer #(
        .IN_N      (LAYER_SIZES[i-1]),
        .OUT_N     (LAYER_SIZES[i]),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH (DATA_WIDTH*2 + $clog2(LAYER_SIZES[i-1]))
      ) u_layer (
        .clk    (clk),
        .rst_n  (rst_n),
        .in_vec (i == 1 ? in_vec : layer_outputs[i-1]),
        .weights(weights[i-1]),
        .biases (biases[i-1]),
        .out_vec(layer_outputs[i])
      );
    end
  endgenerate

  // Connect final layer output to module output
  assign out_vec = layer_outputs[NUM_LAYERS-1];

endmodule