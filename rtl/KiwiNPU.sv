`include "../include/width.svh"

module KiwiNPU #(
  parameter int NUM_LAYERS = `NUM_LAYERS,  // Number of layers in the network
  parameter int LAYER_SIZES[0:NUM_LAYERS-1] = `LAYER_SIZES,  // Size of each layer
  parameter int DATA_WIDTH = `DATA_WIDTH  // Bit width of each element
) (
  input logic clk,   // System clock
  input logic rst_n, // Asynchronous reset (active low)

  // Packed input vector:  LAYER_SIZES[0] elements, each DATA_WIDTH bits
  input logic signed [LAYER_SIZES[0]*DATA_WIDTH-1 : 0] in_vec,

  // Flat pack of all weights for layers 1..NUM_LAYERS-1:
  //   Total bits = sum_{i=1..NUM_LAYERS-1} ( LAYER_SIZES[i] * LAYER_SIZES[i-1] * DATA_WIDTH )
  //
  // We slice this flat vector inside generate so that each layer i sees exactly
  //   LAYER_SIZES[i] * LAYER_SIZES[i-1] * DATA_WIDTH bits.
  input logic signed [calc_weights_bits() - 1 : 0] weights_flat,

  // Flat pack of all biases for layers 1..NUM_LAYERS-1:
  //   Total bits = sum_{i=1..NUM_LAYERS-1} ( LAYER_SIZES[i] * DATA_WIDTH )
  input logic signed [calc_biases_bits() - 1 : 0] biases_flat,

  // Final output vector is LAYER_SIZES[NUM_LAYERS-1] elements × DATA_WIDTH bits
  output logic signed [LAYER_SIZES[NUM_LAYERS-1]*DATA_WIDTH - 1 : 0] out_vec
);

  //--------------------------------------------------------------------------
  // Function to compute the total number of weight bits:
  //   sum_{i=1..NUM_LAYERS-1} (LAYER_SIZES[i]*LAYER_SIZES[i-1]*DATA_WIDTH)
  //--------------------------------------------------------------------------
  function automatic int calc_weights_bits();
    int sum = 0;
    for (int j = 1; j < NUM_LAYERS; j++) begin
      sum += LAYER_SIZES[j] * LAYER_SIZES[j-1] * DATA_WIDTH;  // Calculate total weight bits for each layer
    end
    return sum;
  endfunction

  //--------------------------------------------------------------------------
  // Function to compute the total number of bias bits:
  //   sum_{i=1..NUM_LAYERS-1} (LAYER_SIZES[i]*DATA_WIDTH)
  //--------------------------------------------------------------------------
  function automatic int calc_biases_bits();
    int sum;
    sum = 0;
    for (int j = 1; j < NUM_LAYERS; j++) begin
      sum += LAYER_SIZES[j] * DATA_WIDTH;
    end
    return sum;
  endfunction

  //--------------------------------------------------------------------------
  // Function to get the bit‐width of the weight chunk for layer 'idx':
  //   weight_size(idx) = LAYER_SIZES[idx] * LAYER_SIZES[idx-1] * DATA_WIDTH
  // (Here idx ∈ [1 .. NUM_LAYERS-1].)
  //--------------------------------------------------------------------------
  function automatic int weight_size(int idx);
    return LAYER_SIZES[idx] * LAYER_SIZES[idx-1] * DATA_WIDTH;
  endfunction

  //--------------------------------------------------------------------------
  // Function to get the bit‐offset of layer 'idx' weights within weights_flat:
  //   We sum up all weight_size(j) for j=1..(idx-1).
  //--------------------------------------------------------------------------
  function automatic int weight_offset(int idx);
    int offset;
    offset = 0;
    for (int j = 1; j < idx; j++) begin
      offset += LAYER_SIZES[j] * LAYER_SIZES[j-1] * DATA_WIDTH;
    end
    return offset;
  endfunction

  //--------------------------------------------------------------------------
  // Function to get the bit‐width of the bias chunk for layer 'idx':
  //   bias_size(idx) = LAYER_SIZES[idx] * DATA_WIDTH
  //--------------------------------------------------------------------------
  function automatic int bias_size(int idx);
    return LAYER_SIZES[idx] * DATA_WIDTH;
  endfunction

  //--------------------------------------------------------------------------
  // Function to get the bit‐offset of layer 'idx' biases within biases_flat:
  //   We sum up all bias_size(j) for j=1..(idx-1).
  //--------------------------------------------------------------------------
  function automatic int bias_offset(int idx);
    int offset;
    offset = 0;
    for (int j = 1; j < idx; j++) begin
      offset += LAYER_SIZES[j] * DATA_WIDTH;
    end
    return offset;
  endfunction

  //--------------------------------------------------------------------------
  // Generate one Layer instance for each layer index i = 1 .. NUM_LAYERS-1
  //    - We declare a local signal layer_out that is exactly
  //        [ LAYER_SIZES[i]*DATA_WIDTH-1 : 0 ]
  //    - We slice out the correct chunk of weights_flat and biases_flat
  //      (via weight_offset/weight_size and bias_offset/bias_size).
  //    - On i==1, we drive in_vec directly. Otherwise, we wire in_vec_i = previous layer’s out.
  //    - When i == NUM_LAYERS-1, we assign layer_out → top‐level out_vec.
  //--------------------------------------------------------------------------
  generate
    for (genvar i = 1; i < NUM_LAYERS; i++) begin : gen_layers
      // Each layer’s activation‐vector width:
      localparam int THIS_OUT_WIDTH = LAYER_SIZES[i] * DATA_WIDTH;

      // Declare a local signal for this layer’s output
      logic signed [THIS_OUT_WIDTH-1 : 0] layer_out;

      // Extract exactly the right slice of weights_flat for layer i:
      //   width = LAYER_SIZES[i] * LAYER_SIZES[i-1] * DATA_WIDTH,
      //   offset = weight_offset(i).
      wire signed [weight_size(i)-1 : 0] layer_weights = weights_flat[weight_offset(i)+:weight_size(i)];

      // Extract exactly the right slice of biases_flat for layer i:
      //   width = LAYER_SIZES[i] * DATA_WIDTH,
      //   offset = bias_offset(i).
      wire signed [bias_size(i)-1 : 0] layer_biases = biases_flat[bias_offset(i)+:bias_size(i)];

      // Instantiate Layer, using an if/else to avoid a wide‐condition “?:”
      if (i == 1) begin
        Layer #(
          .IN_N      (LAYER_SIZES[i-1]),
          .OUT_N     (LAYER_SIZES[i]),
          .DATA_WIDTH(DATA_WIDTH),
          .ACC_WIDTH (DATA_WIDTH * 2 + $clog2(LAYER_SIZES[i-1]))
        ) u_layer_inst (
          .clk    (clk),
          .rst_n  (rst_n),
          .in_vec (in_vec),         // top‐level input for first layer
          .weights(layer_weights),
          .biases (layer_biases),
          .out_vec(layer_out)
        );
      end else begin
        Layer #(
          .IN_N      (LAYER_SIZES[i-1]),
          .OUT_N     (LAYER_SIZES[i]),
          .DATA_WIDTH(DATA_WIDTH),
          .ACC_WIDTH (DATA_WIDTH * 2 + $clog2(LAYER_SIZES[i-1]))
        ) u_layer_inst (
          .clk    (clk),
          .rst_n  (rst_n),
          // “previous layer’s output” is gen_layers[i-1].layer_out
          .in_vec (gen_layers[i-1].layer_out),
          .weights(layer_weights),
          .biases (layer_biases),
          .out_vec(layer_out)
        );
      end

      // If this is the very last layer (i == NUM_LAYERS-1), drive out_vec:
      if (i == NUM_LAYERS - 1) begin
        assign out_vec = layer_out;
      end

    end  // gen_layers
  endgenerate

endmodule
