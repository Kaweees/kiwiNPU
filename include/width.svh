`ifndef WIDTH_SVH
`define WIDTH_SVH

// Supported quantization widths
`define QUANT_INT4 4 // 4-bit integer quantization
`define QUANT_INT8 8 // 8-bit integer quantization
`define QUANT_INT16 16 // 16-bit integer quantization

// Bit-width for quantized data (e.g. INT8)
`define DATA_WIDTH 8

// Define number of layers
`define NUM_LAYERS 3

// Define layer sizes
`define LAYER_SIZES {8'd4, 8'd8, 8'd4}

// Define number of inputs
`define N 4

// Bit-width for the accumulator
`define ACC_WIDTH (`DATA_WIDTH*2 + $clog2(`N))

`endif  // WIDTH_SVH
