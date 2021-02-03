////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : tcrc2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : TCRC: Transmit CRC
// Commentary   : neu geschrieben zur Synthese optimierung: Instanziierung
//                der Register mit Generate, XOR Verknüpfung per Hand. Verschiedene Preload
//                Eingänge: crc_pre_load_ext: für IDE=1, kommt von mesin ganz oben,
//                crc_pre_load_rem (falscher Name) für Basic, kommt von weiter unten aus mesin
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

module tcrc2 (
    input  wire        clock,
    input  wire        bitin,
    input  wire        activ,
    input  wire        reset,
    input  wire [14:0] crc_pre_load_ext,
    input  wire [14:0] crc_pre_load_rem,
    input  wire        extended,
    input  wire        load,
    input  wire        load_activ,
    input  wire        crc_shft_out,
    input  wire        zerointcrc,
    output wire        crc_tosend 
  );

reg	    edged;
reg         enable_i;           // Flankenmerker
wire        activ_i;
wire        reset_i;
wire        load_i;
wire        bitin_i;
wire        feedback;
wire [14:0] q_out;           // Ausgänge Register
wire [14:0] inp;             // Eingänge Register
reg  [14:0] crc_pre_load_i;  // Ausgang MUX bas/ext

assign reset_i = reset;

// crc_shft_out=1 : Register ist jetzt Sendeschieberegister, deshalb feedback auf 0 stellen. 
// Sonst normale XOR-Rückkopplung
assign activ_i  = (activ & (~crc_shft_out)) | (load_activ & crc_shft_out);
assign feedback = ( ~crc_shft_out) & q_out[14];  // Rückführung
assign load_i   = load & load_activ;
assign bitin_i  = (bitin | crc_shft_out) & zerointcrc; 

// Nullen reinschieben (die fehlenden 15 Takte vor versendung), Rückkopplung wie CRC-Generatorpolynom:
assign inp[ 0] = bitin_i ^ feedback;
assign inp[ 1] = q_out[ 0];
assign inp[ 2] = q_out[ 1];
assign inp[ 3] = q_out[ 2] ^ feedback;
assign inp[ 4] = q_out[ 3] ^ feedback;
assign inp[ 5] = q_out[ 4];
assign inp[ 6] = q_out[ 5];
assign inp[ 7] = q_out[ 6] ^ feedback;
assign inp[ 8] = q_out[ 7] ^ feedback;
assign inp[ 9] = q_out[ 8];
assign inp[10] = q_out[ 9] ^ feedback;
assign inp[11] = q_out[10];
assign inp[12] = q_out[11];
assign inp[13] = q_out[12];
assign inp[14] = q_out[13] ^ feedback;

assign crc_tosend = q_out[14];

//// Register instanziieren
genvar i;
generate for (i = 0; i < 15; i = i + 1) begin
    tcrc_cell2 reg_i( 
	.enable  ( enable_i	     ),
        .preload ( crc_pre_load_i[i] ),
        .clock   ( clock             ),
        .reset   ( reset_i           ),
        .load    ( load_i            ),
        .Input   ( inp[i]            ),
        .q       ( q_out[i]          )
       );
end endgenerate

// Multiplexer: abhängig von IDE crcreg mit unten oder oben vorladen
always@(extended, crc_pre_load_ext, crc_pre_load_rem)
begin
  if (extended == 1'b1)
    crc_pre_load_i = crc_pre_load_ext;  // extended
  else
    crc_pre_load_i = crc_pre_load_rem;  // basic
end 

always@(negedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
begin  
  if (reset == 1'b0)          // synchroner reset
    begin
     enable_i <= 1'b1;
     edged = 1'b0;
    end
  else
    if (activ_i == 1'b1)
      if (edged == 1'b0)      // war schon flanke?
        begin 
         edged = 1'b1;        // dann aber jetzt
         enable_i <= 1'b1;     // Schiebesignal
        end
      else 
        begin
         edged = 1'b1;        // war schon!
         enable_i <= 1'b0;     // Signal kurz
        end
    else 
      begin
       edged = 1'b0;          // kein activ, flanke neg.
       if (load == 1'b1 && load_activ == 1'b1)
         enable_i <= 1'b1;     // Vorladen
       else
         enable_i <= 1'b0;
      end
end

endmodule
