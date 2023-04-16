/*------------------------------------------------------------------------------
-- Title      : FPGA UART Receive Module
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : rx_module.v
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2023-04-16
-- Design     : baud_generator
-- Platform   : -
-- Standard   : Verilog '05
--------------------------------------------------------------------------------
-- Description: Module to perform receipt of UART data from the uart_rx_i
--              port.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2023-04-16  1.0      TZS     Created
------------------------------------------------------------------------------*/

module rx_module (

  input  wire         clk_i,
  input  wire         rst_i,
  input  wire         baud_en_i,
  input  wire         rx_en_i,
  input  wire         uart_rx_i,
  input  wire [5-1:0] rx_conf_i,

  output wire         rx_done_o,
  output wire         parity_error_o,
  output wire [8-1:0] rx_data_o
);

/*** TYPES/CONSTANTS/DECLARATIONS *********************************************/

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

  wire sample_count_done_s;
  wire last_data_sample_s;

  reg uart_rx_s;
  reg load_rx_conf_r;
  reg parity_r;
  reg parity_en_r;
  reg busy_r;
  reg rx_done_r;

  reg [3-1:0] c_state_r, n_state_s;
  reg [3-1:0] data_counter_r;
  reg [2-1:0] stop_counter_r;
  reg [4-1:0] sample_counter_r;
  reg [8-1:0] rx_data_r;
  reg [2-1:0] rx_stop_r;
  reg [3-1:0] data_counter_max_r;
  reg [2-1:0] stop_counter_max_r;

/*** FSM **********************************************************************/

  always @(posedge clk_i or posedge rst_i) begin : sync_fsm_next_state
    if ( rst_i ) begin
      c_state_r <= Reset;
    end else if ( baud_en_i ) begin
      c_state_r <= n_state_s;
    end
  end

  always @(*) begin : comb_fsm_next_state

    n_state_s      = c_state_r;

    case(c_state_r)

      Reset      : begin                                                    /**/
        if ( rx_en_i ) begin
          n_state_s = Idle;
        end
      end

      Idle       : begin                                                    /**/
        if ( uart_rx_i ) begin
          n_state_s      = RecvStart;
        end
      end

      RecvStart  : begin                                                    /**/
        if ( sample_count_done_s ) begin 
          n_state_s = RecvData;
        end
      end

      RecvData   : begin                                                    /**/
        if ( last_data_sample_s ) begin
          n_state_s = (parity_en_r) ? RecvParity : RecvStop;
        end
      end

      RecvParity : begin                                                    /**/
        if ( sample_counter_r == SampleCounterMax ) begin
          n_state_s = RecvStop;
        end
      end

      RecvStop   : begin                                                    /**/
        if ( sample_counter_r == SampleCounterMax ) begin
          n_state_s = RecvStop;
        end
      end

      Done       : begin                                                    /**/
        if ( rx_en_i ) begin
          n_state_s = Idle;
        end else begin 
          n_state_s = Reset;
        end
      end

      default    : begin                                                    /**/
        n_state_s = Reset;
      end

    endcase
  end

/*** Bit Counters *************************************************************/

  assign sample_count_done_s = (sample_counter_r == SampleCounterMax) ? 1'b1 : 1'b0;
  assign last_data_sample_s  = ((sample_counter_r == SampleCounterMax) &&
                                (data_counter_r == data_counter_max_r)) ? 1'b1 : 1'b0;

  always @(posedge clk_i or posedge rst_i) begin : sync_bit_counter

    if ( rst_i ) begin

      sample_counter_r <= 0;
      data_counter_r   <= 0;
      stop_counter_r   <= 0;

    end else if ( baud_en_i ) begin

      if ( c_state_r == RecvStart || c_state_r == RecvData ||
           c_state_r == RecvParity || c_state_r == RecvStop ) begin 
        sample_counter_r <= (sample_counter_r == SampleCounterMax) ? 0 : sample_counter_r + 1;
      end

      if ( sample_counter_r ==  SampleCounterMax ) begin

        case ( c_state_r )
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

      end
    end
  end

/*** Busy  + Done *************************************************************/

  always @(posedge clk_i or posedge rst_i) begin 

    if ( rst_i ) begin
      busy_r         <= 1'b0;
      rx_done_r      <= 1'b0;
      load_rx_conf_r <= 1'b0;
    end else if ( baud_en_i ) begin

      rx_done_r      <= 1'b0;
      load_rx_conf_r <= 1'b0;

      if ( n_state_s == RecvStart ) begin
        busy_r <= 1'b1;
      end else if ( n_state_s == Done ) begin
        busy_r    <= 1'b0;
        rx_done_r <= 1'b1;
      end

      if ( c_state_r == Reset && n_state_s == Idle ) begin
        load_rx_conf_r <= 1'b1;
      end

    end
  end

  assign rx_done_o = rx_done_r;

endmodule // rx_module
