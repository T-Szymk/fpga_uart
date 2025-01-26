/*------------------------------------------------------------------------------
-- Title      : 1 Bit synchroniser
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : sync_1bit.v
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2025-01-26
-- Design     : sync_1bit
-- Platform   : -
-- Standard   : Verilog '05
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2025-01-26  1.0      TZS     Created
------------------------------------------------------------------------------*/
/*** DESCRIPTION ***/
//! Generic 1-bit synchroniser. Number of synchroniser flops is configurable
/*----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module sync_1bit #(
  parameter SYNC_DEPTH = 2 //! Number of synchroniser stages
) (
  input  wire dst_clk_i,   //! Clock from destination clock domain
  input  wire dst_rst_i,   //! Active-hi synch reset from destination domain
  input  wire src_data_i,  //! Data in to be synchronised

  output wire dst_data_o   //! Synchronised data out
);

  reg [SYNC_DEPTH-1:0] sync_reg;

  always @(posedge dst_clk_i) begin

    if (dst_rst_i) begin

      sync_reg <= {SYNC_DEPTH{1'b0}};

    end else begin

      sync_reg <= {sync_reg[SYNC_DEPTH-2:0], src_data_i};

    end
  end

  assign dst_data_o = sync_reg[SYNC_DEPTH-1];

endmodule
