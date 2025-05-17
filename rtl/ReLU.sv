module ReLU #(parameter WIDTH = `FP_WIDTH) (
  input logic signed [WIDTH-1:0] x,
  output logic signed [WIDTH-1:0] y
);
  assign y = (x[WIDTH-1]) ? 0 : x;
endmodule
