`timescale 1ns / 1ps

module tb_relu();
  // Declare test bench parameters
  localparam CLK_PERIOD = 10; // Clock period in ns (100MHz clock)
  localparam WIDTH = 16;      // Width of the signals

  // Declare test bench input/output signals
  logic signed [WIDTH-1:0] sIN;
  logic signed [WIDTH-1:0] sOUT;

  // Instantiate the ReLU module
  ReLU #(
    .WIDTH(WIDTH)
  ) DUT (
    .x(sIN),
    .y(sOUT)
  );

  // Test cases
  initial begin
    // Test Case 1: Positive number
    sIN = 16'h0123;  // Some positive number
    #10;
    if (sOUT !== sIN) begin
      $error("Test Case 1 failed: Expected %0h, Got %0h", sIN, sOUT);
    end else begin
      $display("Test Case 1 passed: ReLU(%0h) = %0h", sIN, sOUT);
    end

    // // Test Case 2: Zero
    // sIN = 16'h0000;
    // #10;
    // if (sOUT !== sIN) begin
    //   $error("Test Case 2 failed: Expected %0h, Got %0h", sIN, sOUT);
    // end else begin
    //   $display("Test Case 2 passed: ReLU(%0h) = %0h", sIN, sOUT);
    // end

    // // Test Case 3: Negative number
    // sIN = 16'h8123;  // Some negative number (MSB=1)
    // #10;
    // if (sOUT !== 16'h0000) begin
    //   $error("Test Case 3 failed: Expected 0, Got %0h", sOUT);
    // end else begin
    //   $display("Test Case 3 passed: ReLU(%0h) = %0h", sIN, sOUT);
    // end

    $display("All tests completed!");
    #100; // Add a delay before finishing to ensure VCD is written
    $finish();
  end

  // Waveform dump
  initial begin
    $dumpfile("tb_relu.vcd");
    $dumpvars(0, tb_relu);
  end
endmodule
