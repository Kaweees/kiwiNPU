module WeightLoader #(
  parameter int IN_N = `N,
  parameter int HIDDEN_N = `M,
  parameter int OUT_N = `N,
  parameter int DATA_WIDTH = `DATA_WIDTH
) (
  input logic clk,
  input logic rst_n,

  // SPI Interface
  output logic flash_csb,
  output logic flash_clk,
  output logic flash_io0_oe,
  output logic flash_io1_oe,
  output logic flash_io2_oe,
  output logic flash_io3_oe,
  output logic flash_io0_do,
  output logic flash_io1_do,
  output logic flash_io2_do,
  output logic flash_io3_do,
  input  logic flash_io0_di,
  input  logic flash_io1_di,
  input  logic flash_io2_di,
  input  logic flash_io3_di,

  // KiwiNPU Interface
  output logic signed [ HIDDEN_N*IN_N*DATA_WIDTH-1:0] weights1,
  output logic signed [      HIDDEN_N*DATA_WIDTH-1:0] biases1,
  output logic signed [OUT_N*HIDDEN_N*DATA_WIDTH-1:0] weights2,
  output logic signed [         OUT_N*DATA_WIDTH-1:0] biases2,
  output logic                                        weights_ready
);

  // Calculate total memory needed for weights and biases
  localparam int WEIGHTS1_SIZE = HIDDEN_N * IN_N * DATA_WIDTH;
  localparam int BIASES1_SIZE = HIDDEN_N * DATA_WIDTH;
  localparam int WEIGHTS2_SIZE = OUT_N * HIDDEN_N * DATA_WIDTH;
  localparam int BIASES2_SIZE = OUT_N * DATA_WIDTH;

  // Memory addresses for weights and biases in flash (24-bit addresses)
  localparam logic [31:0] WEIGHTS1_ADDR_32 = 32'h000000;
  localparam logic [31:0] BIASES1_ADDR_32 = WEIGHTS1_ADDR_32 + ((WEIGHTS1_SIZE / 8) & 32'hFFFFFF);
  localparam logic [31:0] WEIGHTS2_ADDR_32 = BIASES1_ADDR_32 + ((BIASES1_SIZE / 8) & 32'hFFFFFF);
  localparam logic [31:0] BIASES2_ADDR_32 = WEIGHTS2_ADDR_32 + ((WEIGHTS2_SIZE / 8) & 32'hFFFFFF);

  // Convert to 24-bit addresses
  localparam logic [23:0] WEIGHTS1_ADDR = WEIGHTS1_ADDR_32[23:0];
  localparam logic [23:0] BIASES1_ADDR = BIASES1_ADDR_32[23:0];
  localparam logic [23:0] WEIGHTS2_ADDR = WEIGHTS2_ADDR_32[23:0];
  localparam logic [23:0] BIASES2_ADDR = BIASES2_ADDR_32[23:0];

  // SPI Memory Interface
  logic        spi_valid;
  logic        spi_ready;
  logic [23:0] spi_addr;
  logic [31:0] spi_rdata;

  // Configuration register
  logic [ 3:0] cfgreg_we;
  logic [31:0] cfgreg_di;
  logic [31:0] cfgreg_do;

  // State machine states
  typedef enum logic [3:0] {
    IDLE = 4'd0,
    LOAD_WEIGHTS1 = 4'd1,
    LOAD_BIASES1 = 4'd2,
    LOAD_WEIGHTS2 = 4'd3,
    LOAD_BIASES2 = 4'd4,
    DONE = 4'd5
  } state_t;

  state_t state, next_state;

  // Counter for tracking loaded data
  logic [31:0] load_counter;

  // Address calculation function
  function automatic [23:0] calc_addr;
    input [23:0] base_addr;
    input [31:0] offset;
    logic [31:0] temp;
    begin
      temp      = {8'h0, base_addr} + (offset & 32'hFFFFFF);
      calc_addr = temp[23:0];
    end
  endfunction

  // Instantiate SPIMemIO
  SPIMemIO spi_mem (
    .clk         (clk),
    .resetn      (rst_n),
    .valid       (spi_valid),
    .ready       (spi_ready),
    .addr        (spi_addr),
    .rdata       (spi_rdata),
    .flash_csb   (flash_csb),
    .flash_clk   (flash_clk),
    .flash_io0_oe(flash_io0_oe),
    .flash_io1_oe(flash_io1_oe),
    .flash_io2_oe(flash_io2_oe),
    .flash_io3_oe(flash_io3_oe),
    .flash_io0_do(flash_io0_do),
    .flash_io1_do(flash_io1_do),
    .flash_io2_do(flash_io2_do),
    .flash_io3_do(flash_io3_do),
    .flash_io0_di(flash_io0_di),
    .flash_io1_di(flash_io1_di),
    .flash_io2_di(flash_io2_di),
    .flash_io3_di(flash_io3_di),
    .cfgreg_we   (cfgreg_we),
    .cfgreg_di   (cfgreg_di),
    .cfgreg_do   (cfgreg_do)
  );

  // State machine
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state         <= IDLE;
      load_counter  <= 0;
      weights_ready <= 0;
    end else begin
      state <= next_state;

      case (state)
        IDLE: begin
          load_counter  <= 0;
          weights_ready <= 0;
        end

        LOAD_WEIGHTS1: begin
          if (spi_ready && spi_valid) begin
            weights1[load_counter*32+:32] <= spi_rdata;
            load_counter                  <= load_counter + 1;
          end
        end

        LOAD_BIASES1: begin
          if (spi_ready && spi_valid) begin
            biases1[load_counter*32+:32] <= spi_rdata;
            load_counter                 <= load_counter + 1;
          end
        end

        LOAD_WEIGHTS2: begin
          if (spi_ready && spi_valid) begin
            weights2[load_counter*32+:32] <= spi_rdata;
            load_counter                  <= load_counter + 1;
          end
        end

        LOAD_BIASES2: begin
          if (spi_ready && spi_valid) begin
            biases2[load_counter*32+:32] <= spi_rdata;
            load_counter                 <= load_counter + 1;
          end
        end

        DONE: begin
          weights_ready <= 1;
        end

        default: begin
          // Handle any undefined states
          state <= IDLE;
        end
      endcase
    end
  end

  // Next state logic
  always_comb begin
    next_state = state;
    spi_valid  = 0;
    spi_addr   = 0;

    case (state)
      IDLE: begin
        next_state = LOAD_WEIGHTS1;
      end

      LOAD_WEIGHTS1: begin
        spi_valid = 1;
        spi_addr  = calc_addr(WEIGHTS1_ADDR, load_counter * 4);
        if (load_counter >= (WEIGHTS1_SIZE / 32)) begin
          next_state = LOAD_BIASES1;
        end
      end

      LOAD_BIASES1: begin
        spi_valid = 1;
        spi_addr  = calc_addr(BIASES1_ADDR, load_counter * 4);
        if (load_counter >= (BIASES1_SIZE / 32)) begin
          next_state = LOAD_WEIGHTS2;
        end
      end

      LOAD_WEIGHTS2: begin
        spi_valid = 1;
        spi_addr  = calc_addr(WEIGHTS2_ADDR, load_counter * 4);
        if (load_counter >= (WEIGHTS2_SIZE / 32)) begin
          next_state = LOAD_BIASES2;
        end
      end

      LOAD_BIASES2: begin
        spi_valid = 1;
        spi_addr  = calc_addr(BIASES2_ADDR, load_counter * 4);
        if (load_counter >= (BIASES2_SIZE / 32)) begin
          next_state = DONE;
        end
      end

      DONE: begin
        // Stay in DONE state
      end

      default: begin
        next_state = IDLE;
      end
    endcase
  end

endmodule
