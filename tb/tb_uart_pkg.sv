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
    input  bit          parity_en
  );

    automatic bit [StopCfgWidth-1:0] stop_bits_s;
    automatic bit [DataCfgWidth-1:0] data_bits_s;

    if (stop_bits > StopWidthMax)
      $error("[TB %0t] get_uart_config - provided stop bit count too large! Max = 3", $time);

    if (stop_bits < StopWidthMin)
      $error("[TB %0t] get_uart_config - provided stop bit count too small! Min = 1", $time);

    if (data_bits > DataWidthMax)
      $error("[TB %0t] get_uart_config - provided data bit count too large! Max = 8", $time);

    if (data_bits < DataWidthMin)
      $error("[TB %0t] get_uart_config - provided data bit count too small! Min = 5", $time);

    stop_bits_s = (stop_bits - StopWidthMin);
    data_bits_s = (data_bits - DataWidthMin);

    return {data_bits_s, stop_bits_s, parity_en};

  endfunction

endpackage
