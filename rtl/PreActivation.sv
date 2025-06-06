`include "../include/width.svh"

module PreActivation #(
  parameter int N = `N,  // Data dimensionality
  parameter DATA_WIDTH = `DATA_WIDTH,  // Data width
  parameter ACC_WIDTH = (DATA_WIDTH * 2 + $clog2(N))  // Accumulator width
) (
  input  logic                           clk,    // System clock
  input  logic                           rst_n,  // Asynchronous reset (active low)
  input  logic signed [N*DATA_WIDTH-1:0] x,      // First vector (packed)
  input  logic signed [N*DATA_WIDTH-1:0] w,      // Second vector (packed)
  input  logic signed [  DATA_WIDTH-1:0] b,      // Bias vector
  output logic signed [   ACC_WIDTH-1:0] pre     // Pre-activation result
);
  logic signed [DATA_WIDTH-1:0] x_arr                     [N];
  logic signed [DATA_WIDTH-1:0] w_arr                     [N];
  logic signed [ ACC_WIDTH-1:0] dp;  // Dot product result
  genvar i;
  generate
    for (i = 0; i < N; i++) begin
      assign x_arr[i] = x[i*DATA_WIDTH+:DATA_WIDTH];
      assign w_arr[i] = w[i*DATA_WIDTH+:DATA_WIDTH];
    end
  endgenerate

  always_comb begin
    dp = '0;
    for (int i = 0; i < N; i++) begin
      dp += x_arr[i] * w_arr[i];
      $display("[PreActivation DEBUG] x[%0d]=%0d, w[%0d]=%0d, b=%0d, dp=%0d", i, x_arr[i], i, w_arr[i], b, dp);
    end
    pre = dp + {{(ACC_WIDTH-DATA_WIDTH){b[DATA_WIDTH-1]}}, b};  // Add sign-extended bias to dot product
  end
endmodule
