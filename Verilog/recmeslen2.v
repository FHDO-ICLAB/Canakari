////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : recmeslen2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : reception data length register
//                Ermittelt tatsächliche Empfangs-Datenlänge in Byte (rmlb), d.h. bei RTR
//                Rahmen ist rmlb immer 0 unabhängig vom DLC-Feld
// Commentary   : DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
//                Beer Assignment of rmlb, setrmlen_reg outside of process (VHDL)
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

module recmeslen2(
       input  wire       clock,     // voll
       input  wire       activ,     // macfsm: actvrmlen
       input  wire       reset,     // macfsm: resrmlen; reset_mac
       input  wire [2:0] setrmlen,  // macfsm, setrmleno
       output wire [3:0] rmlb       // rmlen in Byte (neu)
       );
       
reg        edged;       
reg  [3:0] rmlb_reg;   
wire [2:0] setrmlen_reg; 

assign rmlb         = rmlb_reg;     // Beer
assign setrmlen_reg = setrmlen;

always@(posedge clock)
begin
  if (reset == 1'b0) begin              // synchroner Reset                          
    rmlb_reg <= 4'b0000;
    edged     = 1'b0;
    end
  else
    if (activ == 1'b1) begin
	if (edged == 1'b0) begin
		edged = 1'b1;                   // Flanke merken
		if (setrmlen_reg == 3'd1)       // Bit#0 setzen
		  rmlb_reg[0] <= 1'b1;
		else if (setrmlen_reg == 3'd2)  // Bit#1 setzen
		  rmlb_reg[1] <= 1'b1;
		else if (setrmlen_reg == 3'd3)  // Bit#2 setzen
		  rmlb_reg[2] <= 1'b1;
		else if (setrmlen_reg == 3'd4)  // Bit#3 setzen
		  rmlb_reg[3] <= 1'b1;
		end
	else begin
	  edged = 1'b1;                 // Flanke nicht gewechselt
	  end
	end
    else
      edged = 1'b0;                  // activ=0, Flankenmerker 0                          
end








endmodule
