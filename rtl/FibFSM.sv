`timescale 1ns / 1ps

module FibFSM #(
  parameter INPUT_WIDTH = 8,  // Width of input number
  parameter OUTPUT_WIDTH = 32 // Width of output result
)(
  input logic clk,                    // Clock signal
  input logic rst_n,                  // Active low synchronous reset
  input logic [INPUT_WIDTH-1:0] fib_in,  // Input number
  input logic vld_in,                 // Input valid
  input logic rdy_out,                // Output ready
  output logic rdy_in,                // Input ready
  output logic [OUTPUT_WIDTH-1:0] fib_out, // Output result
  output logic vld_out                // Output valid
);

  // Define states for the FSM
  typedef enum logic [1:0] {
    IDLE,        // Waiting for input
    CALCULATING, // Calculating Fibonacci number
    DONE         // Result ready
  } state_t;

  // Define state register
  state_t cur_state, next_state;

  // Internal registers for calculation
  logic [OUTPUT_WIDTH-1:0] a, b;  // Previous two Fibonacci numbers
  logic [INPUT_WIDTH-1:0] counter; // Counter for calculation steps
  logic [INPUT_WIDTH-1:0] cur_num;       // Store input number

  // State transition logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cur_state <= IDLE;
      a <= 0;
      b <= 1;
      counter <= 0;
      cur_num <= 0;
    end else begin
      cur_state <= next_state;
      // Update calculation registers
      case (cur_state)
        IDLE: begin
          if (vld_in && rdy_in) begin
            cur_num <= fib_in;
            counter <= 0;
            a <= 0; // First number in Fibonacci sequence
            b <= 1; // Second number in Fibonacci sequence
          end
        end
        CALCULATING: begin
          if (counter < cur_num - 1) begin
            b <= a + b; // Calculate next fib number
            a <= b;
            counter <= counter + 1;
          end
        end
        DONE: begin
        end
        default: ; // Do nothing for DONE and undefined states
      endcase
    end
  end

  // Define next state logic
  always_comb begin
    next_state = cur_state;
    case (cur_state)
      IDLE:
        if (vld_in && rdy_in)
          next_state = state_t'((fib_in <= 1) ? DONE : CALCULATING);
      CALCULATING:
        if (counter >= cur_num - 1)
          next_state = DONE;
      DONE:
        if (rdy_out)
          next_state = IDLE;
      default: next_state = IDLE;
    endcase
  end

  // Output assignments
  assign rdy_in = (cur_state == IDLE);
  assign vld_out = (cur_state == DONE);
  assign fib_out = (cur_num == 0) ? 0 : (cur_num == 1) ? 1 : b;
endmodule
