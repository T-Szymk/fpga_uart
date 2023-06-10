/*------------------------------------------------------------------------------
-- Title      : FPGA UART Transmit Module
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : tx_module.v
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2023-03-11
-- Design     : baud_generator
-- Platform   : -
-- Standard   : Verilog '05
--------------------------------------------------------------------------------
-- Description: Module to perform transmission of UART data onto the uart_tx_o
--              port.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2023-03-11  1.0      TZS     Created
-- 2023-04-16  1.1      TZS     Connected tx_done_o
------------------------------------------------------------------------------*/

module tx_module #(
  parameter  unsigned MAX_DATA_WIDTH       = 8,
  parameter  unsigned DATA_COUNTER_WIDTH   = 3,
  parameter  unsigned STOP_CONF_WIDTH      = 2,
  parameter  unsigned DATA_CONF_WIDTH      = 3,
  parameter  unsigned SAMPLE_COUNTER_WIDTH = 4,
  localparam unsigned TotalConfWidth = STOP_CONF_WIDTH + DATA_CONF_WIDTH
) (
  input  wire         clk_i,
  input  wire         rst_i,
  input  wire         baud_en_i,
  input  wire         tx_en_i,
  input  wire         tx_start_i,
  input  wire [5-1:0] tx_conf_i, // {data_size[1:0], stop_size {1:0}, parity_en}
  input  wire [8-1:0] tx_data_i,

  output wire         tx_done_o,
  output wire         uart_tx_o
);

/*** TYPES/CONSTANTS/DECLARATIONS *********************************************/

  localparam reg [3-1:0] // tx fsm states
    Reset      = 3'b000,
    Idle       = 3'b001,
    SendStart  = 3'b010,
    SendData   = 3'b011,
    SendParity = 3'b100,
    SendStop   = 3'b101,
    Done       = 3'b110;

  localparam unsigned SampleCounterMax = 4'd15;

  wire sample_count_done_s;
  wire parity_bit_s;

  reg uart_tx_s;
  reg load_tx_conf_r;
  reg parity_en_r;
  reg busy_r;
  reg tx_done_r;

  reg [3-1:0] c_state_r, n_state_s;
  reg [  DATA_COUNTER_WIDTH-1:0] data_counter_r;
  reg [     STOP_CONF_WIDTH-1:0] stop_counter_r;
  reg [SAMPLE_COUNTER_WIDTH-1:0] sample_counter_r;
  reg [      MAX_DATA_WIDTH-1:0] tx_data_r;
  reg [     DATA_CONF_WIDTH-1:0] data_counter_max_r;
  reg [     STOP_CONF_WIDTH-1:0] stop_counter_max_r;

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
        if ( tx_en_i ) begin
          n_state_s = Idle;
        end
      end

      Idle       : begin                                                    /**/
        if ( (tx_start_i == 1'b1) ) begin
          n_state_s      = SendStart;
        end
      end

      SendStart  : begin                                                    /**/
        if (sample_count_done_s) begin
          n_state_s = SendData;
        end
      end

      SendData   : begin                                                    /**/
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

      SendStop   : begin                                                    /**/
        if (sample_count_done_s && (stop_counter_r == stop_counter_max_r) ) begin
          n_state_s = Done;
        end
      end

      Done       : begin                                                    /**/
        if (tx_en_i) begin
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

  always @(posedge clk_i or posedge rst_i) begin : sync_bit_counter

    if ( rst_i ) begin

      sample_counter_r <= {SAMPLE_COUNTER_WIDTH{1'b0}};
      data_counter_r   <= {DATA_COUNTER_WIDTH{1'b0}};
      stop_counter_r   <= {STOP_CONF_WIDTH{1'b0}};

    end else if ( baud_en_i ) begin

      if ( c_state_r == SendStart || c_state_r == SendData ||
           c_state_r == SendParity || c_state_r == SendStop ) begin
        sample_counter_r <= (sample_counter_r == SampleCounterMax) ? 0 : sample_counter_r + 1;
      end

      if ( sample_counter_r ==  SampleCounterMax ) begin

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
  end

/*** Busy  + Done *************************************************************/

  always @(posedge clk_i or posedge rst_i) begin : sync_busy_done

    if ( rst_i ) begin
      busy_r         <= 1'b0;
      tx_done_r      <= 1'b0;
      load_tx_conf_r <= 1'b0;
    end else if ( baud_en_i ) begin

      tx_done_r      <= 1'b0;
      load_tx_conf_r <= 1'b0;

      if ( n_state_s == SendStart ) begin
        busy_r <= 1'b1;
      end else if ( n_state_s == Done ) begin
        busy_r    <= 1'b0;
        tx_done_r <= 1'b1;
      end

      if ( n_state_s == SendStart ) begin 
        load_tx_conf_r <= 1'b1;
      end

    end
  end

  assign tx_done_o = tx_done_r;

/*** Load configuration *******************************************************/

  always @(posedge clk_i or posedge rst_i) begin : sync_tx_conf_load

    if ( rst_i ) begin
      tx_data_r          <= {MAX_DATA_WIDTH{1'b0}};
      parity_en_r        <= 1'b0;
      stop_counter_max_r <= {STOP_CONF_WIDTH{1'b0}};
      data_counter_max_r <= {DATA_CONF_WIDTH{1'b0}};
    end else begin
      if ( load_tx_conf_r ) begin
        tx_data_r          <= tx_data_i;
        parity_en_r        <= tx_conf_i[0];
        stop_counter_max_r <= tx_conf_i[2:1];
        data_counter_max_r <= 3'd4 + tx_conf_i[4:3];
      end
    end

  end

/*** Tx Data, Parity and Output ***********************************************/

  assign uart_tx_o = uart_tx_s;
  assign parity_bit_s = ^tx_data_r;

  always @(*) begin : comb_uart_tx_out

    case ( c_state_r )
      SendStart : begin
        uart_tx_s = 1'b1;
      end
      SendData : begin
        uart_tx_s = tx_data_r[data_counter_r];
      end
      SendParity : begin
        uart_tx_s = parity_bit_s;
      end
      SendStop : begin
        uart_tx_s = 1'h0;
      end
      default : begin
        uart_tx_s = 1'b0;
      end
    endcase

  end

endmodule
