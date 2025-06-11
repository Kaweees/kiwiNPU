`include "../include/width.svh"

// Fixed-point MAC unit optimized for NN inference
module nn_mac_unit #(
  parameter DATA_WIDTH  = `DATA_WIDTH,  // Input/weight precision
  parameter ACCUM_WIDTH = `ACC_WIDTH,   // Accumulator precision
  parameter FRAC_BITS   = 8             // Fractional bits for fixed-point
) (
  input  logic                          clk,
  input  logic                          rst_n,
  input  logic                          enable,
  input  logic                          clear_accum,  // Clear accumulator for new neuron
  input  logic signed [ DATA_WIDTH-1:0] activation,
  input  logic signed [ DATA_WIDTH-1:0] weight,
  input  logic signed [ACCUM_WIDTH-1:0] bias,
  input  logic                          bias_enable,
  output logic signed [ACCUM_WIDTH-1:0] accumulator,
  output logic                          valid
);

  logic signed [DATA_WIDTH*2-1:0] mult_result;
  logic signed [ ACCUM_WIDTH-1:0] accum_reg;
  logic                           valid_reg;

  // Multiply
  always_comb begin
    mult_result = activation * weight;
  end

  // Accumulate with bias support
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      accum_reg <= 0;
      valid_reg <= 0;
    end else begin
      valid_reg <= enable;

      if (clear_accum) begin
        if (bias_enable) begin
          accum_reg <= bias;
        end else begin
          accum_reg <= 0;
        end
      end else if (enable) begin
        accum_reg <= accum_reg + mult_result;
      end
    end
  end

  assign accumulator = accum_reg;
  assign valid       = valid_reg;

endmodule
