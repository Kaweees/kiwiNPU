`include "../include/width.svh"

module DotProduct #(
  parameter int N = 4,  // Data dimensionality
  parameter DATA_WIDTH = `DATA_WIDTH,  // Data width
  parameter ACC_WIDTH = `ACC_WIDTH  // Accumulator width
) (
  input  logic signed [N*DATA_WIDTH-1:0] x,  // First vector (packed)
  input  logic signed [N*DATA_WIDTH-1:0] w,  // Second vector (packed)
  output logic signed [   ACC_WIDTH-1:0] dp  // Dot product result
);
  logic signed [DATA_WIDTH-1:0] x_arr[N];
  logic signed [DATA_WIDTH-1:0] w_arr[N];
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
      $display("[DotProduct DEBUG] x[%0d]=%0d, w[%0d]=%0d, dp=%0d", i, x_arr[i], i, w_arr[i], dp);
    end
  end
endmodule
