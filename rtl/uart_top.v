/*------------------------------------------------------------------------------
-- Title      : FPGA UART Top
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : uart_top.v
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2025-01-24
-- Design     : uart_top
-- Platform   : -
-- Standard   : Verilog '05
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2025-01-24  1.0      TZS     Created
------------------------------------------------------------------------------*/
/***  DESCRIPTION ***/
//! Top module for FPGA UART containing register controller and UART controller.
// ToDo: Add FIFO
/*----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module uart_top #(
  parameter          TOP_CLK_FREQ_HZ  = 50_000_000, //! Frequency of input clock in Hz
  localparam integer CPU_ADDR_WIDTH   =          2, //! Output data to CPU
  localparam integer CPU_DATA_WIDTH   =         32  //! Output data from registers to peripherals
) (
  input  wire                       clk_i,       //! Top clock
  input  wire                       rst_i,       //! Synchronous active-high reset

  // UART Signals

  input  wire                       uart_rx_i,   //! External Rx input of UART

  output wire                       uart_tx_o,   //! External Tx output of UART

  // CPU Interface Signals

  input  wire                       wr_en_cpu_i, //! Write enable signal from CPU bus
  input  wire                       rd_en_cpu_i, //! Read enable signal from CPU bus
  input  wire [ CPU_ADDR_WIDTH-1:0] cpu_addr_i,  //! Address from CPU bus
  input  wire [ CPU_DATA_WIDTH-1:0] cpu_data_i,  //! Write data FROM CPU bus

  output wire [ CPU_DATA_WIDTH-1:0] cpu_data_o   //! Read data TO CPU bus
);

  /* constants ****************************************************************/
  localparam integer MAX_UART_DATA_W  = 8;                             //! Maximum width of UART data 
  localparam integer STOP_CONF_W      = 2;                             //! Width of stop bit configuration field
  localparam integer DATA_CONF_W      = 2;                             //! Width of data bit configuration field
  localparam integer BAUD_RATE_SEL_W  = 2;                             //! Width of Baud rate select signal = $clog2(N_BAUD_RATE_VALS)
  localparam integer TOTAL_CONF_W     = STOP_CONF_W + DATA_CONF_W + 1; //! Total width of configuration data bits sent to Tx and Rx modules
  localparam integer N_BAUD_RATE_VALS = 4;                             //! Number of Baud rate values
  localparam integer SAMPLE_COUNT_W   = 4;                             //! Width of sample counter within Tx and Rx module (sampled 16 times) = $clog2(16)

  /* signals and type declarations ********************************************/

  // connecting signals
  wire                       tx_done_s;
  wire                       tx_busy_s;
  wire                       rx_done_s;
  wire                       rx_parity_err_s;
  wire                       rx_stop_err_s;
  wire                       rx_busy_s;
  wire [MAX_UART_DATA_W-1:0] rx_data_s;
  wire                       rx_fifo_full_s;
  wire                       rx_fifo_nearly_full_s;
  wire                       rx_fifo_empty_s;
  wire                       rx_fifo_nearly_empty_s;
  wire                       tx_fifo_full_s;
  wire                       tx_fifo_nearly_full_s;
  wire                       tx_fifo_empty_s;
  wire                       tx_fifo_nearly_empty_s;
  wire                       tx_fifo_push_s;
  wire                       rx_fifo_pop_s;
  wire [BAUD_RATE_SEL_W-1:0] baud_sel_s;
  wire                       tx_en_s;
  wire                       tx_start_s;
  wire [   TOTAL_CONF_W-1:0] tx_conf_s;
  wire [MAX_UART_DATA_W-1:0] tx_data_s;
  wire                       tx_fifo_en_s;
  wire                       rx_en_s;
  wire [   TOTAL_CONF_W-1:0] rx_conf_s;
  wire                       rx_fifo_en_s;

  /* Components ***************************************************************/

  // UART Register Controller
  uart_reg_ctrl #(
    .MAX_UART_DATA_W ( MAX_UART_DATA_W ),
    .STOP_CONF_W     ( STOP_CONF_W     ),
    .DATA_CONF_W     ( DATA_CONF_W     ),
    .BAUD_RATE_SEL_W ( BAUD_RATE_SEL_W ),
    .TOTAL_CONF_W    ( TOTAL_CONF_W    ),
    .CPU_ADDR_WIDTH  ( CPU_ADDR_WIDTH  ),
    .CPU_DATA_WIDTH  ( CPU_DATA_WIDTH  )
  ) i_uart_register_controller (
    .clk_i                  ( clk_i                  ),
    .rst_i                  ( rst_i                  ),
    .tx_done_i              ( tx_done_s              ),
    .tx_busy_i              ( tx_busy_s              ),
    .rx_done_i              ( rx_done_s              ),
    .rx_parity_err_i        ( rx_parity_err_s        ),
    .rx_stop_err_i          ( rx_stop_err_s          ),
    .rx_busy_i              ( rx_busy_s              ),
    .rx_data_i              ( rx_data_s              ),
    .rx_fifo_full_i         ( rx_fifo_full_s         ),
    .rx_fifo_nearly_full_i  ( rx_fifo_nearly_full_s  ),
    .rx_fifo_empty_i        ( rx_fifo_empty_s        ),
    .rx_fifo_nearly_empty_i ( rx_fifo_nearly_empty_s ),
    .tx_fifo_full_i         ( tx_fifo_full_s         ),
    .tx_fifo_nearly_full_i  ( tx_fifo_nearly_full_s  ),
    .tx_fifo_empty_i        ( tx_fifo_empty_s        ),
    .tx_fifo_nearly_empty_i ( tx_fifo_nearly_empty_s ),
    .tx_fifo_push_o         ( tx_fifo_push_s         ),
    .rx_fifo_pop_o          ( rx_fifo_pop_s          ),
    .baud_sel_o             ( baud_sel_s             ),
    .tx_en_o                ( tx_en_s                ),
    .tx_start_o             ( tx_start_s             ),
    .tx_conf_o              ( tx_conf_s              ),
    .tx_data_o              ( tx_data_s              ),
    .tx_fifo_en_o           ( tx_fifo_en_s           ),
    .rx_en_o                ( rx_en_s                ),
    .rx_conf_o              ( rx_conf_s              ),
    .rx_fifo_en_o           ( rx_fifo_en_s           ),
    .wr_en_cpu_i            ( wr_en_cpu_i            ),
    .rd_en_cpu_i            ( rd_en_cpu_i            ),
    .cpu_addr_i             ( cpu_addr_i             ),
    .cpu_data_i             ( cpu_data_i             ),
    .cpu_data_o             ( cpu_data_o             )
  );

  // UART Controller
  uart_controller #(
    .TOP_CLK_FREQ_HZ  ( TOP_CLK_FREQ_HZ  ),
    .MAX_UART_DATA_W  ( MAX_UART_DATA_W  ),
    .STOP_CONF_W      ( STOP_CONF_W      ),
    .DATA_CONF_W      ( DATA_CONF_W      ),
    .SAMPLE_COUNT_W   ( SAMPLE_COUNT_W   ),
    .N_BAUD_RATE_VALS ( N_BAUD_RATE_VALS ),
    .BAUD_RATE_SEL_W  ( BAUD_RATE_SEL_W  ),
    .TOTAL_CONF_W     ( TOTAL_CONF_W     )
  ) i_uart_controller (
    .clk_i           ( clk_i              ),
    .rst_i           ( rst_i              ),
    .baud_sel_i      ( baud_sel_s         ),
    .tx_en_i         ( tx_en_s            ),
    .tx_start_i      ( tx_start_s         ),
    .tx_conf_i       ( tx_conf_s          ),
    .tx_data_i       ( tx_data_s          ),
    .tx_fifo_en_i    ( tx_fifo_en_s       ),
    .rx_en_i         ( rx_en_s            ),
    .uart_rx_i       ( uart_rx_i          ),
    .rx_conf_i       ( rx_conf_s          ),
    .rx_fifo_en_i    ( rx_fifo_en_s       ),
    .rx_fifo_full_i  ( rx_fifo_full_s     ),
    .tx_done_o       ( tx_done_s          ),
    .tx_busy_o       ( tx_busy_s          ),
    .uart_tx_o       ( uart_tx_o          ),
    .tx_fifo_pop_o   (  /* UNCONNECTED */ ),
    .rx_done_o       ( rx_done_s          ),
    .rx_parity_err_o ( rx_parity_err_s    ),
    .rx_stop_err_o   ( rx_stop_err_s      ),
    .rx_busy_o       ( rx_busy_s          ),
    .rx_data_o       ( rx_data_s          ),
    .rx_fifo_push_o  ( /* UNCONNECTED */  )
  );

  // ToDo: Add FIFOs HERE!

  /* Assignments **************************************************************/
  assign rx_fifo_full_s         = 1'b0;
  assign rx_fifo_nearly_full_s  = 1'b0;
  assign rx_fifo_empty_s        = 1'b0;
  assign rx_fifo_nearly_empty_s = 1'b0;
  assign tx_fifo_full_s         = 1'b0;
  assign tx_fifo_nearly_full_s  = 1'b0;
  assign tx_fifo_empty_s        = 1'b0;
  assign tx_fifo_nearly_empty_s = 1'b0;


endmodule
