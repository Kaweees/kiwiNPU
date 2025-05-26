// Auto-generated test cases by quantizer_generate.py
// DATA_WIDTH=8, ACC_WIDTH=18, N=4, NUM_TESTS=10
// THIS IS A HEADER FILE - DO NOT ATTEMPT TO COMPILE DIRECTLY

`ifndef QUANTIZER_TESTCASES_SVH
`define QUANTIZER_TESTCASES_SVH

localparam int NUM_QUANTIZER_TEST = 10;

// Test vectors
logic signed [17:0] quantizer_test_input[NUM_QUANTIZER_TEST];
logic signed [7:0] quantizer_test_expected[NUM_QUANTIZER_TEST];
// Initialize test cases
function void init_quantizer_test_cases();
  // Test case 0
  quantizer_test_input[0] = 18'b010010001100001111;
  quantizer_test_expected[0] = 8'b01111111;
  // input=74511, output=127
  // Test case 1
  quantizer_test_input[1] = 18'b010111110101001111;
  quantizer_test_expected[1] = 8'b01111111;
  // input=97615, output=127
  // Test case 2
  quantizer_test_input[2] = 18'b011011101011001101;
  quantizer_test_expected[2] = 8'b01111111;
  // input=113357, output=127
  // Test case 3
  quantizer_test_input[3] = 18'b010000101110110101;
  quantizer_test_expected[3] = 8'b01111111;
  // input=68533, output=127
  // Test case 4
  quantizer_test_input[4] = 18'b010101001001000110;
  quantizer_test_expected[4] = 8'b01111111;
  // input=86598, output=127
  // Test case 5
  quantizer_test_input[5] = 18'b010011000001010101;
  quantizer_test_expected[5] = 8'b01111111;
  // input=77909, output=127
  // Test case 6
  quantizer_test_input[6] = 18'b100001001101110101;
  quantizer_test_expected[6] = 8'b10000000;
  // input=-126091, output=-128
  // Test case 7
  quantizer_test_input[7] = 18'b101010011010010011;
  quantizer_test_expected[7] = 8'b10000000;
  // input=-88429, output=-128
  // Test case 8
  quantizer_test_input[8] = 18'b000011011101100000;
  quantizer_test_expected[8] = 8'b01111111;
  // input=14176, output=127
  // Test case 9
  quantizer_test_input[9] = 18'b011011111110001101;
  quantizer_test_expected[9] = 8'b01111111;
  // input=114573, output=127
endfunction

`endif // QUANTIZER_TESTCASES_SVH
