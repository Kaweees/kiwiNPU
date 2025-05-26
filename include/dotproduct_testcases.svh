// Auto-generated test cases by dotproduct_generate.py
// DATA_WIDTH=8, ACC_WIDTH=18, N=4, NUM_TESTS=10
// THIS IS A HEADER FILE - DO NOT ATTEMPT TO COMPILE DIRECTLY

`ifndef DOTPRODUCT_TESTCASES_SVH
`define DOTPRODUCT_TESTCASES_SVH

localparam int NUM_DOT_PRODUCT_TEST = 10;

// Test vectors
logic signed [7:0] dotproduct_test_x[NUM_DOT_PRODUCT_TEST][4];
logic signed [7:0] dotproduct_test_w[NUM_DOT_PRODUCT_TEST][4];
logic signed [17:0] dotproduct_test_expected[NUM_DOT_PRODUCT_TEST];
// Initialize test cases
function void init_dotproduct_test_cases();
  // Test case 0: random_1
  dotproduct_test_x[0][0] = 8'hee;
  dotproduct_test_x[0][1] = 8'd0;
  dotproduct_test_x[0][2] = 8'd118;
  dotproduct_test_x[0][3] = 8'd96;
  dotproduct_test_w[0][0] = 8'hee;
  dotproduct_test_w[0][1] = 8'hf3;
  dotproduct_test_w[0][2] = 8'd63;
  dotproduct_test_w[0][3] = 8'd3;
  dotproduct_test_expected[0] = 18'd8046;
  // Test case 1: random_2
  dotproduct_test_x[1][0] = 8'd15;
  dotproduct_test_x[1][1] = 8'd31;
  dotproduct_test_x[1][2] = 8'd5;
  dotproduct_test_x[1][3] = 8'he4;
  dotproduct_test_w[1][0] = 8'd2;
  dotproduct_test_w[1][1] = 8'hf5;
  dotproduct_test_w[1][2] = 8'he7;
  dotproduct_test_w[1][3] = 8'hf4;
  dotproduct_test_expected[1] = 18'h3ff9c;
  // Test case 2: random_3
  dotproduct_test_x[2][0] = 8'd16;
  dotproduct_test_x[2][1] = 8'd9;
  dotproduct_test_x[2][2] = 8'd26;
  dotproduct_test_x[2][3] = 8'd3;
  dotproduct_test_w[2][0] = 8'hee;
  dotproduct_test_w[2][1] = 8'he4;
  dotproduct_test_w[2][2] = 8'hcd;
  dotproduct_test_w[2][3] = 8'he8;
  dotproduct_test_expected[2] = 18'h3f86e;
  // Test case 3: random_4
  dotproduct_test_x[3][0] = 8'd127;
  dotproduct_test_x[3][1] = 8'h80;
  dotproduct_test_x[3][2] = 8'h80;
  dotproduct_test_x[3][3] = 8'h80;
  dotproduct_test_w[3][0] = 8'h80;
  dotproduct_test_w[3][1] = 8'h80;
  dotproduct_test_w[3][2] = 8'd127;
  dotproduct_test_w[3][3] = 8'h80;
  dotproduct_test_expected[3] = 18'd256;
  // Test case 4: random_5
  dotproduct_test_x[4][0] = 8'd6;
  dotproduct_test_x[4][1] = 8'hf9;
  dotproduct_test_x[4][2] = 8'hfc;
  dotproduct_test_x[4][3] = 8'd7;
  dotproduct_test_w[4][0] = 8'd8;
  dotproduct_test_w[4][1] = 8'd4;
  dotproduct_test_w[4][2] = 8'hfe;
  dotproduct_test_w[4][3] = 8'd0;
  dotproduct_test_expected[4] = 18'd28;
  // Test case 5: random_6
  dotproduct_test_x[5][0] = 8'h80;
  dotproduct_test_x[5][1] = 8'h80;
  dotproduct_test_x[5][2] = 8'd127;
  dotproduct_test_x[5][3] = 8'h80;
  dotproduct_test_w[5][0] = 8'h80;
  dotproduct_test_w[5][1] = 8'd127;
  dotproduct_test_w[5][2] = 8'h80;
  dotproduct_test_w[5][3] = 8'd127;
  dotproduct_test_expected[5] = 18'h38180;
  // Test case 6: random_7
  dotproduct_test_x[6][0] = 8'hab;
  dotproduct_test_x[6][1] = 8'd40;
  dotproduct_test_x[6][2] = 8'h8f;
  dotproduct_test_x[6][3] = 8'd61;
  dotproduct_test_w[6][0] = 8'd64;
  dotproduct_test_w[6][1] = 8'h9c;
  dotproduct_test_w[6][2] = 8'hcf;
  dotproduct_test_w[6][3] = 8'd14;
  dotproduct_test_expected[6] = 18'h3f417;
  // Test case 7: random_8
  dotproduct_test_x[7][0] = 8'd20;
  dotproduct_test_x[7][1] = 8'd26;
  dotproduct_test_x[7][2] = 8'd16;
  dotproduct_test_x[7][3] = 8'he7;
  dotproduct_test_w[7][0] = 8'd12;
  dotproduct_test_w[7][1] = 8'he8;
  dotproduct_test_w[7][2] = 8'hec;
  dotproduct_test_w[7][3] = 8'd19;
  dotproduct_test_expected[7] = 18'h3fb65;
  // Test case 8: random_9
  dotproduct_test_x[8][0] = 8'd58;
  dotproduct_test_x[8][1] = 8'd32;
  dotproduct_test_x[8][2] = 8'd15;
  dotproduct_test_x[8][3] = 8'd56;
  dotproduct_test_w[8][0] = 8'hee;
  dotproduct_test_w[8][1] = 8'hdd;
  dotproduct_test_w[8][2] = 8'hf6;
  dotproduct_test_w[8][3] = 8'hd7;
  dotproduct_test_expected[8] = 18'h3edfe;
  // Test case 9: random_10
  dotproduct_test_x[9][0] = 8'h80;
  dotproduct_test_x[9][1] = 8'h80;
  dotproduct_test_x[9][2] = 8'd127;
  dotproduct_test_x[9][3] = 8'h80;
  dotproduct_test_w[9][0] = 8'd127;
  dotproduct_test_w[9][1] = 8'h80;
  dotproduct_test_w[9][2] = 8'd127;
  dotproduct_test_w[9][3] = 8'd127;
  dotproduct_test_expected[9] = 18'd1;
endfunction

`endif // DOTPRODUCT_TESTCASES_SVH
