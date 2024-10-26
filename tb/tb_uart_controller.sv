/*------------------------------------------------------------------------------
-- Title      : Testbench for FPGA UART Controller
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : tb_uart_controller.sv
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2024-08-25
-- Design     : tb_uart_controller
-- Platform   : -
-- Standard   : SystemVerilog '17
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2024-10-26  1.0      TZS     Created
------------------------------------------------------------------------------*/
/*** DESCRIPTION ***/
/*
Test cases covered:
- loopback test (rx/tx tied)
- asynchronous communication (tx and rx running at different frequencies with the same Baud Rate)
- tests at each baud rate
- each data/stop length value covered
- tx parity checking tested
- start/stop/parity error checks
- test over reset
- baudrate monitoring 
- partial transmission + recovery testing
*/
/*----------------------------------------------------------------------------*/

module tb_uart_controller;

  timeunit 1ns/1ps;

  import tb_uart_pkg::*;

  // constants and TB params
  parameter time             CLOCK_PERIOD     = 20ns;
  parameter realtime         TEST_RUNTIME     = 10ms;
  parameter integer unsigned TOP_CLK_FREQ_HZ  = 50_000_000;
  parameter integer unsigned MAX_UART_DATA_W  = 8;
  parameter integer unsigned STOP_CONF_W      = 2;
  parameter integer unsigned DATA_CONF_W      = 2;
  parameter integer unsigned SAMPLE_COUNT_W   = 4;
  parameter integer unsigned N_BAUD_RATE_VALS = 4;
  parameter integer unsigned BAUD_RATE_SEL_W  = 2;
  parameter integer unsigned TOTAL_CONF_W     = STOP_CONF_W + DATA_CONF_W + 1;

  // TB UART Configuration
  localparam int unsigned UARTDataBits = 8;
  localparam int unsigned UARTStopBits = 1;
  localparam int unsigned UARTParityEn = 0;
  localparam baud_rate_e  BaudRate     = BAUD9600;

  // signals
  bit tb_clk, tb_rst;

  bit [BAUD_RATE_SEL_W-1:0] baud_sel_s;
  bit                       tx_en_s;
  bit                       tx_start_s;
  bit [   TOTAL_CONF_W-1:0] tx_conf_s;
  bit [MAX_UART_DATA_W-1:0] tx_data_s;
  bit                       tx_fifo_en_s;
  bit                       rx_en_s;
  bit                       uart_rx_s;
  bit [   TOTAL_CONF_W-1:0] rx_conf_s;
  bit                       rx_fifo_en_s;
  bit                       tx_done_s;
  bit                       tx_busy_s;
  bit                       uart_tx_s;
  bit                       tx_fifo_pop_s;
  bit                       rx_done_s;
  bit                       rx_parity_err_s;
  bit                       rx_stop_err_s;
  bit                       rx_busy_s;
  bit [MAX_UART_DATA_W-1:0] rx_data_s;
  bit                       rx_fifo_push_s;
  bit                       rx_fifo_full_s;

  // FIFO to contain test data
  mailbox #(bit [UARTDataBits-1:0]) data_queue = new();

  // continuous assignments

  assign uart_rx_s = uart_tx_s; // loopback

  // clock generation
  initial begin
    tb_clk = 1'b0;
    forever begin
      #(CLOCK_PERIOD/2) tb_clk = ~tb_clk;
    end
  end

  // reset logic
  initial begin
    tb_rst = 1'b1;
    repeat(5) begin
      @(negedge tb_clk);
    end
    tb_rst = 1'b0;
  end

  initial begin

    $dumpfile("tb_uart_controller.vcd");
    $dumpvars;

  `ifndef VERILATOR
    $timeformat(-9, 0, " ns");
  `endif

  end

  // dut instance
  uart_controller #(
    .TOP_CLK_FREQ_HZ  ( TOP_CLK_FREQ_HZ  ),
    .MAX_UART_DATA_W  ( MAX_UART_DATA_W  ),
    .STOP_CONF_W      ( STOP_CONF_W      ),
    .DATA_CONF_W      ( DATA_CONF_W      ),
    .SAMPLE_COUNT_W   ( SAMPLE_COUNT_W   ),
    .N_BAUD_RATE_VALS ( N_BAUD_RATE_VALS ),
    .BAUD_RATE_SEL_W  ( BAUD_RATE_SEL_W  ),
    .TOTAL_CONF_W     ( TOTAL_CONF_W     )
  ) i_dut (
    .clk_i            ( tb_clk          ),
    .rst_i            ( tb_rst          ),
    .baud_sel_i       ( baud_sel_s      ),
    .tx_en_i          ( tx_en_s         ),
    .tx_start_i       ( tx_start_s      ),
    .tx_conf_i        ( tx_conf_s       ),
    .tx_data_i        ( tx_data_s       ),
    .tx_fifo_en_i     ( tx_fifo_en_s    ),
    .rx_en_i          ( rx_en_s         ),
    .uart_rx_i        ( uart_rx_s       ),
    .rx_conf_i        ( rx_conf_s       ),
    .rx_fifo_en_i     ( rx_fifo_en_s    ),
    .rx_fifo_full_i   ( rx_fifo_full_s  ),
    .tx_done_o        ( tx_done_s       ),
    .tx_busy_o        ( tx_busy_s       ),
    .uart_tx_o        ( uart_tx_s       ),
    .tx_fifo_pop_o    ( tx_fifo_pop_s   ),
    .rx_done_o        ( rx_done_s       ),
    .rx_parity_err_o  ( rx_parity_err_s ),
    .rx_stop_err_o    ( rx_stop_err_s   ),
    .rx_busy_o        ( rx_busy_s       ),
    .rx_data_o        ( rx_data_s       ),
    .rx_fifo_push_o   ( rx_fifo_push_s  )
  );

  // TB logic
  initial begin

    automatic bit [UARTDataBits-1:0] test_data_tx_s, test_data_rx_s;
    automatic bit success;

    baud_sel_s     = get_baud_bits(BaudRate);
    tx_en_s        = '0;
    tx_start_s     = '0;
    tx_conf_s      = get_uart_config(UARTDataBits, UARTStopBits, UARTParityEn);
    tx_data_s      = '0;
    tx_fifo_en_s   = 1'b1;
    rx_en_s        = '0;
    rx_conf_s      = get_uart_config(UARTDataBits, UARTStopBits, UARTParityEn);
    rx_fifo_en_s   = 1'b1;
    rx_fifo_full_s = 1'b0;

    $display("[TB %0t] UART CONFIG:", $time);
    $display("\tUART DATA BITS: %0d", $time, UARTDataBits);
    $display("\tUART STOP BITS: %0d", $time, UARTStopBits);
    $display("\tUART PARITY EN: %0d", $time, UARTParityEn);

    while (tb_rst) begin
      @(posedge tb_clk);
    end

    $display("[TB %0t] reset de-asserted", $time);

    @(posedge tb_clk);
    @(posedge tb_clk);
    @(negedge tb_clk);

    tx_en_s = 1'b1;
    rx_en_s = 1'b1;

    $display("[TB %0t] tx and rx modules enabled", $time);

    @(negedge tb_clk);
    @(negedge tb_clk);
    @(negedge tb_clk);

    fork

      begin

        forever begin

          // generate random data value and push it into queue
          success = std::randomize(test_data_tx_s);
          data_queue.put(test_data_tx_s);
          tx_data_s = test_data_tx_s;

          // send data
          tx_start_s = 1'b1;

          while (~tx_done_s) begin
            @(negedge tb_clk);
          end

          tx_start_s = 1'b0;

          @(negedge tb_clk);

        end
      end

      begin

        forever begin

          // wait for data
          while (~rx_done_s) begin
            @(negedge tb_clk);
          end

          // check data against expected value
          data_queue.get(test_data_rx_s);
          a_result_checker : assert (test_data_rx_s == rx_data_s) else begin
            $error("[TB %0t] Result Checker Failed!", $time);
            $display("\tUART RX: RX DATA  : 0x%0H", rx_data_s);
            $display("\tUART RX: Expected : 0x%0H", test_data_rx_s);
          end

          @(negedge tb_clk);

        end
      end

    join

    $display("[TB %0t] Test logic complete", $time);
    $finish;

  end

  // testbench timeout
  initial begin

    while ($realtime < TEST_RUNTIME) begin
      @(posedge tb_clk);
    end

    $display("[TB %0t] tb_uart_controller Test Timed Out", $time);

    $finish;
  end


endmodule // tb_uart_controller
