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
-- 2023-07-02  1.0      TZS     Created
------------------------------------------------------------------------------*/
/*** DESCRIPTION ****/
//! Top module for UART controller.
/*----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module uart_controller #(
  //! Frequency of input clock in Hz
  parameter unsigned TOP_CLK_FREQ_HZ  = 50000000,
  //! Maximum width of UART data 
  parameter unsigned MAX_UART_DATA_W  = 8,
  //! Number of Baud rate values
  parameter unsigned N_BAUD_RATE_VALS = 4,
  //! Width of Baud rate select signal
  localparam integer BAUD_RATE_SEL_W  = $clog2(N_BAUD_RATE_VALS)
)(
  //! Top clock
  input wire                       clk_i,
  //! Synchronous active-high reset
  input wire                       rst_i,
  //! Baud rate select signal
  input wire [BAUD_RATE_SEL_W-1:0] baud_sel_i
);

  /*** CONSTANTS **************************************************************/

  localparam integer MIN_SAMPLE_FREQ_9600_BAUD_HZ   =  153600;
  localparam integer MIN_SAMPLE_FREQ_19200_BAUD_HZ  =  307200;
  localparam integer MIN_SAMPLE_FREQ_115200_BAUD_HZ = 1843200;
  localparam integer MIN_SAMPLE_FREQ_256000_BAUD_HZ = 4086000;

  localparam integer SAMPLE_COUNT_9600_BAUD   = ( TOP_CLK_FREQ_HZ / MIN_SAMPLE_FREQ_9600_BAUD_HZ );
  localparam integer SAMPLE_COUNT_19200_BAUD  = ( TOP_CLK_FREQ_HZ / MIN_SAMPLE_FREQ_19200_BAUD_HZ );
  localparam integer SAMPLE_COUNT_115200_BAUD = ( TOP_CLK_FREQ_HZ / MIN_SAMPLE_FREQ_115200_BAUD_HZ );
  localparam integer SAMPLE_COUNT_256000_BAUD = ( TOP_CLK_FREQ_HZ / MIN_SAMPLE_FREQ_256000_BAUD_HZ );

  /*** SIGNALS ****************************************************************/

  wire baud_en_s;

  /*** INSTANTIATIONS *********************************************************/
  
  baud_generator #(
    .TOP_CLK_FREQ_HZ                ( TOP_CLK_FREQ_HZ                ),    
    .MIN_SAMPLE_FREQ_9600_BAUD_HZ   ( MIN_SAMPLE_FREQ_9600_BAUD_HZ   ),                 
    .MIN_SAMPLE_FREQ_19200_BAUD_HZ  ( MIN_SAMPLE_FREQ_19200_BAUD_HZ  ),                  
    .MIN_SAMPLE_FREQ_115200_BAUD_HZ ( MIN_SAMPLE_FREQ_115200_BAUD_HZ ),                   
    .MIN_SAMPLE_FREQ_256000_BAUD_HZ ( MIN_SAMPLE_FREQ_256000_BAUD_HZ ),                   
    .SAMPLE_COUNT_9600_BAUD         ( SAMPLE_COUNT_9600_BAUD         ),           
    .SAMPLE_COUNT_19200_BAUD        ( SAMPLE_COUNT_19200_BAUD        ),            
    .SAMPLE_COUNT_115200_BAUD       ( SAMPLE_COUNT_115200_BAUD       ),             
    .SAMPLE_COUNT_256000_BAUD       ( SAMPLE_COUNT_256000_BAUD       )         
  ) i_baud_generator (
    .clk_i      ( clk_i      ),  
    .rst_i      ( rst_i      ),  
    .baud_sel_i ( baud_sel_i ),       
    .baud_en_o  ( baud_en_s  )      
  );

  tx_module #(
    .MAX_UART_DATA_W      (MAX_UART_DATA_W),        
    .STOP_CONF_WIDTH      (),         
    .DATA_CONF_WIDTH      (),         
    .SAMPLE_COUNTER_WIDTH ()             
  ) i_tx_module (
    .clk_i      (clk_i),    
    .rst_i      (rst_i),    
    .baud_en_i  (baud_en_s),        
    .tx_en_i    (),      
    .tx_start_i (),         
    .tx_conf_i  (),        
    .tx_data_i  (),        
    .tx_done_o  (),        
    .busy_o     (),     
    .uart_tx_o  ()      
  );

  rx_module #(
    .MAX_UART_DATA_W      (MAX_UART_DATA_W),   
    .STOP_CONF_WIDTH      (),    
    .DATA_CONF_WIDTH      (),    
    .SAMPLE_COUNTER_WIDTH ()        
  ) i_rx_module (
    .clk_i          (clk_i),     
    .rst_i          (rst_i),     
    .baud_en_i      (baud_en_s),         
    .rx_en_i        (),       
    .uart_rx_i      (),         
    .rx_conf_i      (),         
    .rx_done_o      (),         
    .busy_o         (),      
    .parity_error_o (),              
    .rx_data_o      ()        
  );

endmodule // uart_controller