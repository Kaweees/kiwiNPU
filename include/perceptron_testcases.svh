// Auto-generated test cases by perceptron_generate.py
// DATA_WIDTH=8, ACC_WIDTH=18, N=4, NUM_TESTS=10
// THIS IS A HEADER FILE - DO NOT ATTEMPT TO COMPILE DIRECTLY

`ifndef PERCEPTRON_TESTCASES_SVH
`define PERCEPTRON_TESTCASES_SVH

localparam int NUM_PERCEPTRON_TEST = 10;

// Test vectors
logic signed [7:0] perceptron_test_x[NUM_PERCEPTRON_TEST][4];
logic signed [7:0] perceptron_test_w[NUM_PERCEPTRON_TEST][4];
logic signed [7:0] perceptron_test_b[NUM_PERCEPTRON_TEST];
logic signed [7:0] perceptron_test_expected[NUM_PERCEPTRON_TEST];
// Initialize test cases
function void init_perceptron_test_cases();
  // Test case 0: random_1
  perceptron_test_x[0][0] = 8'b10000111;
  perceptron_test_x[0][1] = 8'b01010000;
  perceptron_test_x[0][2] = 8'b10011010;
  perceptron_test_x[0][3] = 8'b01000101;
  perceptron_test_w[0][0] = 8'b10000000;
  perceptron_test_w[0][1] = 8'b01111011;
  perceptron_test_w[0][2] = 8'b10111010;
  perceptron_test_w[0][3] = 8'b10001110;
  perceptron_test_b[0] = 8'b00110010;
  perceptron_test_expected[0] = 8'b01111111;
  // dot_product=24602, pre_activation=127, post_activation=127
  // Test case 1: random_2
  perceptron_test_x[1][0] = 8'b11100011;
  perceptron_test_x[1][1] = 8'b11110011;
  perceptron_test_x[1][2] = 8'b11100001;
  perceptron_test_x[1][3] = 8'b11100110;
  perceptron_test_w[1][0] = 8'b00001110;
  perceptron_test_w[1][1] = 8'b00010101;
  perceptron_test_w[1][2] = 8'b11110110;
  perceptron_test_w[1][3] = 8'b11111111;
  perceptron_test_b[1] = 8'b00001000;
  perceptron_test_expected[1] = 8'b00000000;
  // dot_product=-343, pre_activation=-128, post_activation=0
  // Test case 2: random_3
  perceptron_test_x[2][0] = 8'b00001010;
  perceptron_test_x[2][1] = 8'b00111111;
  perceptron_test_x[2][2] = 8'b00101000;
  perceptron_test_x[2][3] = 8'b00100111;
  perceptron_test_w[2][0] = 8'b11100001;
  perceptron_test_w[2][1] = 8'b11111110;
  perceptron_test_w[2][2] = 8'b11100010;
  perceptron_test_w[2][3] = 8'b11000100;
  perceptron_test_b[2] = 8'b11000101;
  perceptron_test_expected[2] = 8'b00000000;
  // dot_product=-3976, pre_activation=-128, post_activation=0
  // Test case 3: random_4
  perceptron_test_x[3][0] = 8'b00000000;
  perceptron_test_x[3][1] = 8'b00000000;
  perceptron_test_x[3][2] = 8'b00000000;
  perceptron_test_x[3][3] = 8'b00000000;
  perceptron_test_w[3][0] = 8'b00000000;
  perceptron_test_w[3][1] = 8'b00000000;
  perceptron_test_w[3][2] = 8'b00000000;
  perceptron_test_w[3][3] = 8'b00000000;
  perceptron_test_b[3] = 8'b10000000;
  perceptron_test_expected[3] = 8'b00000000;
  // dot_product=0, pre_activation=-128, post_activation=0
  // Test case 4: random_5
  perceptron_test_x[4][0] = 8'b01111111;
  perceptron_test_x[4][1] = 8'b01111111;
  perceptron_test_x[4][2] = 8'b01111111;
  perceptron_test_x[4][3] = 8'b01111111;
  perceptron_test_w[4][0] = 8'b01111111;
  perceptron_test_w[4][1] = 8'b01111111;
  perceptron_test_w[4][2] = 8'b01111111;
  perceptron_test_w[4][3] = 8'b10000000;
  perceptron_test_b[4] = 8'b01111111;
  perceptron_test_expected[4] = 8'b01111111;
  // dot_product=32131, pre_activation=127, post_activation=127
  // Test case 5: random_6
  perceptron_test_x[5][0] = 8'b00010110;
  perceptron_test_x[5][1] = 8'b00000010;
  perceptron_test_x[5][2] = 8'b11110000;
  perceptron_test_x[5][3] = 8'b01011101;
  perceptron_test_w[5][0] = 8'b10101100;
  perceptron_test_w[5][1] = 8'b11001001;
  perceptron_test_w[5][2] = 8'b00100010;
  perceptron_test_w[5][3] = 8'b01101010;
  perceptron_test_b[5] = 8'b11100001;
  perceptron_test_expected[5] = 8'b01111111;
  // dot_product=7356, pre_activation=127, post_activation=127
  // Test case 6: random_7
  perceptron_test_x[6][0] = 8'b11101100;
  perceptron_test_x[6][1] = 8'b11100111;
  perceptron_test_x[6][2] = 8'b11110010;
  perceptron_test_x[6][3] = 8'b11110011;
  perceptron_test_w[6][0] = 8'b00011011;
  perceptron_test_w[6][1] = 8'b00011011;
  perceptron_test_w[6][2] = 8'b00010000;
  perceptron_test_w[6][3] = 8'b11100111;
  perceptron_test_b[6] = 8'b00000000;
  perceptron_test_expected[6] = 8'b00000000;
  // dot_product=-1114, pre_activation=-128, post_activation=0
  // Test case 7: random_8
  perceptron_test_x[7][0] = 8'b00111101;
  perceptron_test_x[7][1] = 8'b00010110;
  perceptron_test_x[7][2] = 8'b00100001;
  perceptron_test_x[7][3] = 8'b00101000;
  perceptron_test_w[7][0] = 8'b11001001;
  perceptron_test_w[7][1] = 8'b11001010;
  perceptron_test_w[7][2] = 8'b11011010;
  perceptron_test_w[7][3] = 8'b11000100;
  perceptron_test_b[7] = 8'b11110010;
  perceptron_test_expected[7] = 8'b00000000;
  // dot_product=-8197, pre_activation=-128, post_activation=0
  // Test case 8: random_9
  perceptron_test_x[8][0] = 8'b00000000;
  perceptron_test_x[8][1] = 8'b00000000;
  perceptron_test_x[8][2] = 8'b00000000;
  perceptron_test_x[8][3] = 8'b00000000;
  perceptron_test_w[8][0] = 8'b00000000;
  perceptron_test_w[8][1] = 8'b00000000;
  perceptron_test_w[8][2] = 8'b00000000;
  perceptron_test_w[8][3] = 8'b00000000;
  perceptron_test_b[8] = 8'b10000000;
  perceptron_test_expected[8] = 8'b00000000;
  // dot_product=0, pre_activation=-128, post_activation=0
  // Test case 9: random_10
  perceptron_test_x[9][0] = 8'b10000000;
  perceptron_test_x[9][1] = 8'b01111111;
  perceptron_test_x[9][2] = 8'b10000000;
  perceptron_test_x[9][3] = 8'b01111111;
  perceptron_test_w[9][0] = 8'b10000000;
  perceptron_test_w[9][1] = 8'b10000000;
  perceptron_test_w[9][2] = 8'b01111111;
  perceptron_test_w[9][3] = 8'b01111111;
  perceptron_test_b[9] = 8'b01111111;
  perceptron_test_expected[9] = 8'b01111111;
  // dot_product=1, pre_activation=127, post_activation=127
endfunction

`endif // PERCEPTRON_TESTCASES_SVH
