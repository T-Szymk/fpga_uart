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
------------------------------------------------------------------------------*/

module tx_module (
  input  wire         clk_i,
  input  wire         rst_i,
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

  reg c_state_r, n_state_s;

/*** FSM **********************************************************************/

  always @(*) begin : comb_fsm_next_state
    case(c_state_r)
      Reset      : begin 
      end
      Idle       : begin 
      end
      SendStart  : begin 
      end
      SendData   : begin 
      end
      SendParity : begin 
      end
      SendStop   : begin 
      end
      Done       : begin 
      end
      default    : begin 
      end
    endcase
  end

  always @(posedge clk_i or negedge rst_i) begin : sync_fsm_next_state
    if ( ~rst_i ) begin 
      c_state_r <= 3'b000;
    end else begin 
      c_state_r <= n_state_s;
    end
  end

endmodule
