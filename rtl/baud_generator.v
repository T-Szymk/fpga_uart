/*------------------------------------------------------------------------------
-- Title      : FPGA UART Baud Generator
-- Project    : FPGA UART
--------------------------------------------------------------------------------
-- File       : baud_generator.v
-- Author(s)  : Thomas Szymkowiak
-- Company    : TUNI
-- Created    : 2023-03-04
-- Design     : baud_generator
-- Platform   : -
-- Standard   : Verilog '05
--------------------------------------------------------------------------------
-- Description: Baud rate generator to be used within the FPGA UART. The Baud 
--              rate can be set using the sel signal. The following Baud rates
--              are supported: 9600, 19200, 115200 and 256000.
--              The generator toggles an enable signal for one clock cycle at a 
--              frequency equivalent to the Baud Rate / 16. This can be used by
--              other components within the UART for timing Rx and Tx processes.
--------------------------------------------------------------------------------
-- Revisions:
-- Date        Version  Author  Description
-- 2023-03-04  1.0      TZS     Created
------------------------------------------------------------------------------*/

module baud_generator #(
  //! Top clock frequency
  parameter unsigned TOP_CLK_FREQ_HZ = 50000000
) (
  input  wire         clk_i,      //! Clock
  input  wire         rst_i,      //! Active-high synchronous reset
  input  wire [2-1:0] baud_sel_i, //! Baud-rate select signal
  output wire         baud_en_o   //! Baud clock enable signal
);

/*** TYPES/CONSTANTS/DECLARATIONS *********************************************/

  localparam integer MIN_SAMPLE_FREQ_9600_BAUD_HZ   =  153600;
  localparam integer MIN_SAMPLE_FREQ_19200_BAUD_HZ  =  307200;
  localparam integer MIN_SAMPLE_FREQ_115200_BAUD_HZ = 1843200;
  localparam integer MIN_SAMPLE_FREQ_256000_BAUD_HZ = 4086000;

  localparam integer SAMPLE_COUNT_9600_BAUD   = ( TOP_CLK_FREQ_HZ / MIN_SAMPLE_FREQ_9600_BAUD_HZ );
  localparam integer SAMPLE_COUNT_19200_BAUD  = ( TOP_CLK_FREQ_HZ / MIN_SAMPLE_FREQ_19200_BAUD_HZ );
  localparam integer SAMPLE_COUNT_115200_BAUD = ( TOP_CLK_FREQ_HZ / MIN_SAMPLE_FREQ_115200_BAUD_HZ );
  localparam integer SAMPLE_COUNT_256000_BAUD = ( TOP_CLK_FREQ_HZ / MIN_SAMPLE_FREQ_256000_BAUD_HZ );

  localparam integer SAMPLE_COUNT_WIDTH = $clog2(SAMPLE_COUNT_256000_BAUD + 1);

  //! Baud clock enable signal
  reg baud_en_r     = 1'b0;
  //! Indicates baud rate select has been updated
  reg select_update_s = 1'b0;
  //! Baud rate select register to detect value update
  reg [                 2-1:0] baud_sel_r; 
  //! Register holding maximum value of sample counter 
  reg [SAMPLE_COUNT_WIDTH-1:0] sample_count_max_s;
  //! Sample counter register
  reg [SAMPLE_COUNT_WIDTH-1:0] sample_count_r;

/*** Assignments **************************************************************/

  assign baud_en_o = baud_en_r;

/*** Logic ********************************************************************/
  
  //! Sample counter logic 
  always @(posedge clk_i) begin : sync_sample_count

    if ( rst_i ) begin 
      
      sample_count_r <= 0;
      baud_en_r      <= 1'b0;

    end else begin 
      
      if ( (sample_count_r == ( sample_count_max_s - 1)) || select_update_s ) begin 
        sample_count_r <= 0;
        baud_en_r      <= 1'b1;
      end else begin 
        sample_count_r <= sample_count_r + 1;
        baud_en_r      <= 1'b0;
      end 

    end
  end
  
  //! Assigns baud_sel into a register to determine if baud_sel has been updated
  always @(posedge clk_i) begin : sync_baud_sel
  
    if ( rst_i ) begin 
      baud_sel_r <= 0;
    end else begin 
      baud_sel_r <= baud_sel_i;
    end
  
  end

  //! Assign max value of baud clock counter
  always @( baud_sel_i ) begin : comb_baud_count_select

    case(baud_sel_i)

      2'b00 : begin 
        sample_count_max_s = SAMPLE_COUNT_9600_BAUD;
      end 
      2'b01 : begin 
        sample_count_max_s = SAMPLE_COUNT_19200_BAUD;
      end
      2'b10 : begin 
        sample_count_max_s = SAMPLE_COUNT_115200_BAUD;
      end
      2'b11 : begin 
        sample_count_max_s = SAMPLE_COUNT_256000_BAUD;
      end
      default: begin 
        sample_count_max_s = SAMPLE_COUNT_9600_BAUD;
      end

    endcase

  end

  //! Raise baud update if select value is updated for 1 clock cycle
  always @( baud_sel_r, baud_sel_i ) begin : sync_baud_update

    if ( baud_sel_r != baud_sel_i ) begin 
      select_update_s = 1'b1;
    end else begin 
      select_update_s = 1'b0;
    end

  end

endmodule // baud_generator
