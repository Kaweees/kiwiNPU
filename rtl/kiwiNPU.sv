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
  // Input vector (packed bus)
  input logic signed [IN_N*DATA_WIDTH-1:0] in_vec,
  // Weights and biases for first (input->hidden) layer (packed)
  input logic signed [HIDDEN_N*IN_N*DATA_WIDTH-1:0] weights1,
  input logic signed [HIDDEN_N*DATA_WIDTH-1:0] biases1,
  // Weights and biases for second (hidden->output) layer (packed)
  input logic signed [OUT_N*HIDDEN_N*DATA_WIDTH-1:0] weights2,
  input logic signed [OUT_N*DATA_WIDTH-1:0] biases2,
  // Output vector (packed bus)
  output logic signed [OUT_N*DATA_WIDTH-1:0] out_vec
);
  // Internal unpacked arrays for computation
  logic signed [DATA_WIDTH-1:0] in_vec_arr [IN_N];
  // logic signed [DATA_WIDTH-1:0] hidden_vec_arr [HIDDEN_N];
  logic signed [HIDDEN_N*DATA_WIDTH-1:0] hidden_vec;
  // Unpack input vector
  genvar i;
  generate
    for (i = 0; i < IN_N; i++) begin
      assign in_vec_arr[i] = in_vec[i*DATA_WIDTH +: DATA_WIDTH];
    end
  endgenerate
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
