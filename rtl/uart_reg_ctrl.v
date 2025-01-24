/*------------------------------------------------------------------------------
-- Title      : FPGA UART Register Controller
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : uart_reg_ctrl.v
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2024-10-28
-- Design     : uart_reg_ctrl
-- Platform   : -
-- Standard   : Verilog '05
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2024-10-28  1.0      TZS     Created
------------------------------------------------------------------------------*/
/***  DESCRIPTION ***/
//! Module containing control logic to manage signals interfacing with UART
//! control registers.
/*----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module uart_reg_ctrl #(
  parameter MAX_UART_DATA_W  = 8,                            //! Maximum width of UART data 
  parameter STOP_CONF_W      = 2,                            //! Width of stop bit configuration field
  parameter DATA_CONF_W      = 2,                            //! Width of data bit configuration field
  parameter BAUD_RATE_SEL_W  = 2,                            //! Width of Baud rate select signal = $clog2(N_BAUD_RATE_VALS)
  parameter TOTAL_CONF_W     = STOP_CONF_W + DATA_CONF_W + 1 //! Total width of configuration data bits sent to Tx and Rx modules
) (
  input  wire                       clk_i,                  //! Top clock
  input  wire                       rst_i,                  //! Synchronous active-high reset

  input  wire                       tx_done_i,              //! Tx done status signal (pulsed when Tx of one character completed)   
  input  wire                       tx_busy_i,              //! Tx status signal to indicate Tx module is busy sending something    

  input  wire                       rx_done_i,              //! Rx done status signal (pulsed when Rx of one character completed)                    
  input  wire                       rx_parity_err_i,        //! Rx status signal indicating that a parity error was recognised in latest received data                    
  input  wire                       rx_stop_err_i,          //! Rx status signal indicating that a stop error was recognised in latest received data                    
  input  wire                       rx_busy_i,              //! Rx status signal to indicate Rx module is busy receiving something                      
  input  wire [MAX_UART_DATA_W-1:0] rx_data_i,              //! Rx data that has been received

  input  wire                       rx_fifo_full_i,         //! Full indication from Rx FIFO
  input  wire                       rx_fifo_nearly_full_i,  //! Nearly full indication from Rx FIFO
  input  wire                       rx_fifo_empty_i,        //! Empty indication from Rx FIFO
  input  wire                       rx_fifo_nearly_empty_i, //! Nearly empty indication from Rx FIFO

  input  wire                       tx_fifo_full_i,         //! Full indication from Tx FIFO
  input  wire                       tx_fifo_nearly_full_i,  //! Nearly full indication from Tx FIFO
  input  wire                       tx_fifo_empty_i,        //! Empty indication from Tx FIFO
  input  wire                       tx_fifo_nearly_empty_i, //! Nearly empty indication from Tx FIFO

  output wire                       tx_fifo_push_o,         //! Push control for Tx FIFO
  output wire                       rx_fifo_pop_o,          //! Pop control for Rx FIFO

  output wire [BAUD_RATE_SEL_W-1:0] baud_sel_o,             //! Baud rate select signal
  output wire                       tx_en_o,                //! Enable for Tx module
  output wire                       tx_start_o,             //! Start signal to initiate transmission of data     
  output wire [   TOTAL_CONF_W-1:0] tx_conf_o,              //! Tx configuration data conf {data[1:0], stop[1:0], parity_en}       
  output wire [MAX_UART_DATA_W-1:0] tx_data_o,              //! Tx data to be transmitted
  output wire                       tx_fifo_en_o,           //! Enable for the Tx FIFO
  output wire                       rx_en_o,                //! Enable for Rx module
  output wire [   TOTAL_CONF_W-1:0] rx_conf_o,              //! Rx configuration data conf {data[1:0], stop[1:0], parity_en} 
  output wire                       rx_fifo_en_o            //! Enable for the Rx FIFO
);

  // constants
  localparam integer RegBusAddrWidth =  2;
  localparam integer RegBusDataWidth = 32;
  localparam integer RegWidth        = 32;
  localparam integer RegCount        =  4;

  // UART Register Component
  uart_registers #(
    .ADDR_WIDTH ( RegBusAddrWidth ),
    .DATA_WIDTH ( RegBusDataWidth ),
    .REG_WIDTH  ( RegWidth        ),
    .REG_COUNT  ( RegCount        )
  ) i_uart_registers (
    .clk_i          ( clk_i                              ),
    .rst_i          ( rst_i                              ),
    .cpu_addr_i     ( {RegBusAddrWidth{1'b0}}            ),
    .cpu_data_i     ( {RegBusDataWidth{1'b0}}            ),
    .periph_data_i  ( {(RegCount*RegBusDataWidth){1'b0}} ),
    .wr_en_periph_i ( {RegCount{1'b0}}                   ),
    .wr_en_cpu_i    ( 1'b0                               ),
    .rd_en_cpu_i    ( 1'b0                               ),
    .cpu_data_o     ( /*NOT CONNECTED*/                  ),
    .periph_data_o  ( /*NOT CONNECTED*/                  )
  );

endmodule
