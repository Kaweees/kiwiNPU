`timescale 1ns / 1ps
`include "../include/width.svh"

module Quantizer #(
  parameter int DATA_WIDTH = `DATA_WIDTH,
  parameter int ACC_WIDTH = `ACC_WIDTH
) (
  input  logic signed [ACC_WIDTH-1:0] in,
  output logic signed [DATA_WIDTH-1:0] out
);
  // Saturated maximum and minimum values for signed DATA_WIDTH
  localparam MIN_VAL = - (1 << (DATA_WIDTH - 1)); // -2^(DATA_WIDTH-1)
  localparam MAX_VAL = (1 << (DATA_WIDTH - 1)) - 1;  // 2^(DATA_WIDTH-1) - 1

  always_comb begin
    if (in >  MAX_VAL) out =  MAX_VAL;
    else if (in < MIN_VAL) out = MIN_VAL;
    else out = in[DATA_WIDTH-1:0];
  end
endmodule
