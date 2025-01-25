/*------------------------------------------------------------------------------
-- Title      : FPGA UART Edge Detector
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : edge_detector.v
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2025-01-25
-- Design     : edge_detector
-- Platform   : -
-- Standard   : Verilog '05
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2025-01-25  1.0      TZS     Created
------------------------------------------------------------------------------*/
/***  DESCRIPTION ***/
//! Generic edge detector. Can be configured to detect a rising or falling edge
//! Output is pulsed for one cycle if edge is detected
/*----------------------------------------------------------------------------*/

`timescale 1ns/1ps

module edge_detector #(
  parameter RISING_nFALLING_EDGE = 1  //! > 0 is rising edge detect, 
) (
  input  wire clk_i,                  //! Top clock
  input  wire rst_i,                  //! Synchronous active-high reset

  input  wire data_i,                 //! Monitored signal

  output wire edge_o,                 //! Edge detect output, default lo, pulsed high when edge is detected
  output wire edge_n_o                //! Edge detect output, default hi, pulsed lo when edge is detected
);

  /* Signals ******************************************************************/

  reg data_r;

  /* Logic ********************************************************************/

  always @(posedge clk_i) begin
    if (rst_i) begin
      data_r <= 1'b0;
    end else begin
      data_r <= data_i;
    end
  end

  generate
    if (RISING_nFALLING_EDGE == 0) begin : gen_negedge_detect

      assign edge_o = (data_i == 1'b0 && data_r == 1'b1) ? 1'b1 : 1'b0;
      assign edge_n_o = ~edge_n_o;


    end else begin : gen_posedge_detect

      assign edge_o = (data_i == 1'b1 && data_r == 1'b0) ? 1'b1 : 1'b0;
      assign edge_n_o = ~edge_n_o;

    end
  endgenerate

endmodule
