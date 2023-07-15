/*------------------------------------------------------------------------------
-- Title      : FPGA UART Receive Module
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : rx_module.v
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2023-04-16
-- Design     : rx_module
-- Platform   : -
-- Standard   : Verilog '05
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2023-04-16  1.0      TZS     Created
------------------------------------------------------------------------------*/
/***  DESCRIPTION ***/
//! Module to perform receipt of UART data from the uart_rx_i port.
//!
//! ToDo: Add stop error signal.
/*----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module rx_module #(
  parameter  unsigned MAX_UART_DATA_W      = 8, // max possible data width
  parameter  unsigned STOP_CONF_WIDTH      = 2,
  parameter  unsigned DATA_CONF_WIDTH      = 2,
  parameter  unsigned SAMPLE_COUNTER_WIDTH = 4,
  parameter  unsigned TOTAL_CONF_WIDTH     = 5,
  // locals
  localparam unsigned DataCounterWidth = $clog2(MAX_UART_DATA_W)
) (

  input  wire                        clk_i,
  input  wire                        rst_i,
  input  wire                        baud_en_i,
  input  wire                        rx_en_i,
  input  wire                        uart_rx_i,
  input  wire [TOTAL_CONF_WIDTH-1:0] rx_conf_i, //! {data[1:0], stop[1:0], parity_en}

  output wire                        rx_done_o,
  output wire                        rx_busy_o,
  output wire                        rx_parity_err_o,
  output wire [ MAX_UART_DATA_W-1:0] rx_data_o
);

/*** CONSTANTS ****************************************************************/

  localparam reg [3-1:0] // rx fsm states
    Reset      = 3'b000,
    Idle       = 3'b001,
    RecvStart  = 3'b010,
    RecvData   = 3'b011,
    RecvParity = 3'b100,
    RecvStop   = 3'b101,
    Done       = 3'b110;

  localparam unsigned SampleCounterMax = 4'd15;
  localparam unsigned SampleCountMid   = 4'd7;

  /*** SIGNALS ****************************************************************/

  wire final_sample_s;
  wire last_data_sample_s;

  reg uart_rx_s;
  reg load_rx_conf_r;
  reg start_r;
  reg parity_r;
  reg parity_en_r;
  reg busy_r;
  reg rx_done_r;
  reg parity_error_r;

  reg [                   3-1:0] c_state_r, n_state_s;
  reg [    DataCounterWidth-1:0] data_counter_r;
  reg [     STOP_CONF_WIDTH-1:0] stop_counter_r;
  reg [SAMPLE_COUNTER_WIDTH-1:0] sample_counter_r;
  reg [     MAX_UART_DATA_W-1:0] rx_data_r;
  reg [    DataCounterWidth-1:0] data_counter_max_r;
  reg [     STOP_CONF_WIDTH-1:0] stop_counter_max_r;

  /*** RTL ********************************************************************/

  /*** FSM ***/

  always @(posedge clk_i or posedge rst_i) begin : sync_fsm_next_state
    if ( rst_i ) begin
      c_state_r <= Reset;
    end else if ( baud_en_i ) begin
      c_state_r <= n_state_s;
    end
  end

  always @(*) begin : comb_fsm_next_state

    n_state_s = c_state_r;

    case(c_state_r)

      Reset : begin                                                         /**/
        if ( rx_en_i ) begin
          n_state_s = Idle;
        end
      end

      Idle : begin                                                          /**/
        if ( uart_rx_i ) begin
          n_state_s = RecvStart;
        end
      end

      RecvStart : begin                                                     /**/
        if ( final_sample_s) begin
          /* check if start bit value was maintained throughout sample period
             if not, assume glitch and return to idle */
          if (start_r) begin
            n_state_s = RecvData;
          end else begin 
            n_state_s = Idle;
          end
        end
      end

      RecvData : begin                                                      /**/
        if ( last_data_sample_s ) begin
          if (parity_en_r) begin
            n_state_s = RecvParity;
          end else begin
            n_state_s = RecvStop;
          end
        end
      end

      RecvParity : begin                                                    /**/
        if ( final_sample_s ) begin
          n_state_s = RecvStop;
        end
      end

      RecvStop : begin                                                      /**/
        if ( final_sample_s ) begin
          n_state_s = Done;
        end
      end

      Done : begin                                                          /**/
        if ( rx_en_i ) begin
          n_state_s = Idle;
        end else begin
          n_state_s = Reset;
        end
      end

      default : begin                                                       /**/
        n_state_s = Reset;
      end

    endcase
  end

  /*** Bit Counters + Data capture + Parity ***/

  assign final_sample_s     = (sample_counter_r == SampleCounterMax) ? 1'b1 : 1'b0;
  assign last_data_sample_s = ((sample_counter_r == SampleCounterMax) &&
                               (data_counter_r == data_counter_max_r)) ? 1'b1 : 1'b0;

  always @(posedge clk_i or posedge rst_i) begin : sync_bit_counter

    if ( rst_i ) begin

      sample_counter_r <= {SAMPLE_COUNTER_WIDTH{1'b0}};
      data_counter_r   <= {DataCounterWidth{1'b0}};
      stop_counter_r   <= {STOP_CONF_WIDTH{1'b0}};
      rx_data_r        <= {MAX_UART_DATA_W{1'b0}};
      start_r          <= 1'b0;
      parity_r         <= 1'b0;
      parity_error_r   <= 1'b0;

    end else if (baud_en_i) begin

      // increment sample counter values with each tick of baud clk (clk_i)
      if (c_state_r == RecvStart  || c_state_r == RecvData ||
          c_state_r == RecvParity || c_state_r == RecvStop) begin
        sample_counter_r <= (sample_counter_r == SampleCounterMax) ? 0 : sample_counter_r + 1;
      end

      // parity checking
      if (parity_en_r) begin
        if ( (c_state_r == RecvParity) && final_sample_s ) begin
          // parity error remains high until next correct message is received while parity enabled
          parity_error_r <= (parity_r == (^rx_data_r)) ? 1'b0 : 1'b1;
        end
      end else begin
        parity_error_r <= 1'b0;
      end

      // manage bit counter values at final sample of each bit
      if ( final_sample_s ) begin

        case (c_state_r)
          RecvData : begin
            data_counter_r <= (data_counter_r == data_counter_max_r) ? 0 : data_counter_r + 1;
          end
          RecvStop : begin
            stop_counter_r <= (stop_counter_r == stop_counter_max_r) ? 0 : stop_counter_r + 1;
          end
          default : begin
            data_counter_r <= 0;
            stop_counter_r <= 0;
          end
        endcase

      // sample RX line when at midpoint of bit
      end else if (sample_counter_r == SampleCountMid) begin

        case ( c_state_r )
          Reset : begin
            rx_data_r <= {MAX_UART_DATA_W{1'b0}};
            parity_r  <= 1'b0;
          end
          RecvStart : begin
            start_r <= uart_rx_i;
          end
          RecvData : begin
            rx_data_r[data_counter_r] <= uart_rx_i;
          end
          RecvParity : begin
            parity_r <= uart_rx_i;
          end
          default : begin
            // do nothing
          end
        endcase

      end
    end
  end

  /*** Busy  + Done ***/

  always @(posedge clk_i or posedge rst_i) begin : sync_busy_done

    if (rst_i) begin
      busy_r         <= 1'b0;
      rx_done_r      <= 1'b0;
      load_rx_conf_r <= 1'b0;
    end else if (baud_en_i) begin

      rx_done_r      <= 1'b0;
      load_rx_conf_r <= 1'b0;

      if (n_state_s == RecvStart) begin
        busy_r    <= 1'b1;
      end else if (n_state_s == Done) begin
        busy_r    <= 1'b0;
        rx_done_r <= 1'b1; // rx_done high for 1 clk period
      end
      // load configuration data whenever moving into or staying in idle
      if (n_state_s == Idle) begin
        load_rx_conf_r <= 1'b1;
      end

    end
  end

  assign rx_done_o       = rx_done_r;
  assign rx_busy_o       = busy_r;
  assign rx_parity_err_o = parity_error_r;

  /*** Load configuration ***/

  always @(posedge clk_i or posedge rst_i) begin : sync_rx_conf_load

    if (rst_i) begin
      parity_en_r        <= 1'b0;
      stop_counter_max_r <= {STOP_CONF_WIDTH{1'b0}};
      data_counter_max_r <= {DataCounterWidth{1'b0}};
    end else begin
      if (load_rx_conf_r) begin
        parity_en_r        <= rx_conf_i[0];
        stop_counter_max_r <= rx_conf_i[2:1];
        data_counter_max_r <= 3'd4 + rx_conf_i[4:3];
      end
    end

  end

endmodule // rx_module
