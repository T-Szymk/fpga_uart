/*------------------------------------------------------------------------------
-- Title      : Testbench for FPGA UART Top
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : tb_uart_top.sv
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2025-01-24
-- Design     : tb_uart_top
-- Platform   : -
-- Standard   : SystemVerilog '17
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2025-01-24  1.0      TZS     Created
--------------------------------------------------------------------------------
*** DESCRIPTION ***
//! Top testbench for the FPGA UART module. UART is in a loopback configuration.
//! Test bench configures the peripheral,drives tx data and asynchronously performs
//! checks using received data.
/*----------------------------------------------------------------------------*/

module tb_uart_top;

  timeunit 1ns/1ps;

  /* Constants and TB params **************************************************/

  parameter time             CLOCK_PERIOD     = 20ns;
  parameter realtime         TEST_RUNTIME     = 10ms;
  parameter integer unsigned TOP_CLK_FREQ_HZ  = 50_000_000;

  localparam int unsigned CPUAddrWidth  = 2;
  localparam int unsigned CPUDataWidth  = 32;

  localparam int unsigned StopCfgWidth  = 2;
  localparam int unsigned DataCfgWidth  = 2;
  localparam int unsigned BaudSelWidth  = 2;
  localparam int unsigned TotalCfgWidth = StopCfgWidth + DataCfgWidth + 1;

  localparam int unsigned UartStatusAddr  = 0;
  localparam int unsigned UartControlAddr = 1;
  localparam int unsigned UartTxAddr      = 2;
  localparam int unsigned UartRxAddr      = 3;

  localparam int unsigned TxDoneIdx        =  0;
  localparam int unsigned TxBusyIdx        =  1;
  localparam int unsigned RxDoneIdx        = 16;
  localparam int unsigned RxBusyIdx        = 17;

  localparam int unsigned TxEnableIdx      =  0;
  localparam int unsigned TxStartIdx       =  1;
  localparam int unsigned TxParityIdx      =  2;
  localparam int unsigned TxStopWidthIdxLo =  3;
  localparam int unsigned TxStopWidthIdxHi =  4;
  localparam int unsigned TxDataWidthIdxLo =  5;
  localparam int unsigned TxDataWidthIdxHi =  6;
  localparam int unsigned RxEnableIdx      = 16;
  localparam int unsigned RxStartIdx       = 17;
  localparam int unsigned RxParityIdx      = 18;
  localparam int unsigned RxStopWidthIdxLo = 19;
  localparam int unsigned RxStopWidthIdxHi = 20;
  localparam int unsigned RxDataWidthIdxLo = 21;
  localparam int unsigned RxDataWidthIdxHi = 22;
  localparam int unsigned BaudSelectIdxLo  = 30;
  localparam int unsigned BaudSelectIdxHi  = 31;

  localparam int unsigned TxDataIdxLo      =  0;
  localparam int unsigned TxDataIdxHi      =  8;

  localparam int unsigned RxDataIdxLo      =  0;
  localparam int unsigned RxDataIdxHi      =  8;

  localparam int unsigned StopWidthMax = 3;
  localparam int unsigned StopWidthMin = 1;
  localparam int unsigned DataWidthMax = 8;
  localparam int unsigned DataWidthMin = 5;

  /* Signals and Types ********************************************************/

  typedef bit [CPUAddrWidth-1:0] cpu_addr_t;
  typedef bit [CPUDataWidth-1:0] cpu_data_t;
  typedef bit [DataWidthMax-1:0] uart_data_t;

  typedef enum bit [BaudSelWidth-1:0] {
    BAUD9600   = 'd0,
    BAUD19200  = 'd1,
    BAUD115200 = 'd2,
    BAUD256000 = 'd3
  } baud_rate_e;

  typedef enum bit {
    PARITY_ENABLE  = 1'b1,
    PARITY_DISABLE = 1'b0
  } parity_e;

  typedef enum bit[StopCfgWidth-1:0] {
    STOP_1_BIT = 'd0,
    STOP_2_BIT = 'd1,
    STOP_3_BIT = 'd2
  } stop_width_e;

  typedef enum bit[DataCfgWidth-1:0] {
    DATA_5_BIT = 'd0,
    DATA_6_BIT = 'd1,
    DATA_7_BIT = 'd2,
    DATA_8_BIT = 'd3
  } data_width_e;

  typedef struct {
    parity_e     tx_parity_en;
    stop_width_e tx_stop_width;
    data_width_e tx_data_width;
    parity_e     rx_parity_en;
    stop_width_e rx_stop_width;
    data_width_e rx_data_width;
    baud_rate_e  baud_rate;
  } uart_cfg_t;

  bit tb_clk, tb_rst;

  wire                    dut_uart_rx_i_s;
  wire                    dut_uart_tx_o_s;
  wire                    dut_wr_en_cpu_i_s;
  wire                    dut_rd_en_cpu_i_s;
  wire [CPUAddrWidth-1:0] dut_cpu_addr_i_s;
  wire [CPUDataWidth-1:0] dut_cpu_data_i_s;
  wire [CPUDataWidth-1:0] dut_cpu_data_o_s;

  bit                     uart_rx;
  bit                     uart_tx;
  bit                     wr_en_cpu;
  bit                     rd_en_cpu;
  cpu_addr_t              cpu_addr;
  cpu_data_t              cpu_din;
  cpu_data_t              cpu_dout;

  /* Assignments **************************************************************/

  assign dut_uart_rx_i_s   = uart_rx;
  assign uart_tx           = dut_uart_tx_o_s;
  assign dut_wr_en_cpu_i_s = wr_en_cpu;
  assign dut_rd_en_cpu_i_s = rd_en_cpu;
  assign dut_cpu_addr_i_s  = cpu_addr;
  assign dut_cpu_data_i_s  = cpu_din;
  assign cpu_dout          = dut_cpu_data_o_s;

  assign uart_rx = uart_tx;

  /* System Configuration *****************************************************/

  initial begin

    $dumpfile("tb_uart_top.vcd");
    $dumpvars;

  `ifndef VERILATOR
    $timeformat(-9, 0, " ns");
  `endif

  end

  /* Clock and reset generation ***********************************************/

  initial begin
    tb_clk = 1'b0;
    forever begin
      #(CLOCK_PERIOD/2) tb_clk = ~tb_clk;
    end
  end

  initial begin
    tb_rst = 1'b1;
    repeat(5) begin
      @(negedge tb_clk);
    end
    tb_rst = 1'b0;
  end

  /* DUT **********************************************************************/

  uart_top #(
    .TOP_CLK_FREQ_HZ ( TOP_CLK_FREQ_HZ )
  ) i_dut (
    .clk_i       ( tb_clk            ),
    .rst_i       ( tb_rst            ),
    .uart_rx_i   ( dut_uart_rx_i_s   ),
    .uart_tx_o   ( dut_uart_tx_o_s   ),
    .wr_en_cpu_i ( dut_wr_en_cpu_i_s ),
    .rd_en_cpu_i ( dut_rd_en_cpu_i_s ),
    .cpu_addr_i  ( dut_cpu_addr_i_s  ),
    .cpu_data_i  ( dut_cpu_data_i_s  ),
    .cpu_data_o  ( dut_cpu_data_o_s  )
  );

  /* TB Logic *****************************************************************/

  initial begin : tb_logic

    automatic uart_cfg_t uart_cfg;
    automatic int unsigned tx_data = 'hAA;

    // set initial config
    uart_cfg.tx_parity_en  = PARITY_DISABLE;
    uart_cfg.tx_stop_width = STOP_1_BIT;
    uart_cfg.tx_data_width = DATA_8_BIT;
    uart_cfg.rx_parity_en  = PARITY_DISABLE;
    uart_cfg.rx_stop_width = STOP_1_BIT;
    uart_cfg.rx_data_width = DATA_8_BIT;
    uart_cfg.baud_rate     = BAUD9600;

    wr_en_cpu = '0;
    rd_en_cpu = '0;
    cpu_addr  = '0;
    cpu_din   = '0;

    while(tb_rst) @(negedge tb_clk);

    // configure UART
    set_uart_cfg(uart_cfg, tb_clk, wr_en_cpu, rd_en_cpu, cpu_addr, cpu_din, cpu_dout);

    // enable tx + rx
    enable_tx(tb_clk, wr_en_cpu, rd_en_cpu, cpu_addr, cpu_din, cpu_dout);
    enable_rx(tb_clk, wr_en_cpu, rd_en_cpu, cpu_addr, cpu_din, cpu_dout);

    // send a loop of 10 values, inverting bits after each iteration
    for (int iter = 0; iter < 5; iter++) begin

      transmit_data_single(tx_data, tb_clk, wr_en_cpu, rd_en_cpu, cpu_addr, cpu_din, cpu_dout);

      tx_data ^= 'hFF;
    end

    // end of TB logic
    $display("[TB %0t] Test logic complete", $time);
    $finish;

  end

  /* Subroutines **************************************************************/

  task automatic write_data_cpu (
    input int unsigned data,
    input int unsigned addr,
    const ref bit      clk,
    ref  bit           wr_en_cpu,
    ref  cpu_addr_t    cpu_addr,
    ref  cpu_data_t    cpu_data_in
  );
    begin

      cpu_addr    = cpu_addr_t'(addr);
      cpu_data_in = cpu_data_t'(data);

      // ensure wr_en is set over a rising edge
      @(negedge clk);
      wr_en_cpu = 1'b1;
      @(negedge clk);

      // release bus
      wr_en_cpu   = '0;
      cpu_addr    = '0;
      cpu_data_in = '0;

    end
  endtask

  task automatic read_data_cpu (
    output int unsigned data,
    input  int unsigned addr,
    const ref bit       clk,
    ref  bit            rd_en_cpu,
    ref  cpu_addr_t     cpu_addr,
    ref  cpu_data_t     cpu_data_out
  );
    begin

      data     = '0;
      cpu_addr = cpu_addr_t'(addr);

      // ensure rd_en is set over a single rising edge and then read result on
      // following rising edge
      @(negedge clk);
      rd_en_cpu = 1'b1;
      @(negedge clk);
      rd_en_cpu = 1'b0;
      @(negedge clk);
      data      = unsigned'(cpu_data_out);

      // release bus
      rd_en_cpu = '0;
      cpu_addr  = '0;

    end
  endtask

  task automatic set_uart_cfg (
    input uart_cfg_t uart_cfg,
    const ref bit    clk,
    ref  bit         wr_en_cpu,
    ref  bit         rd_en_cpu,
    ref  cpu_addr_t  cpu_addr,
    ref  cpu_data_t  cpu_data_in,
    ref  cpu_data_t  cpu_data_out
  );
    begin

      cpu_data_t cpu_data = '0;

      $display("\n[TB %0t] Setting UART Config.", $time);
      print_cfg(uart_cfg);

      // read data in
      read_data_cpu(cpu_data, UartControlAddr, clk, rd_en_cpu, cpu_addr, cpu_data_out);

      // assign config.
      cpu_data[                      TxParityIdx] = uart_cfg.tx_parity_en;
      cpu_data[TxStopWidthIdxHi:TxStopWidthIdxLo] = uart_cfg.tx_stop_width;
      cpu_data[TxDataWidthIdxHi:TxDataWidthIdxLo] = uart_cfg.tx_data_width;
      cpu_data[                      RxParityIdx] = uart_cfg.rx_parity_en;
      cpu_data[RxStopWidthIdxHi:RxStopWidthIdxLo] = uart_cfg.rx_stop_width;
      cpu_data[RxDataWidthIdxHi:RxDataWidthIdxLo] = uart_cfg.rx_data_width;
      cpu_data[  BaudSelectIdxHi:BaudSelectIdxLo] = uart_cfg.baud_rate;

      // write data back
      write_data_cpu(cpu_data, UartControlAddr, clk, wr_en_cpu, cpu_addr, cpu_data_in);

    end
  endtask

  task automatic enable_tx (
    const ref bit    clk,
    ref  bit         wr_en_cpu,
    ref  bit         rd_en_cpu,
    ref  cpu_addr_t  cpu_addr,
    ref  cpu_data_t  cpu_data_in,
    ref  cpu_data_t  cpu_data_out
  );
    begin

      cpu_data_t cpu_data = '0;

      // read data in
      read_data_cpu(cpu_data, UartControlAddr, clk, rd_en_cpu, cpu_addr, cpu_data_out);

      // assign config.
      cpu_data[TxEnableIdx] = 1'b1;

      // write data back
      write_data_cpu(cpu_data, UartControlAddr, clk, wr_en_cpu, cpu_addr, cpu_data_in);

    end
  endtask

  task automatic disable_tx (
    const ref bit    clk,
    ref  bit         wr_en_cpu,
    ref  bit         rd_en_cpu,
    ref  cpu_addr_t  cpu_addr,
    ref  cpu_data_t  cpu_data_in,
    ref  cpu_data_t  cpu_data_out
  );
    begin

      cpu_data_t cpu_data = '0;

      // read data in
      read_data_cpu(cpu_data, UartControlAddr, clk, rd_en_cpu, cpu_addr, cpu_data_out);

      // assign config.
      cpu_data[TxEnableIdx] = 1'b0;

      // write data back
      write_data_cpu(cpu_data, UartControlAddr, clk, wr_en_cpu, cpu_addr, cpu_data_in);

    end
  endtask

  task automatic enable_rx (
    const ref bit    clk,
    ref  bit         wr_en_cpu,
    ref  bit         rd_en_cpu,
    ref  cpu_addr_t  cpu_addr,
    ref  cpu_data_t  cpu_data_in,
    ref  cpu_data_t  cpu_data_out
  );
    begin

      cpu_data_t cpu_data = '0;

      // read data in
      read_data_cpu(cpu_data, UartControlAddr, clk, rd_en_cpu, cpu_addr, cpu_data_out);

      // assign config.
      cpu_data[RxEnableIdx] = 1'b1;

      // write data back
      write_data_cpu(cpu_data, UartControlAddr, clk, wr_en_cpu, cpu_addr, cpu_data_in);

    end
  endtask

  task automatic disable_rx (
    const ref bit    clk,
    ref  bit         wr_en_cpu,
    ref  bit         rd_en_cpu,
    ref  cpu_addr_t  cpu_addr,
    ref  cpu_data_t  cpu_data_in,
    ref  cpu_data_t  cpu_data_out
  );
    begin

      cpu_data_t cpu_data = '0;

      // read data in
      read_data_cpu(cpu_data, UartControlAddr, clk, rd_en_cpu, cpu_addr, cpu_data_out);

      // assign config.
      cpu_data[RxEnableIdx] = 1'b0;

      // write data back
      write_data_cpu(cpu_data, UartControlAddr, clk, wr_en_cpu, cpu_addr, cpu_data_in);

    end
  endtask

  task automatic transmit_data_single (
    input int unsigned data,
    const ref bit      clk,
    ref  bit           wr_en_cpu,
    ref  bit           rd_en_cpu,
    ref  cpu_addr_t    cpu_addr,
    ref  cpu_data_t    cpu_data_in,
    ref  cpu_data_t    cpu_data_out
  );
    begin

      // truncate data
      automatic uart_data_t uart_data = uart_data_t'(data);
      automatic cpu_data_t  cpu_data  = '0;
      automatic bit         tx_busy   = 1'b0;

      cpu_data[TxDataIdxHi:TxDataIdxLo] = uart_data;

      // write Tx Data
      write_data_cpu(cpu_data, UartTxAddr, clk, wr_en_cpu, cpu_addr, cpu_data_in);

      // read cfg
      read_data_cpu(cpu_data, UartControlAddr, clk, rd_en_cpu, cpu_addr, cpu_data_out);

      // write Tx En
      cpu_data[TxStartIdx] = 1'b1;
      write_data_cpu(cpu_data, UartControlAddr, clk, wr_en_cpu, cpu_addr, cpu_data_in);

      // read cfg to get busy status
      read_data_cpu(cpu_data, UartStatusAddr, clk, rd_en_cpu, cpu_addr, cpu_data_out);
      // isolate busy flag
      tx_busy = cpu_data[TxBusyIdx];

      // wait for tx busy to clear
      while(tx_busy) begin
        // read cfg
        read_data_cpu(cpu_data, UartStatusAddr, clk, rd_en_cpu, cpu_addr, cpu_data_out);
        // isolate busy flag
        tx_busy = cpu_data[TxBusyIdx];
      end

    end
  endtask

  function automatic void print_cfg(uart_cfg_t cfg);
    $display("\tUART CONFIG:");
    $display("\t\ttx_parity_en  = %0s \t(0b%0b)", cfg.tx_parity_en.name(), cfg.tx_parity_en);
    $display("\t\ttx_stop_width = %0s \t(0b%0b)", cfg.tx_stop_width.name(), cfg.tx_stop_width);
    $display("\t\ttx_data_width = %0s \t(0b%0b)", cfg.tx_data_width.name(), cfg.tx_data_width);
    $display("\t\trx_parity_en  = %0s \t(0b%0b)", cfg.rx_parity_en.name(), cfg.rx_parity_en);
    $display("\t\trx_stop_width = %0s \t(0b%0b)", cfg.rx_stop_width.name(), cfg.rx_stop_width);
    $display("\t\trx_data_width = %0s \t(0b%0b)", cfg.rx_data_width.name(), cfg.rx_data_width);
    $display("\t\tbaud_rate     = %0s \t(0b%0b)\n", cfg.baud_rate.name(), cfg.baud_rate);
  endfunction

  /* Testbench timeout ********************************************************/

  initial begin : tb_timeout

    while ($realtime < TEST_RUNTIME) begin
      @(posedge tb_clk);
    end

    $display("[TB %0t] tb_uart_top : Test Timed Out", $time);

    $finish;
  end

endmodule
