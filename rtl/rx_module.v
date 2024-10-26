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
-- 2023-07-15  1.0      TZS     Created
-- 2024-10-26  1.1      TZS     Add control logic for FIFO mode
------------------------------------------------------------------------------*/
/***  DESCRIPTION ***/
//! Module to perform receipt of UART data from the uart_rx_i port.
/*----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module rx_module #(
  //! Maximum width of UART data 
  parameter MAX_UART_DATA_W = 8,
  //! Width of stop bit configuration field
  parameter STOP_CONF_W     = 2,
  //! Width of data bit configuration field
  parameter DATA_CONF_W     = 2,
  //! Width of sample counter within Tx and Rx module (sampled 16 times)
  parameter SAMPLE_COUNT_W  = 4,
  //! Total width of configuration data bits sent to Tx and Rx modules
  parameter TOTAL_CONF_W    = 5,
  //! Width of UART data counter
  parameter DATA_COUNTER_W  = 3 
) (

  input  wire                       clk_i,           //! Top clock
  input  wire                       rst_i,           //! Synchronous active-high reset
  input  wire                       baud_en_i,       //! Baud rate select signal
  input  wire                       rx_en_i,         //! Enable for Rx module
  input  wire                       uart_rx_i,       //! Synchronised external Rx input of UART
  input  wire [   TOTAL_CONF_W-1:0] rx_conf_i,       //! Rx configuration data conf {data[1:0], stop[1:0], parity_en}
  input  wire                       rx_fifo_en_i,    //! Enable for the Rx FIFO
  input  wire                       rx_fifo_full_i,  //! Rx FIFO full indication

  output wire                       rx_done_o,       //! Rx done status signal (pulsed when Rx of one character completed)
  output wire                       rx_busy_o,       //! Rx status signal to indicate Rx module is busy receiving something
  output wire                       rx_parity_err_o, //! Rx status signal indicating that a parity error was recognised in latest received data
  output wire                       rx_stop_err_o,   //! Rx status signal to indicate that a stop error was recognised in latest received data
  output wire [MAX_UART_DATA_W-1:0] rx_data_o,       //! Rx data that has been received
  output wire                       rx_fifo_push_o   //! Push controls for Rx FIFO
);

/*** CONSTANTS ****************************************************************/

  //! Rx fsm states
  localparam reg [3-1:0]
    Reset      = 3'b000,
    Idle       = 3'b001,
    RecvStart  = 3'b010,
    RecvData   = 3'b011,
    RecvParity = 3'b100,
    RecvStop   = 3'b101,
    Done       = 3'b110;
  //! Max value of symbol sample counter (16-1)
  localparam SampleCounterMax = 4'd15;
  //! Mid value of symbol sample counter used to determine when to latch sample
  localparam SampleCountMid   = 4'd7;

  /*** SIGNALS ****************************************************************/

  wire final_sample_s;
  wire last_data_sample_s;
  wire last_stop_sample_s;

  reg uart_rx_s      = 1'b0;
  reg load_rx_conf_r = 1'b0;
  reg start_r        = 1'b0;
  reg stop_r         = 1'b0;
  reg parity_r       = 1'b0;
  reg parity_en_r    = 1'b0;
  reg busy_r         = 1'b0;
  reg rx_done_r      = 1'b0;
  reg parity_error_r = 1'b0;
  reg stop_error_r   = 1'b0;
  reg rx_fifo_push_r = 1'b0;

  reg [              3-1:0] c_state_r          = {3{1'b0}}; 
  reg [              3-1:0] n_state_s          = {3{1'b0}};
  reg [ DATA_COUNTER_W-1:0] data_counter_r     = {DATA_COUNTER_W{1'b0}};
  reg [    STOP_CONF_W-1:0] stop_counter_r     = {STOP_CONF_W{1'b0}};
  reg [ SAMPLE_COUNT_W-1:0] sample_counter_r   = {SAMPLE_COUNT_W{1'b0}};
  reg [MAX_UART_DATA_W-1:0] rx_data_r          = {MAX_UART_DATA_W{1'b0}};
  reg [ DATA_COUNTER_W-1:0] data_counter_max_r = {DATA_COUNTER_W{1'b0}};
  reg [    STOP_CONF_W-1:0] stop_counter_max_r = {STOP_CONF_W{1'b0}};

  /*** RTL ********************************************************************/

  /*** ASSIGNMENTS ***/

  assign final_sample_s     = (sample_counter_r == SampleCounterMax) ? 1'b1 : 1'b0;
  assign last_data_sample_s = (final_sample_s &&
                               (data_counter_r == data_counter_max_r)) ? 1'b1 : 1'b0;
  assign last_stop_sample_s = (final_sample_s &&
                               (stop_counter_r == stop_counter_max_r)) ? 1'b1 : 1'b0;
  assign rx_done_o          = rx_done_r;
  assign rx_busy_o          = busy_r;
  assign rx_parity_err_o    = parity_error_r;
  assign rx_stop_err_o      = stop_error_r;
  assign rx_data_o          = rx_data_r;
  assign rx_fifo_push_o     = rx_fifo_push_r;

  /*** FSM ***/

  //! Synch current state assignment for Rx FSM
  always @(posedge clk_i) begin : sync_fsm_next_state

    if (rst_i) begin
      c_state_r <= Reset;
    end else if (baud_en_i) begin
      c_state_r <= n_state_s;
    end

  end

  //! Comb next state assignment for Rx FSM
  always @(*) begin : comb_fsm_next_state

    n_state_s = c_state_r;

    case(c_state_r)

      Reset : begin                                                         /**/
        if ( rx_en_i ) begin
          n_state_s = Idle;
        end
      end

      Idle : begin                                                          /**/
        if ( ~uart_rx_i ) begin
          n_state_s = RecvStart;
        end
      end

      RecvStart : begin                                                     /**/
        if ( final_sample_s) begin
          /* check if start bit value was maintained from start of sample period
             if not, assume glitch and return to idle */
          if (~start_r) begin
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
        if ( last_stop_sample_s ) begin
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

  end // comb_fsm_next_state

  /*** Bit Counters + Data capture + Parity ***/

  //! Synch capturing of Rx data
  always @(posedge clk_i) begin : sync_data_capture

    if (rst_i) begin

      sample_counter_r <= {SAMPLE_COUNT_W{1'b0}};
      data_counter_r   <= {DATA_COUNTER_W{1'b0}};
      stop_counter_r   <= {STOP_CONF_W{1'b0}};
      rx_data_r        <= {MAX_UART_DATA_W{1'b0}};
      start_r          <= 1'b0;
      stop_r           <= 1'b0;
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

      // stop checking
      if ((c_state_r == RecvStop) && final_sample_s ) begin
        stop_error_r <= (stop_r == 1'b0) ? 1'b1 : 1'b0;
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
          RecvStop : begin
            stop_r <= uart_rx_i;
          end
          default : begin
            // do nothing
          end
        endcase

      end
    end

  end // sync_data_capture

  /*** Busy  + Done ***/

  //! Synch busy and done signal generation
  always @(posedge clk_i) begin : sync_busy_done

    if (rst_i) begin
      busy_r         <= 1'b0;
      rx_done_r      <= 1'b0;
      load_rx_conf_r <= 1'b0;
      rx_fifo_push_r <= 1'b0;
    end else begin

      rx_done_r      <= 1'b0;
      load_rx_conf_r <= 1'b0;
      rx_fifo_push_r <= 1'b0;

      if ( baud_en_i ) begin

        if ( n_state_s == RecvStart ) begin
          busy_r    <= 1'b1;
        end else if ( n_state_s == Done ) begin
          busy_r    <= 1'b0;
          rx_done_r <= 1'b1; // rx_done high for 1 cycle
        end

        // load configuration data whenever moving receive start
        if ( c_state_r == Idle && n_state_s == RecvStart ) begin
          load_rx_conf_r <= 1'b1;
        end

        // only push to FIFO when stop has been received and FIFO has been
        // enabled/has room. Note that the data is still read from the line when
        // the FIFO is full, because it is possible to read out of the FIFO mid- 
        // way through receiving data
        if ( c_state_r == RecvStop && n_state_s == Done ) begin
          if ( ~rx_fifo_full_i  && rx_fifo_en_i ) begin
            rx_fifo_push_r <= 1'b1;
          end
        end
      end
    end

  end // sync_busy_done

  /*** Load configuration ***/

  //! Synch latching of configuration inputs 
  always @(posedge clk_i) begin : sync_rx_conf_load

    if (rst_i) begin
      parity_en_r        <= 1'b0;
      stop_counter_max_r <= {STOP_CONF_W{1'b0}};
      data_counter_max_r <= {DATA_COUNTER_W{1'b0}};
    end else begin
      if (load_rx_conf_r) begin
        parity_en_r        <= rx_conf_i[0];
        stop_counter_max_r <= rx_conf_i[2:1];
        data_counter_max_r <= 3'd4 + rx_conf_i[4:3];
      end
    end

  end // sync_rx_conf_load

endmodule // rx_module
