// Auto-generated test cases by perceptron_generate.py
// DATA_WIDTH=8, ACC_WIDTH=16, N=4, NUM_TESTS=10
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
  perceptron_test_x[0][0] = 8'hb4;
  perceptron_test_x[0][1] = 8'h98;
  perceptron_test_x[0][2] = 8'd95;
  perceptron_test_x[0][3] = 8'h97;
  perceptron_test_w[0][0] = 8'd107;
  perceptron_test_w[0][1] = 8'hac;
  perceptron_test_w[0][2] = 8'd40;
  perceptron_test_w[0][3] = 8'd113;
  perceptron_test_b[0] = 8'd88;
  perceptron_test_expected[0] = 8'd0;
  // dot_product=-7461, pre_activation=-128, post_activation=0
  // Test case 1: random_2
  perceptron_test_x[1][0] = 8'd31;
  perceptron_test_x[1][1] = 8'he1;
  perceptron_test_x[1][2] = 8'd16;
  perceptron_test_x[1][3] = 8'd6;
  perceptron_test_w[1][0] = 8'hfa;
  perceptron_test_w[1][1] = 8'he5;
  perceptron_test_w[1][2] = 8'hf0;
  perceptron_test_w[1][3] = 8'hfe;
  perceptron_test_b[1] = 8'd17;
  perceptron_test_expected[1] = 8'd127;
  // dot_product=383, pre_activation=127, post_activation=127
  // Test case 2: random_3
  perceptron_test_x[2][0] = 8'd23;
  perceptron_test_x[2][1] = 8'd36;
  perceptron_test_x[2][2] = 8'd29;
  perceptron_test_x[2][3] = 8'd57;
  perceptron_test_w[2][0] = 8'hc1;
  perceptron_test_w[2][1] = 8'hf9;
  perceptron_test_w[2][2] = 8'hda;
  perceptron_test_w[2][3] = 8'hce;
  perceptron_test_b[2] = 8'hda;
  perceptron_test_expected[2] = 8'd0;
  // dot_product=-5653, pre_activation=-128, post_activation=0
  // Test case 3: random_4
  perceptron_test_x[3][0] = 8'd0;
  perceptron_test_x[3][1] = 8'd0;
  perceptron_test_x[3][2] = 8'd0;
  perceptron_test_x[3][3] = 8'd0;
  perceptron_test_w[3][0] = 8'd0;
  perceptron_test_w[3][1] = 8'd0;
  perceptron_test_w[3][2] = 8'd0;
  perceptron_test_w[3][3] = 8'd0;
  perceptron_test_b[3] = 8'h80;
  perceptron_test_expected[3] = 8'd0;
  // dot_product=0, pre_activation=-128, post_activation=0
  // Test case 4: random_5
  perceptron_test_x[4][0] = 8'd127;
  perceptron_test_x[4][1] = 8'd127;
  perceptron_test_x[4][2] = 8'd127;
  perceptron_test_x[4][3] = 8'd127;
  perceptron_test_w[4][0] = 8'd127;
  perceptron_test_w[4][1] = 8'h80;
  perceptron_test_w[4][2] = 8'h80;
  perceptron_test_w[4][3] = 8'd127;
  perceptron_test_b[4] = 8'd127;
  perceptron_test_expected[4] = 8'd0;
  // dot_product=-254, pre_activation=-127, post_activation=0
  // Test case 5: random_6
  perceptron_test_x[5][0] = 8'hac;
  perceptron_test_x[5][1] = 8'ha9;
  perceptron_test_x[5][2] = 8'hb9;
  perceptron_test_x[5][3] = 8'he3;
  perceptron_test_w[5][0] = 8'd94;
  perceptron_test_w[5][1] = 8'd37;
  perceptron_test_w[5][2] = 8'd1;
  perceptron_test_w[5][3] = 8'ha4;
  perceptron_test_b[5] = 8'hb6;
  perceptron_test_expected[5] = 8'd0;
  // dot_product=-8518, pre_activation=-128, post_activation=0
  // Test case 6: random_7
  perceptron_test_x[6][0] = 8'd0;
  perceptron_test_x[6][1] = 8'hf8;
  perceptron_test_x[6][2] = 8'd30;
  perceptron_test_x[6][3] = 8'he3;
  perceptron_test_w[6][0] = 8'd9;
  perceptron_test_w[6][1] = 8'd16;
  perceptron_test_w[6][2] = 8'hfc;
  perceptron_test_w[6][3] = 8'd27;
  perceptron_test_b[6] = 8'd25;
  perceptron_test_expected[6] = 8'd0;
  // dot_product=-1031, pre_activation=-128, post_activation=0
  // Test case 7: random_8
  perceptron_test_x[7][0] = 8'd51;
  perceptron_test_x[7][1] = 8'd5;
  perceptron_test_x[7][2] = 8'd56;
  perceptron_test_x[7][3] = 8'd49;
  perceptron_test_w[7][0] = 8'hc4;
  perceptron_test_w[7][1] = 8'he7;
  perceptron_test_w[7][2] = 8'hde;
  perceptron_test_w[7][3] = 8'hfb;
  perceptron_test_b[7] = 8'd13;
  perceptron_test_expected[7] = 8'd0;
  // dot_product=-5334, pre_activation=-128, post_activation=0
  // Test case 8: random_9
  perceptron_test_x[8][0] = 8'd0;
  perceptron_test_x[8][1] = 8'd0;
  perceptron_test_x[8][2] = 8'd0;
  perceptron_test_x[8][3] = 8'd0;
  perceptron_test_w[8][0] = 8'd0;
  perceptron_test_w[8][1] = 8'd0;
  perceptron_test_w[8][2] = 8'd0;
  perceptron_test_w[8][3] = 8'd0;
  perceptron_test_b[8] = 8'h80;
  perceptron_test_expected[8] = 8'd0;
  // dot_product=0, pre_activation=-128, post_activation=0
  // Test case 9: random_10
  perceptron_test_x[9][0] = 8'd127;
  perceptron_test_x[9][1] = 8'h80;
  perceptron_test_x[9][2] = 8'h80;
  perceptron_test_x[9][3] = 8'd127;
  perceptron_test_w[9][0] = 8'h80;
  perceptron_test_w[9][1] = 8'h80;
  perceptron_test_w[9][2] = 8'h80;
  perceptron_test_w[9][3] = 8'd127;
  perceptron_test_b[9] = 8'h80;
  perceptron_test_expected[9] = 8'd127;
  // dot_product=32641, pre_activation=127, post_activation=127
endfunction

`endif // PERCEPTRON_TESTCASES_SVH
