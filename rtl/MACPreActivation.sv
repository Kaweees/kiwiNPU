`include "../include/width.svh"

module MACPreActivation #(
  parameter int N = `N,  // Data dimensionality
  parameter DATA_WIDTH = `DATA_WIDTH,  // Data width
  parameter ACC_WIDTH = (DATA_WIDTH * 2 + $clog2(N))  // Accumulator width
) (
  input  logic                           clk,    // System clock
  input  logic                           rst_n,  // Asynchronous reset (active low)
  input  logic signed [DATA_WIDTH-1:0] x,      // First vector (packed)
  input  logic signed [DATA_WIDTH-1:0] w,      // Second vector (packed)
  input  logic signed [  DATA_WIDTH-1:0] b,      // Bias vector
  output logic signed [   ACC_WIDTH-1:0] pre     // Pre-activation result
);

  // Multiply
  logic signed [ACC_WIDTH-1:0] mult_result;
  always_comb begin
    mult_result = x * w;
  end

  // Accumulate with bias support
  logic signed [ACC_WIDTH-1:0] accum_reg;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      accum_reg <= {{(ACC_WIDTH-DATA_WIDTH){b[DATA_WIDTH-1]}}, b}; // Add sign-extended bias to dot product
    end else begin
      accum_reg <= accum_reg + mult_result;
    end
    $display("[PreActivation DEBUG] x=%0d, w=%0d, b=%0d, dp=%0d", x, w, b, accum_reg);
  end
endmodule
