`timescale 1ns / 1ps
`include "../include/width.svh"

module tb_perceptron();
  // Declare test bench parameters
  localparam CLK_PERIOD = 10; // Clock period in ns (100MHz clock)
  localparam N = 4; // Vector dimensionality

  // Declare test bench input/output signals
  logic sCLK, sRST_N;
  logic signed [`DATA_WIDTH-1:0] sX[N], sW[N], sB, sY;

  // Instantiate the Perceptron module
  Perceptron #(
    .N(N)
  ) DUT (
    .clk(sCLK),
    .rst_n(sRST_N),
    .x(sX),
    .w(sW),
    .b(sB),
    .y(sY)
  );

  // Clock generation
  initial begin
    sCLK = 1'b1;  // Start simulation with positive edge
    // Toggle the clock every 5 ns
    forever #(CLK_PERIOD / 2) sCLK = ~sCLK;
  end;

  initial begin
    // Initialize signals
    sCLK = 0;
    sX = '{default: 0};
    sW = '{default: 0};
    sB = 8'h00;

    // Test cases
    begin
      // Test case 1: Basic computation
      sX = '{default: 0};
      sW = '{default: 0};
      sB = 8'h00;
    end

    $display("All tests completed!");
    $finish(); // Terminate simulation
  end

  // Waveform dump
  initial begin
    $dumpfile("tb_perceptron.vcd");
    $dumpvars(0, tb_perceptron);
  end
endmodule
