`include "../include/width.svh"

module KiwiNPU #(
  // Number of layers (must match how many 8-bit chunks we packed in LAYER_SIZES).
  parameter integer NUM_LAYERS = `NUM_LAYERS,

  // Each layer’s size is stored in one byte of this vector:
  //   [ (NUM_LAYERS*8-1) : 0 ] = { size[0] << ((NUM_LAYERS-1)*8),
  //                               size[1] << ((NUM_LAYERS-2)*8),
  //                               … }
  //
  // In our case, `LAYER_SIZES` = {8'd4, 8'd8, 8'd4}  (layer0=4, layer1=8, layer2=4).
  parameter [NUM_LAYERS*8-1:0] LAYER_SIZES = `LAYER_SIZES,

  // Bit-width for each datum (we’ll multiply this by the layer sizes when slicing/packing).
  parameter integer DATA_WIDTH = `DATA_WIDTH
) (
  input wire clk,   // System clock
  input wire rst_n, // Asynchronous reset (active low)

  // Flattened “in_vec”: layer0 has get_layer_size(0) elements, each DATA_WIDTH bits.
  // Since get_layer_size(0) now returns a 32-bit integer, Verilator sees a 32-bit expression here.
  input wire signed [get_layer_size(0)*DATA_WIDTH - 1 : 0] in_vec,

  // Flat-packed weights for layers 1..(NUM_LAYERS-1):
  //   total bits = ∑_{j=1..NUM_LAYERS-1} [ get_layer_size(j)*get_layer_size(j-1)*DATA_WIDTH ]
  input wire signed [calc_weights_bits() - 1 : 0] weights_flat,

  // Flat-packed biases for layers 1..(NUM_LAYERS-1):
  //   total bits = ∑_{j=1..NUM_LAYERS-1} [ get_layer_size(j)*DATA_WIDTH ]
  input wire signed [calc_biases_bits() - 1 : 0] biases_flat,

  // Final “out_vec”: layer(NUM_LAYERS-1) has get_layer_size(NUM_LAYERS-1) elements × DATA_WIDTH bits
  output wire signed [get_layer_size(NUM_LAYERS-1)*DATA_WIDTH - 1 : 0] out_vec
);

  function integer get_layer_size;
    input integer idx;
    integer offset;
    begin
      offset         = (NUM_LAYERS - 1 - idx) * 8;
      // zero-extend 8-bit slice to 32 bits
      get_layer_size = {24'd0, LAYER_SIZES[offset+:8]};
    end
  endfunction

  //--------------------------------------------------------------------------
  // Function: calc_weights_bits()
  //   Sum over j = 1..(NUM_LAYERS-1) of [ get_layer_size(j) * get_layer_size(j-1) * DATA_WIDTH ].
  //   Returns a 32-bit integer total bit-width for weights_flat.
  //--------------------------------------------------------------------------
  function integer calc_weights_bits;
    integer sum;
    integer j;
    integer sz_j;
    integer sz_jm1;
    begin
      sum = 0;
      for (j = 1; j < NUM_LAYERS; j = j + 1) begin
        sz_j   = get_layer_size(j);
        sz_jm1 = get_layer_size(j - 1);
        sum    = sum + (sz_j * sz_jm1 * DATA_WIDTH);
      end
      calc_weights_bits = sum;
    end
  endfunction

  //--------------------------------------------------------------------------
  // Function: calc_biases_bits()
  //   Sum over j = 1..(NUM_LAYERS-1) of [ get_layer_size(j) * DATA_WIDTH ].
  //   Returns a 32-bit integer total bit-width for biases_flat.
  //--------------------------------------------------------------------------
  function integer calc_biases_bits;
    integer sum;
    integer j;
    integer sz_j;
    begin
      sum = 0;
      for (j = 1; j < NUM_LAYERS; j = j + 1) begin
        sz_j = get_layer_size(j);
        sum  = sum + (sz_j * DATA_WIDTH);
      end
      calc_biases_bits = sum;
    end
  endfunction

  //--------------------------------------------------------------------------
  // Function: weight_offset(idx)
  //   Returns sum_{k = 1..(idx-1)} [ get_layer_size(k) * get_layer_size(k-1) * DATA_WIDTH ].
  //   This is the starting bit for layer[idx]’s weights in weights_flat.
  //--------------------------------------------------------------------------
  function integer weight_offset;
    input integer idx;
    integer acc;
    integer k;
    integer s_k;
    integer s_km1;
    begin
      acc = 0;
      for (k = 1; k < idx; k = k + 1) begin
        s_k   = get_layer_size(k);
        s_km1 = get_layer_size(k - 1);
        acc   = acc + (s_k * s_km1 * DATA_WIDTH);
      end
      weight_offset = acc;
    end
  endfunction

  //--------------------------------------------------------------------------
  // Function: bias_offset(idx)
  //   Returns sum_{k = 1..(idx-1)} [ get_layer_size(k) * DATA_WIDTH ].
  //   This is the starting bit for layer[idx]’s biases in biases_flat.
  //--------------------------------------------------------------------------
  function integer bias_offset;
    input integer idx;
    integer acc;
    integer k;
    integer s_k;
    begin
      acc = 0;
      for (k = 1; k < idx; k = k + 1) begin
        s_k = get_layer_size(k);
        acc = acc + (s_k * DATA_WIDTH);
      end
      bias_offset = acc;
    end
  endfunction


  //--------------------------------------------------------------------------
  // Generate one “Layer” instance per j = 1..(NUM_LAYERS-1).
  // Each iteration:
  //   1) Call get_layer_size(), which now returns a 32-bit integer.
  //   2) Compute IN_WIDTH, OUT_WIDTH, WEIGHT_SZ, BIAS_SZ.
  //   3) Call weight_offset(j)/bias_offset(j) directly (pure functions).
  //   4) Slice out exactly those bits from weights_flat and biases_flat.
  //   5) Hook this layer’s “input” to in_vec (if j==1) or previous out.
  //   6) Instantiate Layer (all overrides are 32-bit now).
  //   7) If j==(NUM_LAYERS-1), drive top‐level out_vec.
  //--------------------------------------------------------------------------
  genvar j;
  generate
    for (j = 1; j < NUM_LAYERS; j = j + 1) begin : gen_layers

      // 1) Extract layer sizes (32-bit) directly from get_layer_size().
      localparam integer LSIZE_IN = get_layer_size(j - 1);
      localparam integer LSIZE_OUT = get_layer_size(j);

      // 2) Compute per-layer bit‐widths.
      localparam integer IN_WIDTH = LSIZE_IN * DATA_WIDTH;
      localparam integer OUT_WIDTH = LSIZE_OUT * DATA_WIDTH;
      localparam integer WEIGHT_SZ = LSIZE_IN * LSIZE_OUT * DATA_WIDTH;
      localparam integer BIAS_SZ = LSIZE_OUT * DATA_WIDTH;

      // 3) Compute offsets via pure functions (constant‐folded at compile time).
      localparam integer OFFSET_WEIGHTS = weight_offset(j);
      localparam integer OFFSET_BIAS = bias_offset(j);

      // 4) Slice out exactly WEIGHT_SZ bits and BIAS_SZ bits.
      wire signed [IN_WIDTH   - 1 : 0] layer_in;
      wire signed [OUT_WIDTH  - 1 : 0] layer_out;

      wire signed [ WEIGHT_SZ - 1 : 0] layer_weights;
      assign layer_weights = weights_flat[OFFSET_WEIGHTS+:WEIGHT_SZ];

      wire signed [BIAS_SZ   - 1 : 0] layer_biases;
      assign layer_biases = biases_flat[OFFSET_BIAS+:BIAS_SZ];

      // 5) Wire this layer’s “input”:
      if (j == 1) begin
        assign layer_in = in_vec;
      end else begin
        assign layer_in = gen_layers[j-1].layer_out;
      end

      // 6) Instantiate Layer; all parameters (IN_N, OUT_N) are now 32-bit integers,
      //    so no WIDTHEXPAND warnings occur in Layer.sv.
      Layer #(
        .IN_N      (LSIZE_IN),
        .OUT_N     (LSIZE_OUT),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH (DATA_WIDTH * 2 + $clog2(LSIZE_IN))
      ) u_layer_inst (
        .clk    (clk),
        .rst_n  (rst_n),
        .in_vec (layer_in),
        .weights(layer_weights),
        .biases (layer_biases),
        .out_vec(layer_out)
      );

      // 7) For the final layer, drive top‐level out_vec.
      if (j == NUM_LAYERS - 1) begin
        assign out_vec = layer_out;
      end

    end
  endgenerate

endmodule
