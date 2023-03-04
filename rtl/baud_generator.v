/*------------------------------------------------------------------------------
 Title      : FPGA UART Baud Generator
 Project    : FPGA UART
--------------------------------------------------------------------------------
 File       : baud_generator.sv
 Author(s)  : Thomas Szymkowiak
 Company    : TUNI
 Created    : 2023-03-04
 Design     : baud_generator
 Platform   : -
 Standard   : Verilog '05
--------------------------------------------------------------------------------
 Description: 
--------------------------------------------------------------------------------
 Revisions:
 Date        Version  Author  Description
 2023-03-04  1.0      TZS     Created
------------------------------------------------------------------------------*/

module baud_generator #(
  parameter unsigned TOP_CLK_FREQ_HZ = 50_000_000
) (
  input  wire         clk_i,
  input  wire         rst_i,
  input  wire [2-1:0] baud_sel_i,
  output wire         baud_en_o
);

  localparam integer MIN_SAMPLE_FREQ_9600_BAUD_HZ   =   153_600;
  localparam integer MIN_SAMPLE_FREQ_19200_BAUD_HZ  =   307_200;
  localparam integer MIN_SAMPLE_FREQ_115200_BAUD_HZ = 1_843_200;
  localparam integer MIN_SAMPLE_FREQ_256000_BAUD_HZ = 4_086_000;

  localparam integer SAMPLE_COUNT_9600_BAUD   = ( TOP_CLK_FREQ_HZ / MIN_SAMPLE_FREQ_9600_BAUD_HZ );
  localparam integer SAMPLE_COUNT_19200_BAUD  = ( TOP_CLK_FREQ_HZ / MIN_SAMPLE_FREQ_19200_BAUD_HZ );
  localparam integer SAMPLE_COUNT_115200_BAUD = ( TOP_CLK_FREQ_HZ / MIN_SAMPLE_FREQ_115200_BAUD_HZ );
  localparam integer SAMPLE_COUNT_256000_BAUD = ( TOP_CLK_FREQ_HZ / MIN_SAMPLE_FREQ_256000_BAUD_HZ );

  localparam integer SAMPLE_COUNT_WIDTH = $clog2(SAMPLE_COUNT_256000_BAUD + 1);

  reg baud_en_r     = 1'b0;
  reg baud_update_s = 1'b0;

  reg [                 2-1:0] baud_sel_r         ; 
  reg [SAMPLE_COUNT_WIDTH-1:0] sample_count_max_s ;
  reg [SAMPLE_COUNT_WIDTH-1:0] sample_count_r     ;

  assign baud_en_o = baud_en_r;
  
  always @(posedge clk_i) begin

    if ( rst_i ) begin 
      
      sample_count_r <= 0;
      baud_en_r      <= 1'b0;

    end else begin 
      
      if ( (sample_count_r == ( sample_count_max_s - 1)) || baud_update_s ) begin 
        sample_count_r <= 0;
        baud_en_r      <= 1'b1;
      end else begin 
        sample_count_r <= sample_count_r + 1;
        baud_en_r      <= 1'b0;
      end 

    end
  end
  
  // use register to determine if baud_sel has been updated
  always @(posedge clk_i) begin : sync_baud_sel
  
    if ( rst_i ) begin 
      baud_sel_r <= 0;
    end else begin 
      baud_sel_r <= baud_sel_i;
    end
  
  end

  // process to assign max value of baud clock counter
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

  // raise baud update if select value is updated for 1 clock cycle
  always @( baud_sel_r, baud_sel_i ) begin : sync_baud_update

    if ( baud_sel_r != baud_sel_i ) begin 
      baud_update_s = 1'b1;
    end else begin 
      baud_update_s = 1'b0;
    end

  end

endmodule // baud_generator
