`timescale 1ns/1ps
`include "../include/width.svh"

module tb_kiwinpu;
  // Parameters
  localparam int NUM_LAYERS = `NUM_LAYERS;
  localparam [NUM_LAYERS*8-1:0] LAYER_SIZES = `LAYER_SIZES;
  localparam int DATA_WIDTH = `DATA_WIDTH;

  // Function to get layer size (copied from KiwiNPU.sv)
  function integer get_layer_size;
    input integer idx;
    integer offset;
    begin
      offset = (NUM_LAYERS - 1 - idx) * 8;
      get_layer_size = {24'd0, LAYER_SIZES[offset +: 8]};
    end
  endfunction

  // Function to calculate total bits for weights (copied from KiwiNPU.sv)
  function integer calc_weights_bits;
    integer sum;
    integer j;
    integer sz_j;
    integer sz_jm1;
    begin
      sum = 0;
      for (j = 1; j < NUM_LAYERS; j = j + 1) begin
        sz_j    = get_layer_size(j);
        sz_jm1  = get_layer_size(j - 1);
        sum     = sum + (sz_j * sz_jm1 * DATA_WIDTH);
      end
      calc_weights_bits = sum;
    end
  endfunction

  // Function to calculate total bits for biases (copied from KiwiNPU.sv)
  function integer calc_biases_bits;
    integer sum;
    integer j;
    integer sz_j;
    begin
      sum = 0;
      for (j = 1; j < NUM_LAYERS; j = j + 1) begin
        sz_j = get_layer_size(j);
        sum  = sum + (sz_j * DATA_WIDTH);
      end
      calc_biases_bits = sum;
    end
  endfunction

  // Clock and reset signals
  logic clk;
  logic rst_n;

  // Input/Output vectors
  logic signed [get_layer_size(0)*DATA_WIDTH-1:0] in_vec;
  logic signed [get_layer_size(NUM_LAYERS-1)*DATA_WIDTH-1:0] out_vec;

  // Weight and bias signals (flattened)
  logic signed [calc_weights_bits()-1:0] weights_flat;
  logic signed [calc_biases_bits()-1:0] biases_flat;

  // Instantiate the DUT
  KiwiNPU #(
    .NUM_LAYERS(NUM_LAYERS),
    .LAYER_SIZES(LAYER_SIZES),
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .in_vec(in_vec),
    .weights_flat(weights_flat),
    .biases_flat(biases_flat),
    .out_vec(out_vec)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100MHz clock
  end

  // Test stimulus
  initial begin
    // Initialize signals
    rst_n = 0;
    in_vec = 0;
    weights_flat = 0;
    biases_flat = 0;

    // Reset sequence
    #100;
    rst_n = 1;
    #20;

    // Test Case 1: Simple input pattern with identity weights
    // Set weights to identity matrix (1s on diagonal)
    for (int i = 0; i < get_layer_size(1); i++) begin
      for (int j = 0; j < get_layer_size(0); j++) begin
        weights_flat[i*get_layer_size(0)*DATA_WIDTH + j*DATA_WIDTH +: DATA_WIDTH] = (i == j) ? 8'h01 : 8'h00;
      end
      biases_flat[i*DATA_WIDTH +: DATA_WIDTH] = 8'h00;
    end
    for (int i = 0; i < get_layer_size(2); i++) begin
      for (int j = 0; j < get_layer_size(1); j++) begin
        weights_flat[get_layer_size(1)*get_layer_size(0)*DATA_WIDTH + i*get_layer_size(1)*DATA_WIDTH + j*DATA_WIDTH +: DATA_WIDTH] = (i == j) ? 8'h01 : 8'h00;
      end
      biases_flat[get_layer_size(1)*DATA_WIDTH + i*DATA_WIDTH +: DATA_WIDTH] = 8'h00;
    end
    in_vec = {4{8'h01}};  // All inputs set to 1
    #100;

    // Test Case 2: Alternating pattern with alternating weights
    for (int i = 0; i < get_layer_size(1); i++) begin
      for (int j = 0; j < get_layer_size(0); j++) begin
        weights_flat[i*get_layer_size(0)*DATA_WIDTH + j*DATA_WIDTH +: DATA_WIDTH] = ((i + j) % 2) ? 8'h01 : 8'hFF;
      end
      biases_flat[i*DATA_WIDTH +: DATA_WIDTH] = 8'h00;
    end
    for (int i = 0; i < get_layer_size(2); i++) begin
      for (int j = 0; j < get_layer_size(1); j++) begin
        weights_flat[get_layer_size(1)*get_layer_size(0)*DATA_WIDTH + i*get_layer_size(1)*DATA_WIDTH + j*DATA_WIDTH +: DATA_WIDTH] = ((i + j) % 2) ? 8'h01 : 8'hFF;
      end
      biases_flat[get_layer_size(1)*DATA_WIDTH + i*DATA_WIDTH +: DATA_WIDTH] = 8'h00;
    end
    in_vec = {4{8'hAA}};  // Alternating 1s and 0s
    #100;

    // Test Case 3: Maximum values with maximum weights
    for (int i = 0; i < get_layer_size(1); i++) begin
      for (int j = 0; j < get_layer_size(0); j++) begin
        weights_flat[i*get_layer_size(0)*DATA_WIDTH + j*DATA_WIDTH +: DATA_WIDTH] = 8'h7F;  // Maximum positive value
      end
      biases_flat[i*DATA_WIDTH +: DATA_WIDTH] = 8'h00;
    end
    for (int i = 0; i < get_layer_size(2); i++) begin
      for (int j = 0; j < get_layer_size(1); j++) begin
        weights_flat[get_layer_size(1)*get_layer_size(0)*DATA_WIDTH + i*get_layer_size(1)*DATA_WIDTH + j*DATA_WIDTH +: DATA_WIDTH] = 8'h7F;  // Maximum positive value
      end
      biases_flat[get_layer_size(1)*DATA_WIDTH + i*DATA_WIDTH +: DATA_WIDTH] = 8'h00;
    end
    in_vec = {4{8'h7F}};  // Maximum positive values
    #100;

    // Test Case 4: Random pattern with random weights
    for (int i = 0; i < get_layer_size(1); i++) begin
      for (int j = 0; j < get_layer_size(0); j++) begin
        weights_flat[i*get_layer_size(0)*DATA_WIDTH + j*DATA_WIDTH +: DATA_WIDTH] = $random;
      end
      biases_flat[i*DATA_WIDTH +: DATA_WIDTH] = $random;
    end
    for (int i = 0; i < get_layer_size(2); i++) begin
      for (int j = 0; j < get_layer_size(1); j++) begin
        weights_flat[get_layer_size(1)*get_layer_size(0)*DATA_WIDTH + i*get_layer_size(1)*DATA_WIDTH + j*DATA_WIDTH +: DATA_WIDTH] = $random;
      end
      biases_flat[get_layer_size(1)*DATA_WIDTH + i*DATA_WIDTH +: DATA_WIDTH] = $random;
    end
    in_vec = $random;
    #100;

    // End simulation
    #100;
    $finish;
  end

  // Monitor and verification
  initial begin
    $monitor("Time=%0t rst_n=%b in_vec=%h weights_flat=%h biases_flat=%h out_vec=%h",
             $time, rst_n, in_vec, weights_flat, biases_flat, out_vec);
  end

  // Waveform dumping
  initial begin
    $dumpfile("tb_kiwinpu.vcd");
    $dumpvars(0, tb_kiwinpu);
  end

endmodule
