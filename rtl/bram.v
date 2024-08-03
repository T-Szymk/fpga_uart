/*------------------------------------------------------------------------------
-- Title      : BRAM Wrapper
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : bram.v
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2024-08-03
-- Design     : bram
-- Platform   : -
-- Standard   : Verilog '05
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2024-08-03  1.0      TZS     Created
------------------------------------------------------------------------------*/
/*** DESCRIPTION ***/
//! Generic bram module to contain platform-specific DP BRAM implementation
//  Xilinx Simple Dual Port Single Clock RAM
//  This code implements a parameterizable SDP single clock memory.
// If a reset or enable is not necessary, it may be tied off or removed from the
// code.
/*----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module bram #(
  parameter RAM_WIDTH = 8, // Specify RAM data width
  parameter RAM_DEPTH = 4, // Specify RAM depth (number of entries)
  localparam AddrWidth = $clog2(RAM_DEPTH)
)(
  input  wire                 clk_i,
  input  wire                 rst_i,
  input  wire                 rd_en_i,
  input  wire                 wr_en_i,
  input  wire [AddrWidth-1:0] rd_addr_i,
  input  wire [AddrWidth-1:0] wr_addr_i,
  input  wire [RAM_WIDTH-1:0] data_i,
  output wire [RAM_WIDTH-1:0] data_o
);

reg [RAM_WIDTH-1:0] ram_r [RAM_DEPTH-1:0];
reg [RAM_WIDTH-1:0] ram_data_r = {RAM_WIDTH{1'b0}};

// The following code either initializes the memory values to a specified file or to all zeros to match hardware
generate

  integer ram_index;
  initial begin : ram_init_to_zero
    for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
      ram_r[ram_index] = {RAM_WIDTH{1'b0}};
  end

endgenerate

always @(posedge clk_i) begin

  if (wr_en_i) begin
    ram_r[wr_addr_i] <= data_i;
  end

  if (rd_en_i) begin
    ram_data_r <= ram_r[rd_addr_i];
  end

end

// The following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing
assign data_o = ram_data_r;

endmodule
