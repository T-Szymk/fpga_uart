/*------------------------------------------------------------------------------
-- Title      : FPGA UART Transmit Module
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : tx_module.v
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2023-03-11
-- Design     : tx_module
-- Platform   : -
-- Standard   : Verilog '05
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2023-07-15  1.0      TZS     Created
-- 2024-08-24  1.1      TZS     Add control logic for FIFO mode
------------------------------------------------------------------------------*/
/*** DESCRIPTION ***/
//! Module to perform transmission of UART data onto the uart_tx_o port.
/*----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module tx_module #(
  //! Maximum width of UART data
  parameter MAX_UART_DATA_W = 8, // max possible data width
  //! Width of stop bit configuration field
  parameter STOP_CONF_W     = 2,
  //! Width of data bit configuration field
  parameter DATA_CONF_W     = 2,
  //! Width of sample counter within Tx and Rx module (sampled 16 times)
  parameter SAMPLE_COUNT_W  = 4,
  //! Width of UART data counter
  parameter DATA_COUNTER_W  = 3,
  //! Total width of configuration data bits sent to Tx and Rx modules
  parameter TOTAL_CONF_W    = STOP_CONF_W + DATA_CONF_W + 1
) (
  input  wire                       clk_i,        //! Top clock      
  input  wire                       rst_i,        //! Synchronous active-high reset        
  input  wire                       baud_en_i,    //! Baud rate select signal          
  input  wire                       tx_en_i,      //! Enable for Tx module      
  input  wire                       tx_start_i,   //! Start signal to initiate transmission of data         
  input  wire [   TOTAL_CONF_W-1:0] tx_conf_i,    //! Tx configuration data conf {data[1:0], stop[1:0], parity_en}           
  input  wire [MAX_UART_DATA_W-1:0] tx_data_i,    //! Tx data to be transmitted
  input  wire                       tx_fifo_en_i, //! Enable for the Tx FIFO

  output wire                       tx_done_o,    //! Tx done status signal (pulsed when Tx of one character completed) 
  output wire                       tx_busy_o,    //! Tx status signal to indicate Tx module is busy sending something  
  output wire                       uart_tx_o,    //! External Tx output of UART
  output wire                       tx_fifo_pop_o //! Pop control for Tx FIFO
);

  /*** CONSTANTS **************************************************************/

  //! Rx fsm states
  localparam reg [3-1:0] 
    Reset      = 3'b000,
    Idle       = 3'b001,
    SendStart  = 3'b010,
    SendData   = 3'b011,
    SendParity = 3'b100,
    SendStop   = 3'b101,
    Done       = 3'b110;

  //! Max value of symbol sample counter (16-1)
  localparam SampleCounterMax = 4'd15;

  /*** SIGNALS ****************************************************************/

  wire sample_count_done_s;
  wire parity_bit_s;

  reg uart_tx_s      = 1'b0;
  reg load_tx_conf_r = 1'b0;
  reg parity_en_r    = 1'b0;
  reg busy_r         = 1'b0;
  reg tx_done_r      = 1'b0;
  reg tx_fifo_pop_s  = 1'b0;

  reg [              3-1:0] c_state_r          = {3{1'b0}}; 
  reg [              3-1:0] n_state_s          = {3{1'b0}};
  reg [ DATA_COUNTER_W-1:0] data_counter_r     = {DATA_COUNTER_W{1'b0}};
  reg [    STOP_CONF_W-1:0] stop_counter_r     = {STOP_CONF_W{1'b0}};
  reg [ SAMPLE_COUNT_W-1:0] sample_counter_r   = {SAMPLE_COUNT_W{1'b0}};
  reg [MAX_UART_DATA_W-1:0] tx_data_r          = {MAX_UART_DATA_W{1'b0}};
  reg [ DATA_COUNTER_W-1:0] data_counter_max_r = {DATA_COUNTER_W{1'b0}};
  reg [    STOP_CONF_W-1:0] stop_counter_max_r = {STOP_CONF_W{1'b0}};

  /*** RTL ********************************************************************/

  /*** ASSIGNMENTS ***/

  assign tx_done_o           = tx_done_r;
  assign tx_busy_o           = busy_r;
  assign uart_tx_o           = uart_tx_s;
  assign parity_bit_s        = ^tx_data_r; 
  assign sample_count_done_s = (sample_counter_r == SampleCounterMax) ? 1'b1 : 1'b0; 
  assign tx_fifo_pop_o       = tx_fifo_pop_s;

  /*** FSM ***/

  //! Synch current state assignment for Tx FSM
  always @(posedge clk_i) begin : sync_fsm_next_state

    if (rst_i) begin
      c_state_r <= Reset;
    end else if (baud_en_i) begin
      c_state_r <= n_state_s;
    end

  end

  //! Comb next state assignment for Tx FSM
  always @(*) begin : comb_fsm_next_state

    // default assignments
    n_state_s     = c_state_r;
    tx_fifo_pop_s = 1'b0;

    case(c_state_r)

      Reset : begin                                                         /**/
        if ( tx_en_i ) begin
          n_state_s = Idle;
        end
      end

      Idle : begin                                                          /**/
        if ( (tx_start_i == 1'b1) ) begin
          n_state_s      = SendStart;
          tx_fifo_pop_s  = 1'b1;
        end
      end

      SendStart : begin                                                     /**/
        if (sample_count_done_s) begin
          n_state_s = SendData;
        end
      end

      SendData : begin                                                      /**/
        if (sample_count_done_s && (data_counter_r == data_counter_max_r) ) begin
          if (parity_en_r) begin
            n_state_s = SendParity;
          end else begin
            n_state_s = SendStop;
          end
        end
      end

      SendParity : begin                                                    /**/
        if (sample_count_done_s) begin
          n_state_s = SendStop;
        end
      end

      SendStop : begin                                                      /**/
        if (sample_count_done_s && (stop_counter_r == stop_counter_max_r) ) begin
          n_state_s = Done;
        end
      end

      Done : begin                                                          /**/
        if (tx_en_i) begin
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

 /*** Bit Counters ***/  

  //! Synch management of output data counters    
  always @(posedge clk_i) begin : sync_data_send

    if ( rst_i ) begin

      sample_counter_r <= {SAMPLE_COUNT_W{1'b0}};
      data_counter_r   <= {DATA_COUNTER_W{1'b0}};
      stop_counter_r   <= {STOP_CONF_W{1'b0}};

    end else if ( baud_en_i ) begin

      if ( c_state_r == SendStart || c_state_r == SendData ||
           c_state_r == SendParity || c_state_r == SendStop ) begin

        sample_counter_r <= (sample_counter_r == SampleCounterMax) ? 0 : sample_counter_r + 1;
      
      end

      if (sample_counter_r ==  SampleCounterMax) begin

        case ( c_state_r )
          SendData : begin
            data_counter_r <= (data_counter_r == data_counter_max_r) ? 0 : data_counter_r + 1;
          end
          SendStop : begin
            stop_counter_r <= (stop_counter_r == stop_counter_max_r) ? 0 : stop_counter_r + 1;
          end
          default : begin
            data_counter_r <= 0;
            stop_counter_r <= 0;
          end
        endcase
      end
    end

  end // sync_data_send

  /*** Busy  + Done ***/

  //! Synch busy and done signal generation
  always @(posedge clk_i) begin : sync_busy_done

    if ( rst_i ) begin
      busy_r         <= 1'b0;
      tx_done_r      <= 1'b0;
      load_tx_conf_r <= 1'b0;
    end else if ( baud_en_i ) begin

      tx_done_r      <= 1'b0;
      load_tx_conf_r <= 1'b0;

      if (n_state_s == SendStart) begin
        busy_r <= 1'b1;
      end else if (n_state_s == Done) begin
        busy_r    <= 1'b0;
        tx_done_r <= 1'b1;
      end

      if (n_state_s == SendStart) begin 
        load_tx_conf_r <= 1'b1;
      end
    end

  end // sync_busy_done  

  /*** Load configuration ***/

  //! Synch latching of configuration inputs 
  always @(posedge clk_i) begin : sync_tx_conf_load

    if ( rst_i ) begin
      tx_data_r          <= {MAX_UART_DATA_W{1'b0}};
      parity_en_r        <= 1'b0;
      stop_counter_max_r <= {STOP_CONF_W{1'b0}};
      data_counter_max_r <= {DATA_COUNTER_W{1'b0}};
    end else begin
      if ( load_tx_conf_r ) begin
        tx_data_r          <= tx_data_i;
        parity_en_r        <= tx_conf_i[0];
        stop_counter_max_r <= tx_conf_i[2:1];
        data_counter_max_r <= 3'd4 + tx_conf_i[4:3];
      end
    end

  end // sync_tx_conf_load

  /*** Tx Data, Parity and Output ***/

  //! Comb assignment of UART Tx signal values
  always @(*) begin : comb_uart_tx_out

    case ( c_state_r )
      SendStart : begin
        uart_tx_s = 1'b0;
      end
      SendData : begin
        uart_tx_s = tx_data_r[data_counter_r];
      end
      SendParity : begin
        uart_tx_s = parity_bit_s;
      end
      SendStop : begin
        uart_tx_s = 1'h1;
      end
      default : begin
        uart_tx_s = 1'b1;
      end
    endcase

  end // comb_uart_tx_out

endmodule
