`include "../include/width.svh"

module PreActivation #(
  parameter int N = `N,  // Data dimensionality
  parameter DATA_WIDTH = `DATA_WIDTH,  // Data width
  parameter int ACC_WIDTH = `ACC_WIDTH  // Accumulator width
) (
  input  logic signed [N*DATA_WIDTH-1:0] x,   // First vector (packed)
  input  logic signed [N*DATA_WIDTH-1:0] w,   // Second vector (packed)
  input  logic signed [  DATA_WIDTH-1:0] b,   // Bias vector
  output logic signed [   ACC_WIDTH-1:0] pre  // Pre-activation result
);
  logic signed [DATA_WIDTH-1:0] x_arr                     [N];
  logic signed [DATA_WIDTH-1:0] w_arr                     [N];
  logic signed [ ACC_WIDTH-1:0] dp;  // Dot product result
  genvar gi;
  generate
    for (gi = 0; gi < N; gi++) begin
      assign x_arr[gi] = x[gi*DATA_WIDTH+:DATA_WIDTH];
      assign w_arr[gi] = w[gi*DATA_WIDTH+:DATA_WIDTH];
    end
  endgenerate

  always_comb begin
    dp = '0;
    for (int i = 0; i < N; i++) begin
      dp += x_arr[i] * w_arr[i];
    end
    pre = dp + {{(ACC_WIDTH-DATA_WIDTH){b[DATA_WIDTH-1]}}, b};  // Add sign-extended bias to dot product
  end
endmodule
