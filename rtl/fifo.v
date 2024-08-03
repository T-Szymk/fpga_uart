/*------------------------------------------------------------------------------
-- Title      : FIFO
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : fifo.v
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2024-08-03
-- Design     : fifo
-- Platform   : -
-- Standard   : Verilog '05
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2024-08-03  1.0      TZS     Created
------------------------------------------------------------------------------*/
/*** DESCRIPTION ***/
//! Basic FIFO designed to be suitable for use with synchronous BRAMS in SDP cfg
/*----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module fifo #(
  parameter WIDTH = 8,
  parameter DEPTH = 4
)(
  input  wire             clk_i,
  input  wire             rst_i,
  // control
  input  wire             push_i,
  input  wire             pop_i,
  input  wire [WIDTH-1:0] data_i,
  output wire [WIDTH-1:0] data_o,
  // status
  output wire              full_o,
  output wire              empty_o,
  output wire              nearly_full_o,
  output wire              nearly_empty_o
);

  /*** CONSTANTS **************************************************************/

  localparam RAMAddrWidth = $clog2(DEPTH);

  /*** SIGNALS ****************************************************************/

  reg [RAMAddrWidth-1:0] rd_ptr_d, rd_ptr_q;
  reg [RAMAddrWidth-1:0] wr_ptr_d, wr_ptr_q;

  reg rd_en_s, wr_en_s;

  reg [RAMAddrWidth:0] fill_count_d, fill_count_q;

  wire full_s, nearly_full_s;
  wire empty_s, nearly_empty_s;

  /*** INSTANTIATIONS *********************************************************/

    bram #(
      .RAM_WIDTH ( WIDTH    ),
      .RAM_DEPTH ( DEPTH    )
    ) i_bram (
      .clk_i     ( clk_i    ),
      .rst_i     ( rst_i    ),
      .rd_en_i   ( rd_en_s  ),
      .wr_en_i   ( wr_en_s  ),
      .rd_addr_i ( rd_ptr_q ),
      .wr_addr_i ( wr_ptr_q ),
      .data_i    ( data_i   ),
      .data_o    ( data_o   )
    );

  /*** RTL ********************************************************************/

  always @(posedge clk_i) begin
    if (rst_i) begin
      rd_ptr_q     <= 0;
      wr_ptr_q     <= 0;
      fill_count_q <= 0;
    end else begin
      rd_ptr_q     <= rd_ptr_d;
      wr_ptr_q     <= wr_ptr_d;
      fill_count_q <= fill_count_d;
    end
  end

  always @(*) begin

    // default assignments
    rd_ptr_d = rd_ptr_q;
    wr_ptr_d = wr_ptr_q;
    wr_en_s  = 1'b0;
    rd_en_s  = 1'b0;

    if (push_i && ~full_s) begin
      wr_ptr_d = (wr_ptr_q == DEPTH-1) ? 0 : wr_ptr_q + 1;
      wr_en_s  = 1'b1;
    end

    if (pop_i && ~empty_s) begin
      rd_ptr_d = (rd_ptr_q == DEPTH-1) ? 0 : rd_ptr_q + 1;
      rd_en_s  = 1'b1;
    end
    
  end

  always @(*) begin
    // default assignments
    fill_count_d = fill_count_q;

    if (push_i && ~full_s) begin
      if (pop_i && ~empty_s) begin
        // counter maintains value if push + pop simultaneously 
        fill_count_d = fill_count_q;
      end else begin
        fill_count_d = fill_count_q + 1;
      end
    end else if (pop_i && ~empty_s) begin 
      fill_count_d = fill_count_q - 1;
    end
  end

  /*** ASSIGNMENTS ***/

  assign full_s         = (fill_count_q == DEPTH)     ? 1'b1 : 1'b0;
  assign nearly_full_s  = (fill_count_q == (DEPTH-1)) ? 1'b1 : 1'b0;
  assign empty_s        = (fill_count_q == 0)         ? 1'b1 : 1'b0;
  assign nearly_empty_s = (fill_count_q == 1)         ? 1'b1 : 1'b0;

  assign full_o         = full_s;
  assign empty_o        = empty_s;
  assign nearly_full_o  = nearly_full_s;
  assign nearly_empty_o = nearly_empty_s;

endmodule
