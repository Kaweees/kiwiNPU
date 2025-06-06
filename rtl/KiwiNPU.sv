`include "../include/width.svh"


module KiwiNPU #(
  // Number of layers (must match how many 8-bit chunks we packed in LAYER_SIZES).
  parameter integer NUM_LAYERS          = `NUM_LAYERS,

  // Each layer’s size is stored in one byte of this vector:
  //   [ (NUM_LAYERS*8-1) : 0 ] = { size[0]<<((NUM_LAYERS-1)*8), size[1]<<((NUM_LAYERS-2)*8), … }
  //
  // In our case, `LAYER_SIZES` = {8'd4, 8'd8, 8'd4}  (layer0=4, layer1=8, layer2=4).
  parameter [NUM_LAYERS*8-1:0] LAYER_SIZES = `LAYER_SIZES,

  // Bit-width for each datum (we’ll multiply this by the layer sizes when slicing/packing).
  parameter integer DATA_WIDTH          = `DATA_WIDTH
) (
  input  wire                      clk,      // System clock
  input  wire                      rst_n,    // Asynchronous reset (active low)

  // Flattened “in_vec”: layer0 has get_layer_size(0) elements, each DATA_WIDTH bits.
  input  wire signed [ get_layer_size(0)*DATA_WIDTH - 1 : 0 ] in_vec,

  // Flat-packed weights for layers 1..(NUM_LAYERS-1):
  //   total bits = ∑_{j=1..NUM_LAYERS-1} [ get_layer_size(j)*get_layer_size(j-1)*DATA_WIDTH ]
  input  wire signed [ calc_weights_bits() - 1 : 0 ] weights_flat,

  // Flat-packed biases for layers 1..(NUM_LAYERS-1):
  //   total bits = ∑_{j=1..NUM_LAYERS-1} [ get_layer_size(j)*DATA_WIDTH ]
  input  wire signed [ calc_biases_bits() - 1 : 0 ] biases_flat,

  // Final “out_vec”: layer(NUM_LAYERS-1) elements × DATA_WIDTH bits
  output wire signed [ get_layer_size(NUM_LAYERS-1)*DATA_WIDTH - 1 : 0 ] out_vec
);



  //--------------------------------------------------------------------------
  // Function: get_layer_size(idx)
  //   Extracts 8 bits out of LAYER_SIZES corresponding to “layer idx.”
  //   We stored layer0 in the top 8 bits, then layer1, … so that:
  //     get_layer_size(0) == LAYER_SIZES[(NUM_LAYERS-1)*8 +: 8]
  //     get_layer_size(1) == LAYER_SIZES[(NUM_LAYERS-2)*8 +: 8]
  //     …
  //   Returns an integer because each chunk is an 8-bit unsigned number.
  //--------------------------------------------------------------------------
  function integer get_layer_size;
    input integer idx;
    integer offset;
    begin
      // Compute “which byte” inside LAYER_SIZES holds layer[idx].
      // If NUM_LAYERS=3, and idx=0 → offset = (3-1-0)*8 = 16 (bits 23:16 hold layer0)
      // If idx=1 → offset = (3-1-1)*8 = 8  (bits 15:8 hold layer1)
      // If idx=2 → offset = (3-1-2)*8 = 0  (bits 7:0 hold layer2)
      offset = (NUM_LAYERS - 1 - idx) * 8;
      get_layer_size = LAYER_SIZES[ offset +: 8 ];
    end
  endfunction


  //--------------------------------------------------------------------------
  // Function: calc_weights_bits()
  //   Sum over j = 1..(NUM_LAYERS-1) of [ get_layer_size(j) * get_layer_size(j-1) * DATA_WIDTH ]
  //   Yields a constant integer total bit-width for weights_flat.
  //--------------------------------------------------------------------------
  function integer calc_weights_bits;
    integer sum;
    integer j;
    begin
      sum = 0;
      for (j = 1; j < NUM_LAYERS; j = j + 1) begin
        sum = sum
            + get_layer_size(j)
            * get_layer_size(j-1)
            * DATA_WIDTH;
      end
      calc_weights_bits = sum;
    end
  endfunction


  //--------------------------------------------------------------------------
  // Function: calc_biases_bits()
  //   Sum over j = 1..(NUM_LAYERS-1) of [ get_layer_size(j) * DATA_WIDTH ]
  //   Yields a constant integer total bit-width for biases_flat.
  //--------------------------------------------------------------------------
  function integer calc_biases_bits;
    integer sum;
    integer j;
    begin
      sum = 0;
      for (j = 1; j < NUM_LAYERS; j = j + 1) begin
        sum = sum + get_layer_size(j) * DATA_WIDTH;
      end
      calc_biases_bits = sum;
    end
  endfunction


  //--------------------------------------------------------------------------
  // Function: weight_size(idx)
  //   Returns (get_layer_size(idx) * get_layer_size(idx-1) * DATA_WIDTH).
  //   Used for slicing out exactly that many bits from weights_flat.
  //   Only valid for idx in [1 .. NUM_LAYERS-1].
  //--------------------------------------------------------------------------
  function integer weight_size;
    input integer idx;
    begin
      weight_size = get_layer_size(idx)
                  * get_layer_size(idx-1)
                  * DATA_WIDTH;
    end
  endfunction


  //--------------------------------------------------------------------------
  // Function: weight_offset(idx)
  //   Returns sum_{j=1..idx-1}[ get_layer_size(j)*get_layer_size(j-1)*DATA_WIDTH ].
  //   This is the starting bit of layer[idx]’s weights within weights_flat.
  //--------------------------------------------------------------------------
  function integer weight_offset;
    input integer idx;
    integer offset;
    integer j;
    begin
      offset = 0;
      for (j = 1; j < idx; j = j + 1) begin
        offset = offset
               + get_layer_size(j)
               * get_layer_size(j-1)
               * DATA_WIDTH;
      end
      weight_offset = offset;
    end
  endfunction


  //--------------------------------------------------------------------------
  // Function: bias_size(idx)
  //   Returns (get_layer_size(idx) * DATA_WIDTH). Used to slice biases_flat.
  //--------------------------------------------------------------------------
  function integer bias_size;
    input integer idx;
    begin
      bias_size = get_layer_size(idx) * DATA_WIDTH;
    end
  endfunction


  //--------------------------------------------------------------------------
  // Function: bias_offset(idx)
  //   Returns sum_{j=1..idx-1}[ get_layer_size(j) * DATA_WIDTH ].
  //   This is the starting bit of layer[idx]’s biases within biases_flat.
  //--------------------------------------------------------------------------
  function integer bias_offset;
    input integer idx;
    integer offset;
    integer j;
    begin
      offset = 0;
      for (j = 1; j < idx; j = j + 1) begin
        offset = offset + get_layer_size(j)*DATA_WIDTH;
      end
      bias_offset = offset;
    end
  endfunction


  //--------------------------------------------------------------------------
  // Generate one “Layer” instance per j = 1..(NUM_LAYERS-1).
  // Each iteration:
  //   • Compute IN_WIDTH  = get_layer_size(j-1) * DATA_WIDTH
  //   • Compute OUT_WIDTH = get_layer_size(j)   * DATA_WIDTH
  //   • Slice out the right chunk of weights_flat and biases_flat
  //   • Hook “layer_in” either to in_vec (for j=1) or previous layer’s out
  //   • Drive out_vec when j == (NUM_LAYERS-1)
  //--------------------------------------------------------------------------
  genvar j;
  generate
    for (j = 1; j < NUM_LAYERS; j = j + 1) begin : gen_layers
      // Per-layer vector bit-widths
      localparam integer IN_WIDTH  = get_layer_size(j-1) * DATA_WIDTH;
      localparam integer OUT_WIDTH = get_layer_size(j)   * DATA_WIDTH;

      // Wires for this layer’s input/output
      wire signed [IN_WIDTH-1:0]   layer_in;
      wire signed [OUT_WIDTH-1:0]  layer_out;

      // Slice out exactly weight_size(j) bits from weights_flat
      wire signed [ weight_size(j)-1 : 0 ] layer_weights;
      assign layer_weights = weights_flat[ weight_offset(j) +: weight_size(j) ];

      // Slice out exactly bias_size(j) bits from biases_flat
      wire signed [ bias_size(j)-1 : 0 ]   layer_biases;
      assign layer_biases   = biases_flat[ bias_offset(j)  +: bias_size(j)  ];

      // Connect this layer’s “in”:
      if (j == 1) begin
        // Top-level input feeds layer1
        assign layer_in = in_vec;
      end else begin
        // Otherwise, feed from previous iteration’s “layer_out”
        assign layer_in = gen_layers[j-1].layer_out;
      end

      // Instantiate the actual Layer module
      Layer #(
        .IN_N       ( get_layer_size(j-1) ),
        .OUT_N      ( get_layer_size(j)   ),
        .DATA_WIDTH ( DATA_WIDTH          ),
        .ACC_WIDTH  ( DATA_WIDTH*2 + $clog2(get_layer_size(j-1)) )
      ) u_layer_inst (
        .clk     ( clk            ),
        .rst_n   ( rst_n          ),
        .in_vec  ( layer_in       ),
        .weights ( layer_weights  ),
        .biases  ( layer_biases   ),
        .out_vec ( layer_out      )
      );

      // If this is the last layer (j == NUM_LAYERS-1), drive out_vec
      if (j == NUM_LAYERS-1) begin
        assign out_vec = layer_out;
      end
    end
  endgenerate

endmodule
