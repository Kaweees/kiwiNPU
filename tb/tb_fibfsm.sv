`timescale 1ns / 1ps

module tb_fibfsm();
  // Declare test bench parameters
  localparam CLK_PERIOD = 10; // Clock period in ns (100MHz clock)

  // Declare test bench input/output signals
  logic sCLK, sRST_N, sVLD_IN, sRDY_OUT, sRDY_IN, sVLD_OUT;
  logic [7:0] sFIB_IN;
  logic [31:0] sFIB_OUT;

  // Instantiate the Fibonacci calculator
  FibFSM #(
    .INPUT_WIDTH(8),
    .OUTPUT_WIDTH(32)
  ) DUT (
    .clk(sCLK),
    .rst_n(sRST_N),
    .fib_in(sFIB_IN),
    .vld_in(sVLD_IN),
    .rdy_out(sRDY_OUT),
    .rdy_in(sRDY_IN),
    .fib_out(sFIB_OUT),
    .vld_out(sVLD_OUT)
  ); // Device Under Testing (DUT)

  // Clock generation
  initial begin
    sCLK = 1'b1;  // Start simulation with positive edge
    // Toggle the clock every 5 ns
    forever #(CLK_PERIOD / 2) sCLK = ~sCLK;
  end

  // Function to calculate expected Fibonacci number
  function automatic [31:0] calculate_fibonacci(input [7:0] n);
    logic [31:0] a, b, temp;
    int i;

    if (n == 0)
      return 0;
    else if (n == 1)
      return 1;
    else begin
      a = 0;
      b = 1;

      for (i = 2; i <= n; i++) begin
        temp = b;
        b = a + b;
        a = temp;
      end
      return b;
    end
  endfunction

  // Task to send a number to the calculator
  task send_number(input [7:0] number);
    // Wait until calculator is ready
    while (!sRDY_IN) @(posedge sCLK);

    // Send the number
    sFIB_IN = number;
    sVLD_IN = 1;
    @(posedge sCLK);
    sVLD_IN = 0;
  endtask

  // Task to receive result from calculator
  task receive_result(output [31:0] result);
    // Wait until result is valid
    while (!sVLD_OUT) @(posedge sCLK);

    // Read the result
    result = sFIB_OUT;
    sRDY_OUT = 1;
    @(posedge sCLK);
    sRDY_OUT = 0;
  endtask

  initial begin
    // Initialize signals
    sCLK = 0;
    sRST_N = 0;
    sFIB_IN = 0;
    sVLD_IN = 0;
    sRDY_OUT = 0;

    // Reset the design
    @(posedge sCLK);
    sRST_N = 1;

    // Test cases
    begin
      int i;
      logic [31:0] expected_result;
      logic [31:0] actual_result;

      for (i = 0; i <= 10; i++) begin
        // Calculate expected result
        expected_result = calculate_fibonacci(8'(i));

        // Send number to calculator
        send_number(8'(i));

        // Receive result
        receive_result(actual_result);

        // Verify result
        if (actual_result != expected_result) begin
          $error("Fibonacci(%0d) = %0d, expected %0d",
                i, actual_result, expected_result);
        end

        $display("Fibonacci(%0d) = %0d", i, actual_result);
      end
    end
    $display("All tests passed!");
    $finish(); // Terminate simulation
  end

  // Waveform dump
  initial begin
    $dumpfile("tb_fibfsm.vcd");
    $dumpvars(0, tb_fibfsm);
  end
endmodule
