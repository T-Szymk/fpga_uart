/*------------------------------------------------------------------------------
-- Title      : FPGA UART Register
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : registers.v
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2024-10-26
-- Design     : register
-- Platform   : -
-- Standard   : Verilog '05
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2024-10-26  1.0      TZS     Created
------------------------------------------------------------------------------*/
/***  DESCRIPTION ***/
//! Definition of parameterisable registers for use within the FPGA UART
/*----------------------------------------------------------------------------*/

module uart_registers #(
  parameter integer ADDR_WIDTH =  2,
  parameter integer DATA_WIDTH = 32,
  parameter integer REG_COUNT  =  4
) (
  input  wire                  clk_i,
  input  wire                  rst_i,
  input  wire [ADDR_WIDTH-1:0] addr_i,
  input  wire [DATA_WIDTH-1:0] data_i,
  input  wire                  wr_en_periph_i,
  input  wire                  wr_en_cpu_i,
  input  wire                  rd_en_cpu_i,

  output wire [               REG_COUNT-1:0] updated_o,
  output wire [(REG_COUNT * DATA_WIDTH)-1:0] data_o
);

endmodule
