/*------------------------------------------------------------------------------
-- Title      : Testbench for FPGA UART FIFO
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : tb_fifo.sv
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2024-08-03
-- Design     : tb_fifo
-- Platform   : -
-- Standard   : SystemVerilog '17
--------------------------------------------------------------------------------
-- Description: Testbench to test standalone fifo
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2024-08-03  1.0      TZS     Created
------------------------------------------------------------------------------*/

module tb_fifo;

  timeunit 1ns/1ps;
   
  parameter time         CLK_PERIOD_NS = 10ns;
  parameter time         TB_RUNTIME    = 100us;
  parameter int unsigned FIFO_WIDTH    = 8;
  parameter int unsigned FIFO_DEPTH    = 4;
   
  bit tb_clk, tb_rst;
  bit tb_push, tb_pop;
  bit tb_full, tb_empty, tb_nearly_full, tb_nearly_empty;
  
  bit [FIFO_WIDTH-1:0] tb_data_in, tb_data_out;

  fifo #(
    .WIDTH          ( FIFO_WIDTH      ),
    .DEPTH          ( FIFO_DEPTH      )
  ) i_dut (
    .clk_i          ( tb_clk          ),
    .rst_i          ( tb_rst          ),
    .push_i         ( tb_push         ),
    .pop_i          ( tb_pop          ),
    .data_i         ( tb_data_in      ),
    .data_o         ( tb_data_out     ),
    .full_o         ( tb_full         ),
    .empty_o        ( tb_empty        ),
    .nearly_full_o  ( tb_nearly_full  ),
    .nearly_empty_o ( tb_nearly_empty )
  );

  // clock gen
  initial begin
    tb_clk = 1'b0;
    forever begin
      #CLK_PERIOD_NS;
      tb_clk = ~tb_clk;
    end
  end

  // reset gen
  initial begin
    tb_rst = 1'b1;
    #(5*CLK_PERIOD_NS);
    @(posedge tb_clk);
    tb_rst = 1'b0;
  end

  // tb runtime check
  initial begin
    #(TB_RUNTIME);
    $finish();
  end

  // tb logic
  initial begin

    automatic bit success;

    $display("FIFO TB, DEPTH = %0d, WIDTH = %0d", FIFO_DEPTH, FIFO_WIDTH);

    tb_push = 1'b0;
    tb_pop  = 1'b0;
    success = std::randomize(tb_data_in);

    @(negedge tb_rst);

    repeat(5)
      @(negedge tb_clk);

    while(!tb_full) begin
      tb_push = 1'b1;
      success = std::randomize(tb_data_in);
      $display("%0tns - Pushed %04H", $time, tb_data_in);
      @(negedge tb_clk);
    end

    tb_push = 1'b0;

    tb_pop  = 1'b1;

    while(!tb_empty) begin
      @(negedge tb_clk);
      tb_pop = 1'b1;
      $display("%0tns - Popped %04H", $time, tb_data_out);      
    end

    @(negedge tb_clk);
    $finish();

  end

endmodule
