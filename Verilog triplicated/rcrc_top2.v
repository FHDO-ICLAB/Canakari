////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : rcrc2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : 
// Commentary   : RCRC: Receive CRC, neu geschrieben zur Synthese optimierung: Instanzieerung
//                der REgister mit Generate, XOR Verkn�pfung per Hand
//                DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
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

module rcrc2 (
    input  wire clock,
    input  wire bitin,    // destuff, bitout
    input  wire activ,    // MACFSM, actvrcrc
    input  wire reset,
    output reg  crc_ok    // wenn Register alle 0
    );

//tmrg default triplicate
//tmrg tmr_error false

reg         enable_i;     // enable f�r das CRC-Register
wire        reset_i;      // reset          "
wire [14:0] q_out;        // Verbindungen zwischen Registern/XOR
wire [14:0] inp;          // Verbindung zwischen XOR/Registern

reg edged;                // Flankenmerker deglitch

assign reset_i = reset;   // reset Register

//triplication signals
wire enable_iVoted = enable_i;
wire edgedVoted = edged;

// 15 Register instanziieren:
genvar i;
generate for (i = 0; i < 15; i = i + 1) begin
    rcrc_cell2 reg_i(
        .enable ( enable_iVoted ),
        .clock  ( clock    ),
        .reset  ( reset_i  ),
        .Input  ( inp[i]   ),
        .q      ( q_out[i] )
    );
end endgenerate

always@(negedge clock)    // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.    
begin
  if(reset == 1'b0)       // synchroner Reset
    enable_i <= 1'b1;
  else begin
    enable_i <= enable_iVoted;
    edged = edgedVoted;
    if (activ == 1'b1)    // Flanke merken
      if (edgedVoted == 1'b0) 
        begin
        edged    = 1'b1;
        enable_i <= 1'b1;  // Taktimpuls f�r Register
        end
      else
        edged = 1'b1;     // Flanke gesetzt lassen
    else 
      begin
      edged    = 1'b0;    // activ=0, flankenmerker reset
      enable_i <= 1'b0;    // f�r Register
      end 
  end    
end

always@(q_out)
begin
  if (q_out == 15'd0)     // CRC Register ist null-> CRC war ok
    crc_ok = 1'b1;
  else
    crc_ok = 1'b0;
end

// XOR R�ckkopplung (q_out[14]) nach CAN-Generatorpolynom:
assign inp[ 0] = bitin     ^ q_out[14];
assign inp[ 1] = q_out[ 0];
assign inp[ 2] = q_out[ 1];
assign inp[ 3] = q_out[ 2] ^ q_out[14];
assign inp[ 4] = q_out[ 3] ^ q_out[14];
assign inp[ 5] = q_out[ 4];
assign inp[ 6] = q_out[ 5];
assign inp[ 7] = q_out[ 6] ^ q_out[14];
assign inp[ 8] = q_out[ 7] ^ q_out[14];
assign inp[ 9] = q_out[ 8];
assign inp[10] = q_out[ 9] ^ q_out[14];
assign inp[11] = q_out[10];
assign inp[12] = q_out[11];
assign inp[13] = q_out[12];
assign inp[14] = q_out[13] ^ q_out[14];

endmodule
