/*------------------------------------------------------------------------------
-- Title      : FPGA UART Reset Synchroniser
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : reset_sync.v
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2025-01-25
-- Design     : reset_sync
-- Platform   : -
-- Standard   : Verilog '05
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2025-01-25  1.0      TZS     Created
------------------------------------------------------------------------------*/
/***  DESCRIPTION ***/
//! Reset synchroniser
//! Active-low input, active high output
/*----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module reset_sync #(
  parameter SYNC_REG_COUNT = 3
) (
  input  wire dest_clk_i,
  input  wire arstn_i,
  output wire rst_o
);

  reg [SYNC_REG_COUNT-1:0] sync_reg_r;

  always @(posedge dest_clk_i or negedge arstn_i) begin
    if (~arstn_i) begin
      sync_reg_r <= {SYNC_REG_COUNT{1'b0}};
    end else begin
      sync_reg_r <= {sync_reg_r[SYNC_REG_COUNT-2:0], 1'b1};
    end
  end

  assign rst_o = sync_reg_r[SYNC_REG_COUNT-1];

endmodule
