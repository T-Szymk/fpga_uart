/*------------------------------------------------------------------------------
-- Title      : Package FPGA UART Testbenches
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : tb_uart_pkg.sv
-- Author(s)  : Thomas Szymkowiak
-- Company    : L3Harris
-- Created    : 2024-10-21
-- Design     : tb_uart_pkg
-- Platform   : -
-- Standard   : SystemVerilog '17
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2024-10-21  1.0      TZS     Created
--------------------------------------------------------------------------------
*** DESCRIPTION ***
--------------------------------------------------------------------------------
Contains types, constants and functions which are used across the testbenches 
within the FPGA UART project
------------------------------------------------------------------------------*/


package tb_uart_pkg;

  localparam int unsigned StopWidthMax = 3;
  localparam int unsigned StopWidthMin = 1;
  localparam int unsigned DataWidthMax = 8;
  localparam int unsigned DataWidthMin = 5;

  localparam int unsigned StopCfgWidth = 2;                                //! Width of stop bit configuration field
  localparam int unsigned DataCfgWidth = 2;                                //! Width of data bit configuration field
  localparam int unsigned TotalCfgWidth = StopCfgWidth + DataCfgWidth + 1; //! Total width of configuration data bits sent to Tx and Rx modules


  // get bit pattern for configuring UART Tx/Rx
  function automatic bit [TotalCfgWidth-1:0] get_uart_config(
    input  int unsigned data_bits,
    input  int unsigned stop_bits,
    input  int unsigned parity_en
  );

    automatic bit [StopCfgWidth-1:0] stop_bits_s;
    automatic bit [DataCfgWidth-1:0] data_bits_s;
    automatic bit                    parity_en_s;

    if (stop_bits > StopWidthMax || stop_bits < StopWidthMin)
      $error("[TB %0t] get_uart_config - provided stop bit count out of valid range 1 - 3!", $time);

    if (data_bits > DataWidthMax || data_bits < DataWidthMin)
      $error("[TB %0t] get_uart_config - provided data bit count out of valid range 5 - 8!", $time);

    if (parity_en != 0 && parity_en != 1)
      $error("[TB %0t] get_uart_config - provided parity_en not valid!", $time);

    stop_bits_s = (stop_bits - StopWidthMin);
    data_bits_s = (data_bits - DataWidthMin);
    parity_en_s = parity_en;

    return {data_bits_s, stop_bits_s, parity_en_s};

  endfunction

endpackage
