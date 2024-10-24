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

  typedef enum bit [1:0] {
    BAUD9600   = 2'b00,
    BAUD19200  = 2'b01,
    BAUD115200 = 2'b10,
    BAUD256000 = 2'b11
  } baud_rate_e;

  // get bit pattern for configuring UART Tx/Rx
  function automatic bit [TotalCfgWidth-1:0] get_uart_config (
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

  // get bit pattern for target Baud rate
  function automatic bit [1:0] get_baud_bits (
    input baud_rate_e requested_baud
  );
    case (requested_baud)
      BAUD9600   : begin
        return 2'b00;
      end
      BAUD19200  : begin
        return 2'b01;
      end
      BAUD115200 : begin
        return 2'b10;
      end
      BAUD256000 : begin
        return 2'b11;
      end
      default : begin
        return 2'b00; // defualt 9600 Baud
      end
    endcase
  endfunction

endpackage
