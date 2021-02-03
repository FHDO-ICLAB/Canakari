////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : tshiftreg2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : TSHIFT: Sendeschieberegister (TOP-Level!). 
//                Zur Synthese Optimierung Instanziierung von 103 Registern.
// Commentary   : DW 2005_06_30 clock Flanke von negativ auf positiv geaendert. 
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 08.07.2019 | created
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module tshiftreg2(
    input  wire         clock,
    input  wire [102:0] mesin,
    input  wire         activ,           // MACFSM: actvtsft, llc:actvtsftllc
    input  wire         reset,           // MAC: reset or MACFSM: resetsft
    input  wire         load,            // llc: load
    input  wire         shift,           // MACFSM: tshift
    input  wire         extended,        // IOCPU
    output wire         bitout,          // stuff, biterrordetect
    output wire         crc_out_bit      // tcrc
);

wire         reset_i;
wire         load_reg;
wire [102:0] q_i;  
wire         zero;
wire         bitout_i;
reg          enable_i;
reg          edged;

assign reset_i   = reset;
assign load_reg  = load;       // intern: laden Register
assign zero      = 1'b0;       // 0- input
assign bitout    = (bitout_i & extended) | (q_i[82] & (~extended));  // basic: 82 extended: 102
assign crc_out_bit = (q_i[87] & extended) | (q_i[67] & (~extended)); // basic: 67, extended 87, 
                                                                        // crc wird mit bit, das 
                                                                        // erst 15 Zeiten später 
                                                                        // kommt gefüttert,
                                                                        // wg crc-änderung

// oberstes Register (Ausgang bitout_i)
  tshift_cell2 topreg(                  // Nr 102
      .enable  ( enable_i   ),
      .preload ( mesin[102] ),
      .clock   ( clock      ),
      .reset   ( reset_i    ),
      .load    ( load_reg   ),
      .Input   ( q_i[101]   ),
      .q       ( bitout_i   )
      );
      
// mittlere Register:      
genvar i;
generate for (i = 1; i < 102; i = i + 1) begin
  tshift_cell2 reg_i(
      .enable  ( enable_i ),
      .preload ( mesin[i] ),
      .clock   ( clock    ),
      .reset   ( reset_i  ),
      .load    ( load_reg ),
      .Input   ( q_i[i-1] ),
      .q       ( q_i[i]   )
      );
end endgenerate
        
        
// unterstes Register, null als eingang
  tshift_cell2 bottom_reg(               // Nr. 0
      .enable  ( enable_i ),
      .preload ( mesin[0] ),
      .clock   ( clock    ),
      .reset   ( reset_i  ),
      .load    ( load_reg ),
      .Input   ( zero     ),
      .q       ( q_i[0]   )
      );

always@(negedge clock)
begin
  if (reset == 1'b0) begin                   // synchroner reset                         
    edged   = 1'b0;                          // normalerweise active high
    enable_i <= 1'b0; 
    end
  else
    if (activ == 1'b1) begin
      if (edged == 1'b0) begin              // Flanke?
        edged = 1'b1;                       // jetzt war eine
        if (shift == 1'b1 || load == 1'b1) 
          enable_i <= 1'b1;                 // shift oder load sorgen für
        else                                // aktivierung der register
          enable_i <= 1'b0;
        end
      else begin
        enable_i <= 1'b0;
        edged = 1'b1;                       // immmer noch pos. Flanke
        end
      end
    else begin
      enable_i <= 1'b0;
      edged   = 1'b0;                       // jetzt war activ runter
      end
end

endmodule
