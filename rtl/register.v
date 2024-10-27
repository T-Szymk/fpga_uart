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

`timescale 1ns/1ps

module register #(
  parameter integer         REG_WIDTH          = 32,
  parameter [REG_WIDTH-1:0] READ_WRITE_PATTERN = {REG_WIDTH{1'b0}},
  parameter [REG_WIDTH-1:0] READ_CLEAR_PATTERN = {REG_WIDTH{1'b0}}
) (
  input  wire                 clk_i,          //! Clock signal
  input  wire                 rst_i,          //! Synch active-high reset
  input  wire                 wr_en_periph_i, //! Write enable from peripheral
  input  wire                 wr_en_cpu_i,    //! Write enable from CPU/Master
  input  wire                 rd_en_cpu_i,    //! Read enable from CPU/Master
  input  wire [REG_WIDTH-1:0] data_periph_i,  //! Data from peripheral
  input  wire [REG_WIDTH-1:0] data_cpu_i,     //! Data from CPU

  output wire [REG_WIDTH-1:0] data_o          //! Output data from register
);

  reg [REG_WIDTH-1:0] data_r = {REG_WIDTH{1'b0}};

  assign data_o = data_r;

  genvar bit_idx;

  generate

    for (bit_idx = 0; bit_idx < REG_WIDTH-1; bit_idx=bit_idx+1) begin : gen_bit_cfg

      always @(posedge clk_i) begin

        if (rst_i) begin

          data_r[bit_idx] <= 1'b0;

        end else begin

          // prioritise writes from CPU side
          if (wr_en_cpu_i) begin

            // only write if bit is R/W
            if (READ_WRITE_PATTERN[bit_idx]) begin
              data_r[bit_idx] <= data_cpu_i[bit_idx];
            end

          end else if (wr_en_periph_i) begin

            if (READ_WRITE_PATTERN[bit_idx]) begin
              data_r[bit_idx] <= data_periph_i[bit_idx];
            end

          // if data is read and read clear cfg is set for bit, clear contents
          end else if (rd_en_cpu_i) begin

            if (READ_CLEAR_PATTERN[bit_idx]) begin
              data_r[bit_idx] <= 1'b0;
            end

          end
        end
      end
    end

  endgenerate

endmodule

