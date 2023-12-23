/*------------------------------------------------------------------------------
-- Title      : Testbench for FPGA UART Transmit Module
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : tb_tx_module.sv
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2023-06-14
-- Design     : tb_tx_module
-- Platform   : -
-- Standard   : SystemVerilog '17
--------------------------------------------------------------------------------
-- Description: Testbench to test standalone tx_module
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2023-06-14  1.0      TZS     Created
------------------------------------------------------------------------------*/

module tb_tx_module #(
  parameter time     CLOCK_PERIOD         = 20ns,
  parameter unsigned MAX_DATA_WIDTH       = 8,
  parameter unsigned DATA_COUNTER_WIDTH   = 3,
  parameter unsigned STOP_CONF_WIDTH      = 2,
  parameter unsigned DATA_CONF_WIDTH      = 2,
  parameter unsigned SAMPLE_COUNTER_WIDTH = 4
);

  timeunit 1ns/1ps;

  localparam unsigned TotalConfWidth = STOP_CONF_WIDTH + DATA_CONF_WIDTH + 1;

  bit clk, rst;

  bit                      dut_baud_en_i;
  bit                      dut_tx_en_i;
  bit                      dut_tx_start_i;
  bit [TotalConfWidth-1:0] dut_tx_conf_i;
  bit [MAX_DATA_WIDTH-1:0] dut_tx_data_i;
  bit                      dut_tx_done_o;
  bit                      dut_busy_o;
  bit                      dut_uart_tx_o;

  // clock generation
  initial begin
    clk = 1'b0;
    forever begin
      #(CLOCK_PERIOD/2) clk = ~clk;
    end
  end

  // dut instance
  tx_module #(
    .MAX_UART_DATA_W ( MAX_DATA_WIDTH       ),
    .DATA_COUNTER_W  ( DATA_COUNTER_WIDTH   ),
    .STOP_CONF_W     ( STOP_CONF_WIDTH      ),
    .DATA_CONF_W     ( DATA_CONF_WIDTH      ),
    .SAMPLE_COUNT_W  ( SAMPLE_COUNTER_WIDTH )
  ) i_dut (
    .clk_i      ( clk            ),
    .rst_i      ( rst            ),
    .baud_en_i  ( dut_baud_en_i  ),
    .tx_en_i    ( dut_tx_en_i    ),
    .tx_start_i ( dut_tx_start_i ),
    .tx_conf_i  ( dut_tx_conf_i  ),
    .tx_data_i  ( dut_tx_data_i  ),
    .tx_done_o  ( dut_tx_done_o  ),
    .tx_busy_o  ( dut_busy_o     ),
    .uart_tx_o  ( dut_uart_tx_o  )
  );

  initial begin

    $dumpfile("tb_tx_module.vcd");
    $dumpvars;

  end

  initial begin

    $dumpfile("tb_tx_module.vcd");
    $dumpvars;

    // initialise dut values
    rst            = 1'b1;
    dut_baud_en_i  =  '0;
    dut_tx_en_i    =  '0;
    dut_tx_start_i =  '0;
    dut_tx_conf_i  = 5'b11000; // 8b data, 1b stop and N parity
    dut_tx_data_i  = 8'hAA;

    #(5*CLOCK_PERIOD);
    @(negedge clk);

    rst = 1'b0;
    $display("[%0t ps] - Reset Lifted", $time);

    @(negedge clk);

    dut_baud_en_i = 1'b1;
    $display("[%0t ps] - Baud clock enabled",$time);

    @(negedge clk);

    dut_tx_en_i = 1'b1;
    $display("[%0t ps] - tx_en set", $time);

    @(negedge clk);

    dut_tx_start_i = 1'b1;

    @(negedge clk);

    dut_tx_start_i = 1'b0;

    @(posedge dut_tx_done_o);
    $display("[%0t ps] - tx_done received", $time);

    @(posedge clk);
    @(posedge clk);
    @(posedge clk);

    $display("[%0t ps] - Simulation Complete!", $time);

    $finish;

  end

endmodule // tb_tx_module
