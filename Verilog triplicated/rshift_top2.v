////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : rshiftreg2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : RSHIFT: Empfangschieberegister (TOP-Level). 
// Commentary   : Instanziierung von 103 Registern. 
//                F�r nachtr�glichen Fastshift zwei extra Eing�nge. 
//                1. setzero: Bitin wird w�hrend fastshift auf null gehalten (0 rein). 
//                2. directshift: Fastshift Schiebetakt (clock_extern/2).
//                DW 2005_06_30 clock Flanke von negativ auf positiv geaendert. 
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

module rshiftreg2(
    input  wire        clock,
    input  wire        bitin,
    input  wire        activ,          // MACFSM: actvrsft
    input  wire        reset,          // reset (sync)
    input  wire        lcrc,           // MACFSM: lcrc
    input  wire        setzero,        // fastshift: setzero
    input  wire        directshift,    // fastshift: directshift
    output wire [67:0] mesout_a,       // llc; IOCPU: data+dlc
    output wire [17:0] mesout_b,       // decapsulation, ext. id
    output wire [10:0] mesout_c        // dcapsulation, bas. id
    );

//tmrg default triplicate
//tmrg tmr_error false

reg          edged;
wire         activ_i;
wire         bitin_i;
reg          enable_i;
wire         reset_i;
wire [102:0] q_i;


//triplication signals
wire edgedVoted = edged;
wire enable_iVoted = enable_i;

assign mesout_a = q_i[ 67: 0];                      // Data+DLC
assign mesout_b = q_i[ 88:71];                      // ext. id
assign mesout_c = q_i[101:91];                      // bas. id
assign activ_i  = (activ & (~lcrc)) | directshift;  // internes Schiebe-enable
assign bitin_i  = bitin & setzero;                  // setzero von fastshift (schiebt 0 rein)
assign reset_i  = reset;                            // reset f�r schieberegister


// Unterstes Register (hat Eingang bitin_i)
rshift_cell2 bottom (
	  .enable ( enable_iVoted  ),
    .clock  ( clock   ),
    .reset  ( reset_i ),
    .Input  ( bitin_i ),
    .q      ( q_i[0]  )
  );

// Der Rest der Register, q(i)102 ist unbenutzt
genvar i;
generate for (i = 1; i < 103; i = i + 1) begin
    rshift_cell2 reg_i(
     	  .enable ( enable_iVoted  ),
        .clock  ( clock    ),
        .reset  ( reset_i  ),
        .Input  ( q_i[i-1] ),
        .q      ( q_i[i]   )
    );
end endgenerate 

always@(posedge clock)  // DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
begin
  if (reset == 1'b0) begin       // synchroner reset
    enable_i <= 1'b0;              // normalerweise active high
    edged   = 1'b0;
    end                
  else begin
    edged = edgedVoted;
    enable_i <= enable_iVoted;
    if (activ_i == 1'b1)
      if (edgedVoted == 1'b0) begin   // Flanke schon gewesen?
        edged   = 1'b1;          // jetzt aber!
        enable_i <= 1'b1;          // Schiebetakt
        end
      else
        enable_i <= 1'b0;            // noch keine neg. Flanke
    else
      begin
      edged   = 1'b0;            // neg. Flanke
      enable_i <= 1'b0;            // clock weg
      end
    end
end

endmodule
