/*------------------------------------------------------------------------------
-- Title      : FPGA UART Top for Arty A7
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : fpga_uart_top_arty_a7.v
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2025-01-26
-- Design     : fpga_uart_top_arty_a7
-- Platform   : -
-- Standard   : Verilog '05
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2025-01-26  1.0      TZS     Created
------------------------------------------------------------------------------*/
/*** DESCRIPTION ***/
//! Top module for FPGA UART testing on Digilent Arty A7 development board
//! Part: AMD XC7A100TCSG324-1
/*----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module fpga_uart_top_arty_a7 (
  input  wire clk_100MHz_i,
  input  wire arstn_i,
  // UART signals
  input  wire uart_rx_i,
  output wire uart_tx_o,
  // Reset LED out
  output wire rst_led_o
);

  /* CONSTANTS ****************************************************************/

  parameter TOP_CLK_FREQ_HZ = 50_000_000;

  localparam integer CPU_ADDR_WIDTH =  2;
  localparam integer CPU_DATA_WIDTH = 32;

  /* SIGNALS ******************************************************************/

    wire rst_s;
    wire uart_clk_s;
    wire pll_locked_s;

    wire                       wr_en_cpu_s;
    wire                       rd_en_cpu_s;
    wire [ CPU_ADDR_WIDTH-1:0] cpu_addr_s;
    wire [ CPU_DATA_WIDTH-1:0] cpu_wr_data_s;
    wire [ CPU_DATA_WIDTH-1:0] cpu_rd_data_s;

  /* COMPONENTS ***************************************************************/

  clk_wiz_0 i_uart_pll (
    .clk_100MHz_i ( clk_100MHz_i ),
    .uart_clk_o   ( uart_clk_s   ),
    .resetn       ( arstn_i      ),
    .locked       ( pll_locked_s )
  );

  reset_sync #(
    .SYNC_REG_COUNT (3)
  ) i_reset_sync (
    .dst_clk_i ( uart_clk_s   ),
    .arstn_i   ( pll_locked_s ), // take from MMCM Locked
    .rst_o     ( rst_s        )
  );

  uart_top #(
    .TOP_CLK_FREQ_HZ ( TOP_CLK_FREQ_HZ )
  ) i_fpga_uart (
    .clk_i       ( uart_clk_s    ),
    .rst_i       ( rst_s         ),
    .uart_rx_i   ( uart_rx_i     ),
    .uart_tx_o   ( uart_tx_o     ),
    .wr_en_cpu_i ( wr_en_cpu_s   ),
    .rd_en_cpu_i ( rd_en_cpu_s   ),
    .cpu_addr_i  ( cpu_addr_s    ),
    .cpu_data_i  ( cpu_wr_data_s ),
    .cpu_data_o  ( cpu_rd_data_s )
  );

  uart_test_module #(
    .TOP_CLK_FREQ_HZ ( TOP_CLK_FREQ_HZ )
  ) i_uart_test_module (
    .clk_i         ( uart_clk_s    ),
    .rst_i         ( rst_s         ),
    .wr_en_cpu_o   ( wr_en_cpu_s   ),
    .rd_en_cpu_o   ( rd_en_cpu_s   ),
    .cpu_addr_o    ( cpu_addr_s    ),
    .cpu_wr_data_o ( cpu_wr_data_s ),
    .cpu_rd_data_i ( cpu_rd_data_s )
  );

  /* ASSIGNMENTS **************************************************************/

  assign rst_led_o = arstn_i;

endmodule
