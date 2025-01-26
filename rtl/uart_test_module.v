/*------------------------------------------------------------------------------
-- Title      : FPGA UART Test Module
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : uart_test_module.v
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2025-01-25
-- Design     : uart_test_module
-- Platform   : -
-- Standard   : Verilog '05
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2025-01-25  1.0      TZS     Created
------------------------------------------------------------------------------*/
/***  DESCRIPTION ***/
//! Synthesisable test module to drive a test pattern out of FPGA UART.
/*----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module uart_test_module #(
  parameter          TOP_CLK_FREQ_HZ  = 50_000_000, //! Frequency of input clock in Hz
  localparam integer CPU_ADDR_WIDTH   =          2, //! Output data to CPU
  localparam integer CPU_DATA_WIDTH   =         32  //! Output data from registers to peripherals
) (
  input  wire                       clk_i,       //! Top clock
  input  wire                       rst_i,       //! Synchronous active-high reset

  output wire                       wr_en_cpu_o,   //! Write enable signal from CPU bus
  output wire                       rd_en_cpu_o,   //! Read enable signal from CPU bus
  output wire [ CPU_ADDR_WIDTH-1:0] cpu_addr_o,    //! Address from CPU bus
  output wire [ CPU_DATA_WIDTH-1:0] cpu_wr_data_o, //! Write data FROM CPU bus
  input  wire [ CPU_DATA_WIDTH-1:0] cpu_rd_data_i  //! Read data TO CPU bus
);

/*** Constants ****************************************************************/

localparam reg [4-1:0] 
  RESET            = 4'b0000,
  READ_CFG_A0      = 4'b0001,
  WRITE_CFG_A0     = 4'b0010,
  WRITE_TX_DATA_B0 = 4'b0011,
  READ_CFG_B0      = 4'b0100,
  WRITE_CFG_B0     = 4'b0101,
  READ_STATUS_B0   = 4'b0110,
  READ_STATUS_B1   = 4'b0111,
  DELAY_0          = 4'b1000,
  DELAY_1          = 4'b1001,
  DELAY_2          = 4'b1010;

  localparam [CPU_ADDR_WIDTH-1:0] UART_STAT_ADDR = 0;
  localparam [CPU_ADDR_WIDTH-1:0] UART_CTRL_ADDR = 1;
  localparam [CPU_ADDR_WIDTH-1:0] UART_TX_ADDR   = 2;
  localparam [CPU_ADDR_WIDTH-1:0] UART_RX_ADDR   = 3;

/*** Signals ******************************************************************/

  reg                        wr_en_cpu_s;
  reg                        rd_en_cpu_s;
  reg  [ CPU_ADDR_WIDTH-1:0] cpu_addr_s;
  reg  [ CPU_DATA_WIDTH-1:0] cpu_wr_data_s;
  wire [ CPU_DATA_WIDTH-1:0] cpu_rd_data_s;

  reg [4-1:0] c_state_r, n_state_s;

  reg [CPU_DATA_WIDTH-1:0] data_arr_r [12-1:0];

  reg [4-1:0] arr_idx_r;
  reg         incr_s;

/*** Logic ********************************************************************/

  initial begin
    data_arr_r[ 0] = "B";
    data_arr_r[ 1] = "e";
    data_arr_r[ 2] = "c";
    data_arr_r[ 3] = "c";
    data_arr_r[ 4] = "a";
    data_arr_r[ 5] = ".";
    data_arr_r[ 6] = "<";
    data_arr_r[ 7] = "3";
    data_arr_r[ 8] = ".";
    data_arr_r[ 9] = "T";
    data_arr_r[10] = "o";
    data_arr_r[11] = "m";
  end

  // FSM sync c_state
  always @(posedge clk_i) begin
    if(rst_i) begin
      c_state_r <= RESET;
    end else begin
      c_state_r <= n_state_s;
    end
  end

  // FSM n_state and output
  always @(*) begin

    // default assignments
    n_state_s     = c_state_r;
    incr_s        = 1'b0;
    wr_en_cpu_s   = 1'b0;
    rd_en_cpu_s   = 1'b0;
    cpu_addr_s    = {CPU_ADDR_WIDTH{1'b0}};
    cpu_wr_data_s = {CPU_DATA_WIDTH{1'b0}};

    case (c_state_r)

      RESET : begin

        n_state_s = READ_CFG_A0;

      end

      READ_CFG_A0 : begin

        // read ctrl register
        rd_en_cpu_s = 1'b1;
        cpu_addr_s  = UART_CTRL_ADDR;

        n_state_s   = WRITE_CFG_A0;

      end

      WRITE_CFG_A0 : begin

        // write initial config and enable tx/rx
        wr_en_cpu_s          = 1'b1;
        cpu_addr_s           = UART_CTRL_ADDR;

        cpu_wr_data_s        = cpu_rd_data_s;
        cpu_wr_data_s[ 0]    = 1'b1;  // tx_en
        cpu_wr_data_s[ 6: 5] = 2'b11; // tx_data width = 8b
        cpu_wr_data_s[16]    = 1'b1;  // rx_en
        cpu_wr_data_s[22:21] = 2'b11; // rx_data width = 8b

        n_state_s   = WRITE_TX_DATA_B0;

      end

      WRITE_TX_DATA_B0 : begin

        // write tx data
        wr_en_cpu_s   = 1'b1;
        cpu_addr_s    = UART_TX_ADDR;
        cpu_wr_data_s = data_arr_r[arr_idx_r];

        n_state_s     = READ_CFG_B0;

      end

      READ_CFG_B0 : begin

        // read cfg before writing back
        rd_en_cpu_s = 1'b1;
        cpu_addr_s  = UART_CTRL_ADDR;

        n_state_s   = WRITE_CFG_B0;

      end

      WRITE_CFG_B0 : begin

        // write tx_start
        wr_en_cpu_s      = 1'b1;
        cpu_addr_s       = UART_CTRL_ADDR;

        cpu_wr_data_s    = cpu_rd_data_s;
        cpu_wr_data_s[1] = 1'b1;

        n_state_s   = DELAY_0;

      end

      DELAY_0 : begin
        n_state_s = DELAY_1;
      end

      DELAY_1 : begin
        n_state_s = DELAY_2;
      end

      DELAY_2 : begin
        n_state_s = READ_STATUS_B0;
      end

      READ_STATUS_B0 : begin

        // read status register to check busy flag
        rd_en_cpu_s = 1'b1;
        cpu_addr_s  = UART_STAT_ADDR;

        n_state_s   = READ_STATUS_B1;

      end

      READ_STATUS_B1 : begin

        if (~cpu_rd_data_s[1]) begin
          n_state_s = WRITE_TX_DATA_B0; // write new data
          incr_s    = 1'b1;
        end else begin
          n_state_s = READ_STATUS_B0;
        end

      end

      default : begin

        n_state_s   = RESET;

      end
    endcase

  end

  always @(posedge clk_i) begin : counter

    if (rst_i) begin
      arr_idx_r <= {4{1'b0}};
    end else begin

      if (incr_s) begin
        if (arr_idx_r == 4'd11) begin
          arr_idx_r <= 4'd0;
        end else begin
          arr_idx_r <= arr_idx_r + 1;
        end
      end


    end

  end

/*** Assignments **************************************************************/

  assign wr_en_cpu_o    = wr_en_cpu_s;
  assign rd_en_cpu_o    = rd_en_cpu_s;
  assign cpu_addr_o     = cpu_addr_s;
  assign cpu_wr_data_o  = cpu_wr_data_s;
  assign cpu_rd_data_s  = cpu_rd_data_i;

endmodule
