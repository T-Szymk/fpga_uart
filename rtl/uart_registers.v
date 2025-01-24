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

module uart_registers #(
  parameter ADDR_WIDTH =  2,
  parameter DATA_WIDTH = 32,
  parameter REG_WIDTH  = 32,
  parameter REG_COUNT  =  4
) (
  input  wire                                clk_i,          //! Clock
  input  wire                                rst_i,          //! Sync active-high reset
  input  wire [              ADDR_WIDTH-1:0] cpu_addr_i,     //! Addr line from CPU bus
  input  wire [              DATA_WIDTH-1:0] cpu_data_i,     //! Data line from CPU bus
  input  wire [(REG_COUNT * DATA_WIDTH)-1:0] periph_data_i,  //! Data from peripheral
  input  wire [               REG_COUNT-1:0] wr_en_periph_i, //! Write enables from peripheral
  input  wire                                wr_en_cpu_i,    //! Write enable from CPU
  input  wire                                rd_en_cpu_i,    //! Read enable from CPU

  output wire [              DATA_WIDTH-1:0] cpu_data_o,     //! Output data to CPU
  output wire [(REG_COUNT * DATA_WIDTH)-1:0] periph_data_o   //! Output data from registers to peripherals
);

  // constants
  // ToDo: Move to Header!
  localparam [ADDR_WIDTH-1:0] UART_STAT_ADDR = 0;
  localparam [ADDR_WIDTH-1:0] UART_CTRL_ADDR = 1;
  localparam [ADDR_WIDTH-1:0] UART_TX_ADDR   = 2;
  localparam [ADDR_WIDTH-1:0] UART_RX_ADDR   = 3;

  // signals

  // write enables
  reg  stat_reg_wr_en_cpu_s;
  reg  ctrl_reg_wr_en_cpu_s;
  reg  tx_reg_wr_en_cpu_s;
  reg  rx_reg_wr_en_cpu_s;
  wire stat_reg_wr_en_periph_s;
  wire ctrl_reg_wr_en_periph_s;
  wire tx_reg_wr_en_periph_s;
  wire rx_reg_wr_en_periph_s;

  // read enables
  reg stat_reg_rd_en_cpu_s;
  reg ctrl_reg_rd_en_cpu_s;
  reg tx_reg_rd_en_cpu_s;
  reg rx_reg_rd_en_cpu_s;

  // input data
  reg  [REG_WIDTH-1:0] stat_reg_data_cpu_i_s;
  reg  [REG_WIDTH-1:0] ctrl_reg_data_cpu_i_s;
  reg  [REG_WIDTH-1:0] tx_reg_data_cpu_i_s;
  reg  [REG_WIDTH-1:0] rx_reg_data_cpu_i_s;
  wire [REG_WIDTH-1:0] stat_reg_data_periph_i_s;
  wire [REG_WIDTH-1:0] ctrl_reg_data_periph_i_s;
  wire [REG_WIDTH-1:0] tx_reg_data_periph_i_s;
  wire [REG_WIDTH-1:0] rx_reg_data_periph_i_s;

  // output data
  reg [REG_WIDTH-1:0] stat_reg_data_o_s;
  reg [REG_WIDTH-1:0] ctrl_reg_data_o_s;
  reg [REG_WIDTH-1:0] tx_reg_data_o_s;
  reg [REG_WIDTH-1:0] rx_reg_data_o_s;
  reg [REG_WIDTH-1:0] cpu_data_o_s;

  // assignments

  // concat all output data for extensibility
  assign periph_data_o = {rx_reg_data_o_s,
                          tx_reg_data_o_s,
                          ctrl_reg_data_o_s,
                          stat_reg_data_o_s};
  assign cpu_data_o    = cpu_data_o_s;

  // split data from peripherals
  assign stat_reg_data_periph_i_s =
    periph_data_i[((UART_STAT_ADDR+1)*REG_WIDTH)-1:(UART_STAT_ADDR*REG_WIDTH)];
  assign ctrl_reg_data_periph_i_s =
    periph_data_i[((UART_CTRL_ADDR+1)*REG_WIDTH)-1:(UART_CTRL_ADDR*REG_WIDTH)];
  assign tx_reg_data_periph_i_s   =
    periph_data_i[((UART_TX_ADDR+1)*REG_WIDTH)-1:(UART_TX_ADDR*REG_WIDTH)];
  assign rx_reg_data_periph_i_s   =
    periph_data_i[((UART_RX_ADDR+1)*REG_WIDTH)-1:(UART_RX_ADDR*REG_WIDTH)];

  assign stat_reg_wr_en_periph_s = wr_en_periph_i[UART_STAT_ADDR];
  assign ctrl_reg_wr_en_periph_s = wr_en_periph_i[UART_CTRL_ADDR];
  assign tx_reg_wr_en_periph_s   = wr_en_periph_i[UART_TX_ADDR];
  assign rx_reg_wr_en_periph_s   = wr_en_periph_i[UART_RX_ADDR];

  // logic

  // address based decoding for CPU signals
  always @(*) begin

    // default assignments
    stat_reg_wr_en_cpu_s  = 1'b0;
    stat_reg_rd_en_cpu_s  = 1'b0;
    stat_reg_data_cpu_i_s = {DATA_WIDTH{1'b0}};
    ctrl_reg_wr_en_cpu_s  = 1'b0;
    ctrl_reg_rd_en_cpu_s  = 1'b0;
    ctrl_reg_data_cpu_i_s = {DATA_WIDTH{1'b0}};
    tx_reg_wr_en_cpu_s    = 1'b0;
    tx_reg_rd_en_cpu_s    = 1'b0;
    tx_reg_data_cpu_i_s   = {DATA_WIDTH{1'b0}};
    rx_reg_wr_en_cpu_s    = 1'b0;
    rx_reg_rd_en_cpu_s    = 1'b0;
    rx_reg_data_cpu_i_s   = {DATA_WIDTH{1'b0}};
    cpu_data_o_s          = {DATA_WIDTH{1'b0}};

    case (cpu_addr_i)

      UART_STAT_ADDR : begin
        stat_reg_wr_en_cpu_s  = wr_en_cpu_i;
        stat_reg_rd_en_cpu_s  = rd_en_cpu_i;
        stat_reg_data_cpu_i_s = cpu_data_i;
        cpu_data_o_s          = stat_reg_data_o_s;
      end

      UART_CTRL_ADDR : begin
        ctrl_reg_wr_en_cpu_s  = wr_en_cpu_i;
        ctrl_reg_rd_en_cpu_s  = rd_en_cpu_i;
        ctrl_reg_data_cpu_i_s = cpu_data_i;
        cpu_data_o_s          = ctrl_reg_data_o_s;
      end

      UART_TX_ADDR : begin
        tx_reg_wr_en_cpu_s    = wr_en_cpu_i;
        tx_reg_rd_en_cpu_s    = rd_en_cpu_i;
        tx_reg_data_cpu_i_s   = cpu_data_i;
        cpu_data_o_s          = tx_reg_data_o_s;
      end

      UART_RX_ADDR : begin
        rx_reg_wr_en_cpu_s    = wr_en_cpu_i;
        rx_reg_rd_en_cpu_s    = rd_en_cpu_i;
        rx_reg_data_cpu_i_s   = cpu_data_i;
        cpu_data_o_s          = rx_reg_data_o_s;
      end

      default : begin
        stat_reg_wr_en_cpu_s  = 1'b0;
        stat_reg_rd_en_cpu_s  = 1'b0;
        stat_reg_data_cpu_i_s = {DATA_WIDTH{1'b0}};
        ctrl_reg_wr_en_cpu_s  = 1'b0;
        ctrl_reg_rd_en_cpu_s  = 1'b0;
        ctrl_reg_data_cpu_i_s = {DATA_WIDTH{1'b0}};
        tx_reg_wr_en_cpu_s    = 1'b0;
        tx_reg_rd_en_cpu_s    = 1'b0;
        tx_reg_data_cpu_i_s   = {DATA_WIDTH{1'b0}};
        rx_reg_wr_en_cpu_s    = 1'b0;
        rx_reg_rd_en_cpu_s    = 1'b0;
        rx_reg_data_cpu_i_s   = {DATA_WIDTH{1'b0}};
        cpu_data_o_s          = {DATA_WIDTH{1'b0}};
      end
    endcase

  end

  // components

  register #(
    .REG_WIDTH          ( REG_WIDTH            ),
    .READ_WRITE_PATTERN ( 32'd0                ),
    .READ_CLEAR_PATTERN ( 32'h10001            )
  ) i_uart_status_reg (
    .clk_i          ( clk_i                    ),
    .rst_i          ( rst_i                    ),
    .wr_en_periph_i ( stat_reg_wr_en_periph_s  ),
    .wr_en_cpu_i    ( stat_reg_wr_en_cpu_s     ),
    .rd_en_cpu_i    ( stat_reg_rd_en_cpu_s     ),
    .data_periph_i  ( stat_reg_data_periph_i_s ),
    .data_cpu_i     ( stat_reg_data_cpu_i_s    ),
    .data_o         ( stat_reg_data_o_s        )
  );

  register #(
    .REG_WIDTH          ( REG_WIDTH  ),
    .READ_WRITE_PATTERN ( 32'hC37D037F),
    .READ_CLEAR_PATTERN ( 32'd0      )
  ) i_uart_control_reg (
    .clk_i          ( clk_i                    ),
    .rst_i          ( rst_i                    ),
    .wr_en_periph_i ( ctrl_reg_wr_en_periph_s  ),
    .wr_en_cpu_i    ( ctrl_reg_wr_en_cpu_s     ),
    .rd_en_cpu_i    ( ctrl_reg_rd_en_cpu_s     ),
    .data_periph_i  ( ctrl_reg_data_periph_i_s ),
    .data_cpu_i     ( ctrl_reg_data_cpu_i_s    ),
    .data_o         ( ctrl_reg_data_o_s        )
  );

  register #(
    .REG_WIDTH          ( REG_WIDTH ),
    .READ_WRITE_PATTERN ( 32'hFF    ),
    .READ_CLEAR_PATTERN ( 32'd0     )
  ) i_tx_data_reg (
    .clk_i          ( clk_i                    ),
    .rst_i          ( rst_i                    ),
    .wr_en_periph_i ( tx_reg_wr_en_periph_s    ),
    .wr_en_cpu_i    ( tx_reg_wr_en_cpu_s       ),
    .rd_en_cpu_i    ( tx_reg_rd_en_cpu_s       ),
    .data_periph_i  ( tx_reg_data_periph_i_s   ),
    .data_cpu_i     ( tx_reg_data_cpu_i_s      ),
    .data_o         ( tx_reg_data_o_s          )
  );

  register #(
    .REG_WIDTH          ( REG_WIDTH ),
    .READ_WRITE_PATTERN ( 32'd0     ),
    .READ_CLEAR_PATTERN ( 32'd0     )
  ) i_rx_data_reg (
    .clk_i          ( clk_i                    ),
    .rst_i          ( rst_i                    ),
    .wr_en_periph_i ( rx_reg_wr_en_periph_s    ),
    .wr_en_cpu_i    ( rx_reg_wr_en_cpu_s       ),
    .rd_en_cpu_i    ( rx_reg_rd_en_cpu_s       ),
    .data_periph_i  ( rx_reg_data_periph_i_s   ),
    .data_cpu_i     ( rx_reg_data_cpu_i_s      ),
    .data_o         ( rx_reg_data_o_s          )
  );

endmodule
