/*------------------------------------------------------------------------------
-- Title      : FPGA UART Controller
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : uart_controller.v
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2023-07-02
-- Design     : uart_controller
-- Platform   : -
-- Standard   : Verilog '05
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2023-07-15  1.0      TZS     Created
-- 2024-08-24  1.1      TZS     Added Tx FIFO interface
-- 2024-10-24  1.2      TZS     Removeed redundant params from Baud Gen inst
-- 2024-10-26  1.3      TZS     Add Rx FIFO interface
------------------------------------------------------------------------------*/
/*** DESCRIPTION ****/
//! UART controller containing Tx/Rx controllers and Baud Generator.
//! Includes synchroniser for uart_rx_i signal.
/*----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module uart_controller #(
  parameter TOP_CLK_FREQ_HZ  = 50_000_000,                   //! Frequency of input clock in Hz
  parameter MAX_UART_DATA_W  = 8,                            //! Maximum width of UART data 
  parameter STOP_CONF_W      = 2,                            //! Width of stop bit configuration field
  parameter DATA_CONF_W      = 2,                            //! Width of data bit configuration field
  parameter SAMPLE_COUNT_W   = 4,                            //! Width of sample counter within Tx and Rx module (sampled 16 times) = $clog2(16)
  parameter N_BAUD_RATE_VALS = 4,                            //! Number of Baud rate values
  parameter BAUD_RATE_SEL_W  = 2,                            //! Width of Baud rate select signal = $clog2(N_BAUD_RATE_VALS)
  parameter TOTAL_CONF_W     = STOP_CONF_W + DATA_CONF_W + 1 //! Total width of configuration data bits sent to Tx and Rx modules
)(
  input  wire                       clk_i,           //! Top clock
  input  wire                       rst_i,           //! Synchronous active-high reset
  input  wire [BAUD_RATE_SEL_W-1:0] baud_sel_i,      //! Baud rate select signal

  input  wire                       tx_en_i,         //! Enable for Tx module
  input  wire                       tx_start_i,      //! Start signal to initiate transmission of data     
  input  wire [   TOTAL_CONF_W-1:0] tx_conf_i,       //! Tx configuration data conf {data[1:0], stop[1:0], parity_en}       
  input  wire [MAX_UART_DATA_W-1:0] tx_data_i,       //! Tx data to be transmitted
  input  wire                       tx_fifo_en_i,    //! Enable for the Tx FIFO
  input  wire                       rx_en_i,         //! Enable for Rx module
  input  wire                       uart_rx_i,       //! External Rx input of UART
  input  wire [   TOTAL_CONF_W-1:0] rx_conf_i,       //! Rx configuration data conf {data[1:0], stop[1:0], parity_en} 
  input  wire                       rx_fifo_en_i,    //! Enable for the Rx FIFO
  input  wire                       rx_fifo_full_i,  //! Full indication from Rx FIFO

  output wire                       tx_done_o,       //! Tx done status signal (pulsed when Tx of one character completed)   
  output wire                       tx_busy_o,       //! Tx status signal to indicate Tx module is busy sending something    
  output wire                       uart_tx_o,       //! External Tx output of UART
  output wire                       tx_fifo_pop_o,   //! Pop control for Tx FIFO

  output wire                       rx_done_o,       //! Rx done status signal (pulsed when Rx of one character completed)                    
  output wire                       rx_parity_err_o, //! Rx status signal indicating that a parity error was recognised in latest received data                    
  output wire                       rx_stop_err_o,   //! Rx status signal indicating that a stop error was recognised in latest received data                    
  output wire                       rx_busy_o,       //! Rx status signal to indicate Rx module is busy receiving something                      
  output wire [MAX_UART_DATA_W-1:0] rx_data_o,       //! Rx data that has been received
  output wire                       rx_fifo_push_o   //! Push control for Rx FIFO
);

  /*** CONSTANTS **************************************************************/
  localparam MIN_SAMPLE_FREQ_9600_BAUD_HZ   =  153600; //! Minimum possible frequency to be able to sample a 9600 Baud signal 16x per symbol 
  localparam MIN_SAMPLE_FREQ_19200_BAUD_HZ  =  307200; //! Minimum possible frequency to be able to sample a 19200 Baud signal 16x per symbol
  localparam MIN_SAMPLE_FREQ_115200_BAUD_HZ = 1843200; //! Minimum possible frequency to be able to sample a 115200 Baud signal 16x per symbol
  localparam MIN_SAMPLE_FREQ_256000_BAUD_HZ = 4086000; //! Minimum possible frequency to be able to sample a 256000 Baud signal 16x per symbol

  localparam SAMPLE_COUNT_9600_BAUD   = ( TOP_CLK_FREQ_HZ / MIN_SAMPLE_FREQ_9600_BAUD_HZ );   //! Max value of sample counter to allow sampling of each symbol 16x @ 9600 Baud
  localparam SAMPLE_COUNT_19200_BAUD  = ( TOP_CLK_FREQ_HZ / MIN_SAMPLE_FREQ_19200_BAUD_HZ );  //! Max value of sample counter to allow sampling of each symbol 16x @ 19200 Baud 
  localparam SAMPLE_COUNT_115200_BAUD = ( TOP_CLK_FREQ_HZ / MIN_SAMPLE_FREQ_115200_BAUD_HZ ); //! Max value of sample counter to allow sampling of each symbol 16x @ 115200 Baud  
  localparam SAMPLE_COUNT_256000_BAUD = ( TOP_CLK_FREQ_HZ / MIN_SAMPLE_FREQ_256000_BAUD_HZ ); //! Max value of sample counter to allow sampling of each symbol 16x @ 256000 Baud  

  localparam DataCounterWidth = $clog2(MAX_UART_DATA_W); //! Width of counter used to counter the maximum number of data bits (MAX_UART_DATA_W)

  /*** SIGNALS ****************************************************************/

  wire baud_en_s;

  reg uart_rx_sync0_r; //! Synchroniser register 0 for incoming Rx signal 
  reg uart_rx_sync1_r; //! Synchroniser register 1 for incoming Rx signal 
  reg uart_rx_sync2_r; //! Synchroniser register 2 for incoming Rx signal 

  /*** INSTANTIATIONS *********************************************************/

  baud_generator #(
    .SAMPLE_COUNT_9600_BAUD   ( SAMPLE_COUNT_9600_BAUD   ),
    .SAMPLE_COUNT_19200_BAUD  ( SAMPLE_COUNT_19200_BAUD  ),
    .SAMPLE_COUNT_115200_BAUD ( SAMPLE_COUNT_115200_BAUD ),
    .SAMPLE_COUNT_256000_BAUD ( SAMPLE_COUNT_256000_BAUD )
  ) i_baud_generator (
    .clk_i      ( clk_i      ),
    .rst_i      ( rst_i      ),
    .baud_sel_i ( baud_sel_i ),
    .baud_en_o  ( baud_en_s  )
  );

  tx_module #(
    .MAX_UART_DATA_W ( MAX_UART_DATA_W  ),
    .STOP_CONF_W     ( STOP_CONF_W      ),
    .DATA_CONF_W     ( DATA_CONF_W      ),
    .SAMPLE_COUNT_W  ( SAMPLE_COUNT_W   ),
    .TOTAL_CONF_W    ( TOTAL_CONF_W     ),
    .DATA_COUNTER_W  ( DataCounterWidth )
  ) i_tx_module (
    .clk_i         ( clk_i         ),
    .rst_i         ( rst_i         ),
    .baud_en_i     ( baud_en_s     ),
    .tx_en_i       ( tx_en_i       ),
    .tx_start_i    ( tx_start_i    ),
    .tx_conf_i     ( tx_conf_i     ),
    .tx_data_i     ( tx_data_i     ),
    .tx_fifo_en_i  ( tx_fifo_en_i  ),
    .tx_done_o     ( tx_done_o     ),
    .tx_busy_o     ( tx_busy_o     ),
    .uart_tx_o     ( uart_tx_o     ),
    .tx_fifo_pop_o ( tx_fifo_pop_o )
  );

  rx_module #(
    .MAX_UART_DATA_W ( MAX_UART_DATA_W  ),
    .STOP_CONF_W     ( STOP_CONF_W      ),
    .DATA_CONF_W     ( DATA_CONF_W      ),
    .SAMPLE_COUNT_W  ( SAMPLE_COUNT_W   ),
    .TOTAL_CONF_W    ( TOTAL_CONF_W     ),
    .DATA_COUNTER_W  ( DataCounterWidth )
  ) i_rx_module (
    .clk_i           ( clk_i           ),
    .rst_i           ( rst_i           ),
    .baud_en_i       ( baud_en_s       ),
    .rx_en_i         ( rx_en_i         ),
    .uart_rx_i       ( uart_rx_sync2_r ),
    .rx_conf_i       ( rx_conf_i       ),
    .rx_fifo_en_i    ( rx_fifo_en_i    ),
    .rx_fifo_full_i  ( rx_fifo_full_i  ),
    .rx_done_o       ( rx_done_o       ),
    .rx_busy_o       ( rx_busy_o       ),
    .rx_parity_err_o ( rx_parity_err_o ),
    .rx_stop_err_o   ( rx_stop_err_o   ),
    .rx_data_o       ( rx_data_o       ),
    .rx_fifo_push_o  ( rx_fifo_push_o  )
  );

  /* RTL **********************************************************************/

  //! 3FF synchroniser for uart_rx_i
  always @(posedge clk_i) begin : uart_rx_sync
    if (rst_i) begin
      uart_rx_sync0_r <= 1'b0;
      uart_rx_sync1_r <= 1'b0;
      uart_rx_sync2_r <= 1'b0;
    end else begin
      uart_rx_sync0_r <= uart_rx_i;
      uart_rx_sync1_r <= uart_rx_sync0_r;
      uart_rx_sync2_r <= uart_rx_sync1_r;
    end
  end // uart_rx_sync

endmodule // uart_controller
