`ifndef WIDTH_SVH
`define WIDTH_SVH

// Supported quantization widths
`define QUANT_INT4 4 // 4-bit integer quantization
`define QUANT_INT8 8 // 8-bit integer quantization
`define QUANT_INT16 16 // 16-bit integer quantization

// Bit-width for quantized data (e.g. INT8)
`define DATA_WIDTH `QUANT_INT8

// Define N (example value, adjust as necessary)
`define N 4

// Bit-width for the accumulator
`define ACC_WIDTH (`DATA_WIDTH + `DATA_WIDTH + $clog2(`N))

`endif // WIDTH_SVH
