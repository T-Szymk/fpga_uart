/*------------------------------------------------------------------------------
-- Title      : FPGA UART Registers
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : registers.v
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2024-10-26
-- Design     : registers
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

module registers #(
  parameter REG_WIDTH = 32,
  parameter READ_CLEAR = 0
) (
  input  wire                 clk_i,
  input  wire                 rst_i,
  input  wire                 wr_en_periph_i,
  input  wire                 wr_en_cpu_i,
  input  wire                 rd_en_cpu_i,
  input  wire [REG_WIDTH-1:0] data_periph_i,
  input  wire [REG_WIDTH-1:0] data_cpu_i,

  output wire                 updated_o,
  output wire [REG_WIDTH-1:0] data_o
);

  reg [REG_WIDTH-1:0] data_r    = {REG_WIDTH{1'b0}};
  reg                 updated_r = 1'b0;

  assign data_o = data_r;

  // clear register contents when read by CPU
  generate
    // clear register contents when read is active and no write
    if (READ_CLEAR) begin : gen_read_clear

      always @(posedge clk_i) begin

        if (rst_i) begin

          data_r    <= {REG_WIDTH{1'b0}};
          updated_r <= 1'b0;

        end else begin

          updated_r <= 1'b0;

          // prioritise writes from CPU side
          if (wr_en_cpu_i) begin
            data_r    <= data_cpu_i;
            updated_r <= 1'b1;
          end else if (wr_en_periph_i) begin
            data_r    <= data_periph_i;
            updated_r <= 1'b1;
          // if data is read, clear contents
          end else if (rd_en_cpu_i) begin
            data_r   <= {REG_WIDTH{1'b0}};
          end

        end
      end

    end else begin : gen_no_read_clear

      always @(posedge clk_i) begin

        if (rst_i) begin

          data_r    <= {REG_WIDTH{1'b0}};
          updated_r <= 1'b0;

        end else begin

          updated_r <= 1'b0;

          // prioritise writes from CPU side
          if (wr_en_cpu_i) begin
            data_r    <= data_cpu_i;
            updated_r <= 1'b1;
          end else if (wr_en_periph_i) begin
            data_r    <= data_periph_i;
            updated_r <= 1'b1;
          end

        end
      end
    end

  endgenerate

endmodule

