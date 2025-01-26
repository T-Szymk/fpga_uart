/*------------------------------------------------------------------------------
-- Title      : Testbench for FPGA UART Top for Arty A7
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : tb_fpga_uart_top_arty_a7.sv
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2025-01-26
-- Design     : tb_fpga_uart_top_arty_a7
-- Platform   : -
-- Standard   : SystemVerilog '17
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2025-01-26  1.0      TZS     Created
--------------------------------------------------------------------------------
*** DESCRIPTION ***
//! Testbench for running FPGA top module on Arty A7
/*----------------------------------------------------------------------------*/

module tb_fpga_uart_top_arty_a7;

  timeunit 1ns/1ps;

  /* CONSTANTS ****************************************************************/

  parameter integer  TOP_CLK_FREQ_HZ = 100_000_000;
  parameter time     CLOCK_PERIOD    = 1_000_000_000ns/TOP_CLK_FREQ_HZ;
  parameter realtime TEST_RUNTIME    = 100ms;

  /* SIGNALS ******************************************************************/

  bit tb_clk, tb_rst;

  bit uart_rx_s;
  bit uart_tx_s;

  bit led_s;

  /* ASSIGNMENTS **************************************************************/

  assign uart_rx_s = uart_tx_s;

  /* COMPONENTS ***************************************************************/

  fpga_uart_top_arty_a7 i_dut (
    .clk_100MHz_i ( tb_clk    ),
    .arstn_i      ( tb_rst    ),
    .uart_rx_i    ( uart_rx_s ),
    .uart_tx_o    ( uart_tx_s ),
    .rst_led_o    ( led_s     )
  );

  /* LOGIC ********************************************************************/

  /*** System Configuration ***/

  initial begin

  `ifndef VERILATOR
    $timeformat(-9, 0, " ns");
  `endif

  end

  /*** Clock and reset generation ***/

  initial begin
    tb_clk = 1'b0;
    forever begin
      #(CLOCK_PERIOD/2) tb_clk = ~tb_clk;
    end
  end

  initial begin
    tb_rst = 1'b0;
    repeat(5) begin
      @(negedge tb_clk);
    end
    tb_rst = 1'b1;
  end


  /*** testbench timeout ***/

  initial begin

    while ($realtime < TEST_RUNTIME) begin
      @(posedge tb_clk);
    end

    $display("[TB %0t] tb_fpga_uart_top_arty_a7 Test Timed Out", $time);

    $finish;
  end

endmodule
