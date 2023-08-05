/*------------------------------------------------------------------------------
-- Title      : Testbench for FPGA UART Controller
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : tb_uart_controller.sv
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2023-08-05
-- Design     : tb_uart_controller
-- Platform   : -
-- Standard   : SystemVerilog '17
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2023-08-05  1.0      TZS     Created
------------------------------------------------------------------------------*/
/*** DESCRIPTION ***/
/*
Test cases covered:
- loopback test (rx/tx tied)
- asynchronous communication (tx and rx running at different frequencies with the same Baud Rate)
- tests at each baud rate
- each data/stop length value covered
- tx parity checking tested
- start/stop/parity error checks
- test over reset
- baudrate monitoring 
- partial transmission + recovery testing
*/
/*----------------------------------------------------------------------------*/

module tb_uart_controller;

  timeunit 1ns/1ps;  

  

endmodule // tb_uart_controller
