`timescale 1ns / 1ps
`include "../include/width.svh"

module Quantizer (
  input  logic signed [`ACC_WIDTH-1:0] in,
  output logic signed [`DATA_WIDTH-1:0] out
);
  // Maximum and minimum values for signed DATA_WIDTH
  localparam MAX_VAL = (1 << (`DATA_WIDTH - 1)) - 1;  // 2^(DATA_WIDTH-1) - 1
  localparam MIN_VAL = -(1 << (`DATA_WIDTH - 1)); // -2^(DATA_WIDTH-1)

  always_comb begin
    if (in >  MAX_VAL) out =  MAX_VAL;
    else if (in < MIN_VAL) out = MIN_VAL;
    else out = in[`DATA_WIDTH-1:0];
  end
endmodule
