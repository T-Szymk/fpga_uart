/*------------------------------------------------------------------------------
-- Title      : FPGA UART Register Controller
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : uart_reg_ctrl.v
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2025-01-25
-- Design     : uart_reg_ctrl
-- Platform   : -
-- Standard   : Verilog '05
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2025-01-25  1.0      TZS     Created
------------------------------------------------------------------------------*/
/***  DESCRIPTION ***/
//! Module containing control logic to manage signals interfacing with UART
//! control registers.
//! Implementation is bus agnostic, so CPU bus controller should be implemented
//! Above this module and wen/ren/data_i/data_o signals should be driven by said
//! bus controller.
// ToDo: Create header defining register IDs and bit fields
// ToDo: Add FIFO controls
/*----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module uart_reg_ctrl #(
  parameter MAX_UART_DATA_W  = 8,                             //! Maximum width of UART data 
  parameter STOP_CONF_W      = 2,                             //! Width of stop bit configuration field
  parameter DATA_CONF_W      = 2,                             //! Width of data bit configuration field
  parameter BAUD_RATE_SEL_W  = 2,                             //! Width of Baud rate select signal = $clog2(N_BAUD_RATE_VALS)
  parameter TOTAL_CONF_W     = STOP_CONF_W + DATA_CONF_W + 1, //! Total width of configuration data bits sent to Tx and Rx modules
  parameter CPU_ADDR_WIDTH   =  2,                            //! Width of CPU address bus
  parameter CPU_DATA_WIDTH   = 32                             //! Width of CPU data bus
) (
  input  wire                       clk_i,                  //! Top clock
  input  wire                       rst_i,                  //! Synchronous active-high reset

  // Peripheral Interface Signals

  input  wire                       tx_done_i,              //! Tx done status signal (pulsed when Tx of one character completed)   
  input  wire                       tx_busy_i,              //! Tx status signal to indicate Tx module is busy sending something    

  input  wire                       rx_done_i,              //! Rx done status signal (pulsed when Rx of one character completed)                    
  input  wire                       rx_parity_err_i,        //! Rx status signal indicating that a parity error was recognised in latest received data                    
  input  wire                       rx_stop_err_i,          //! Rx status signal indicating that a stop error was recognised in latest received data                    
  input  wire                       rx_busy_i,              //! Rx status signal to indicate Rx module is busy receiving something                      
  input  wire [MAX_UART_DATA_W-1:0] rx_data_i,              //! Rx data that has been received

  input  wire                       rx_fifo_full_i,         //! Full indication from Rx FIFO
  input  wire                       rx_fifo_nearly_full_i,  //! Nearly full indication from Rx FIFO
  input  wire                       rx_fifo_empty_i,        //! Empty indication from Rx FIFO
  input  wire                       rx_fifo_nearly_empty_i, //! Nearly empty indication from Rx FIFO

  input  wire                       tx_fifo_full_i,         //! Full indication from Tx FIFO
  input  wire                       tx_fifo_nearly_full_i,  //! Nearly full indication from Tx FIFO
  input  wire                       tx_fifo_empty_i,        //! Empty indication from Tx FIFO
  input  wire                       tx_fifo_nearly_empty_i, //! Nearly empty indication from Tx FIFO

  output wire                       tx_fifo_push_o,         //! Push control for Tx FIFO
  output wire                       rx_fifo_pop_o,          //! Pop control for Rx FIFO

  output wire [BAUD_RATE_SEL_W-1:0] baud_sel_o,             //! Baud rate select signal
  output wire                       tx_en_o,                //! Enable for Tx module
  output wire                       tx_start_o,             //! Start signal to initiate transmission of data     
  output wire [   TOTAL_CONF_W-1:0] tx_conf_o,              //! Tx configuration data conf {data[1:0], stop[1:0], parity_en}       
  output wire [MAX_UART_DATA_W-1:0] tx_data_o,              //! Tx data to be transmitted
  output wire                       tx_fifo_en_o,           //! Enable for the Tx FIFO
  output wire                       rx_en_o,                //! Enable for Rx module
  output wire [   TOTAL_CONF_W-1:0] rx_conf_o,              //! Rx configuration data conf {data[1:0], stop[1:0], parity_en} 
  output wire                       rx_fifo_en_o,           //! Enable for the Rx FIFO

  // CPU Interface Signals

  input  wire                       wr_en_cpu_i,            //! Write enable signal from CPU bus
  input  wire                       rd_en_cpu_i,            //! Read enable signal from CPU bus
  input  wire [ CPU_ADDR_WIDTH-1:0] cpu_addr_i,             //! Address from CPU bus
  input  wire [ CPU_DATA_WIDTH-1:0] cpu_data_i,             //! Write data FROM CPU bus

  output wire [ CPU_DATA_WIDTH-1:0] cpu_data_o              //! Read data TO CPU bus
);

  /* constants ****************************************************************/

  localparam integer RegBusAddrWidth =  2;
  localparam integer RegWidth        = 32;
  localparam integer RegCount        =  4;

  // constants
  // ToDo: Move to Header!
  localparam [RegBusAddrWidth-1:0] UART_STAT_ADDR = 0;
  localparam [RegBusAddrWidth-1:0] UART_CTRL_ADDR = 1;
  localparam [RegBusAddrWidth-1:0] UART_TX_ADDR   = 2;
  localparam [RegBusAddrWidth-1:0] UART_RX_ADDR   = 3;

  /* signals and type declarations ********************************************/

  // grouped registers outputs
  wire [(RegCount * CPU_DATA_WIDTH)-1:0] periph_data_out_s;

  // grouped registers inputs
  wire [(RegCount * CPU_DATA_WIDTH)-1:0] periph_data_in_s;

  // individual register outputs
  wire [RegWidth-1:0] stat_reg_data_o_s;
  wire [RegWidth-1:0] ctrl_reg_data_o_s;
  wire [RegWidth-1:0] tx_reg_data_o_s;
  wire [RegWidth-1:0] rx_reg_data_o_s;

  // individual register inputs
  reg [RegWidth-1:0] stat_reg_data_i_s;
  reg [RegWidth-1:0] ctrl_reg_data_i_s;
  reg [RegWidth-1:0] tx_reg_data_i_s;
  reg [RegWidth-1:0] rx_reg_data_i_s;

  // Control register fields
  reg tx_start_in_r;

  // Peripheral write enable control word
  wire [RegCount-1:0] wr_en_periph_s;

  // Individual peripheral write enables
  reg stat_reg_periph_wr_en_r;
  reg ctrl_reg_periph_wr_en_r;
  reg tx_reg_periph_wr_en_r;
  reg rx_reg_periph_wr_en_r;

  /* Components ***************************************************************/

  // UART Register Component
  uart_registers #(
    .ADDR_WIDTH ( RegBusAddrWidth ),
    .DATA_WIDTH ( CPU_DATA_WIDTH  ),
    .REG_WIDTH  ( RegWidth        ),
    .REG_COUNT  ( RegCount        )
  ) i_uart_registers (
    .clk_i          ( clk_i             ),
    .rst_i          ( rst_i             ),
    .cpu_addr_i     ( cpu_addr_i        ),
    .cpu_data_i     ( cpu_data_i        ),
    .periph_data_i  ( periph_data_in_s  ),
    .wr_en_periph_i ( wr_en_periph_s    ),
    .wr_en_cpu_i    ( wr_en_cpu_i       ),
    .rd_en_cpu_i    ( rd_en_cpu_i       ),
    .cpu_data_o     ( cpu_data_o        ),
    .periph_data_o  ( periph_data_out_s )
  );

  /* Periph Write Enable Logic ************************************************/

  always @(posedge clk_i) begin : sync_wr_en_periph

    if (rst_i) begin

      stat_reg_periph_wr_en_r <= 1'b0;
      ctrl_reg_periph_wr_en_r <= 1'b0;
      tx_reg_periph_wr_en_r   <= 1'b0;
      rx_reg_periph_wr_en_r   <= 1'b0;

      tx_start_in_r           <= 1'b0;

    end else begin

      // status is read only, so will continuously be written by the peripheral
      stat_reg_periph_wr_en_r <= 1'b1;
      // Default assignment for other reg
      tx_reg_periph_wr_en_r   <= 1'b0;
      ctrl_reg_periph_wr_en_r <= 1'b0;
      rx_reg_periph_wr_en_r   <= 1'b0;

      // clear start bit when tx done is signalled
      if (tx_done_i == 1'b1) begin
        tx_start_in_r           <= 1'b0;
        ctrl_reg_periph_wr_en_r <= 1'b1;
      end else begin
        tx_start_in_r           <= 1'b0;
      end

      // only write new data to Rx reg when it a full word has been received
      if (rx_done_i == 1'b1) begin
        rx_reg_periph_wr_en_r <= 1'b1;
      end

    end
  end

  /* assignments **************************************************************/

  // Default/Unimplemented function assignments
  assign tx_fifo_push_o = 1'b0;
  assign rx_fifo_pop_o  = 1'b0;
  assign tx_fifo_en_o   = 1'b0;
  assign rx_fifo_en_o   = 1'b0;

  // INPUTS (Peripheral -> Reg)

  // assign fields into reg groups
  always @(*) begin

    // default assignments
    stat_reg_data_i_s = stat_reg_data_o_s;
    ctrl_reg_data_i_s = ctrl_reg_data_o_s;
    tx_reg_data_i_s   = tx_reg_data_o_s;
    rx_reg_data_i_s   = rx_reg_data_o_s;

    // route signals FROM UART
    stat_reg_data_i_s[ 0] = tx_done_i;
    stat_reg_data_i_s[ 1] = tx_busy_i;
    stat_reg_data_i_s[ 8] = tx_fifo_empty_i;
    stat_reg_data_i_s[ 9] = tx_fifo_nearly_empty_i;
    stat_reg_data_i_s[10] = tx_fifo_full_i;
    stat_reg_data_i_s[11] = tx_fifo_nearly_full_i;
    stat_reg_data_i_s[16] = rx_done_i;
    stat_reg_data_i_s[17] = rx_busy_i;
    stat_reg_data_i_s[18] = rx_parity_err_i;
    stat_reg_data_i_s[19] = rx_stop_err_i;
    stat_reg_data_i_s[24] = rx_fifo_empty_i;
    stat_reg_data_i_s[25] = rx_fifo_nearly_empty_i;
    stat_reg_data_i_s[26] = rx_fifo_full_i;
    stat_reg_data_i_s[27] = rx_fifo_nearly_full_i;

    // Manage rx full
    if (rx_done_i == 1'b1) begin
      stat_reg_data_i_s[23] = 1'b1;
    end else if (rd_en_cpu_i == 1'b1 && cpu_addr_i == UART_RX_ADDR) begin
      stat_reg_data_i_s[23] = 1'b0;
    end

    // Manage tx full
    if (tx_done_i == 1'b1) begin
      stat_reg_data_i_s[7] = 1'b0;
    end else if (wr_en_cpu_i == 1'b1 && cpu_addr_i == UART_TX_ADDR) begin
      stat_reg_data_i_s[7] = 1'b1;
    end

    ctrl_reg_data_i_s[1]  = tx_start_in_r;

    rx_reg_data_i_s[7:0] = rx_data_i;

  end

  // concat reg groups
  assign periph_data_in_s = {rx_reg_data_i_s,   tx_reg_data_i_s,
                             ctrl_reg_data_i_s, stat_reg_data_i_s};

  // OUTPUTS (Reg -> Peripheral)

  // separate periph group into register grouping
  assign {rx_reg_data_o_s,   tx_reg_data_o_s,
          ctrl_reg_data_o_s, stat_reg_data_o_s} = periph_data_out_s;

  // route signals TO UART
  assign baud_sel_o = ctrl_reg_data_o_s[31:30];
  assign tx_en_o    = ctrl_reg_data_o_s[0];
  assign tx_start_o = ctrl_reg_data_o_s[1];
  assign tx_conf_o  = ctrl_reg_data_o_s[6:2];
  assign rx_en_o    = ctrl_reg_data_o_s[16];
  assign rx_conf_o  = ctrl_reg_data_o_s[22:18];
  assign tx_data_o  = tx_reg_data_o_s[7:0];

  // Controls

  // Peripheral write enable concat
  assign wr_en_periph_s = {rx_reg_periph_wr_en_r,   tx_reg_periph_wr_en_r,
                           ctrl_reg_periph_wr_en_r, stat_reg_periph_wr_en_r};

endmodule
