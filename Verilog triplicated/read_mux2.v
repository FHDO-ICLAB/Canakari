////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : read_mux2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : Ausgelagerter Multiplexer f�r CPU-Lesezyklus, umschalten der
//                Registerausg�nge auf Datenbus. Ein einfacher Multiplexer, mit Synopsys
//                Attribut dazu gen�tigt, einer zu sein
// Commentary   : The HW-ID is taken from the original CAN top level (VHDL) 
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 20.05.2019 | created
// -------------------------------------------------------------------------------------------------
// 0.91    | Leduc              | 21.05.2019 | Added parameter for HW-ID 
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module read_mux2(
  input wire [4:0]  address,  // aussen
  input wire [15:0] preregr,  // prescalereg.
  input wire [15:0] genregr,   // generalreg.
  input wire [15:0] intregr,   // interrupt register 
  input wire [15:0] traconr,   // transmit message ctrl. reg.
  input wire [15:0] traar1r,   // trans. arbit. reg.1
  input wire [15:0] traar2r,   // trans. arbit. reg.2
  input wire [15:0] trad01r,   // trans. data 1&2
  input wire [15:0] trad23r,   // trans. data 3&4
  input wire [15:0] trad45r,   // trans. data 5&6
  input wire [15:0] trad67r,   // trans. data 7&8
  input wire [15:0] recconr,   // recv. mess. ctrl. 
  input wire [15:0] accmask1r, // Acceptance Mask Register 1
  input wire [15:0] accmask2r, // Accpetance Mask Register 2
  input wire [15:0] recar1r,   // recv. arbit. 1
  input wire [15:0] recar2r,   // recv. arbit. 2
  input wire [15:0] recd01r,   // recv data 1&2
  input wire [15:0] recd23r,   // recv data 3&4
  input wire [15:0] recd45r,   // recv data 5&6
  input wire [15:0] recd67r,   // recv data 7&8
  input wire [15:0] fehlregr,  // Fehlerzaehler Register TEC/REC
  output reg [15:0] data_out   // zum Datenbus
);

//tmrg default triplicate
//tmrg tmr_error false

parameter [15:0] system_id = 16'hCA05; // HW-ID 

// Read (CPU liest vom Controller) 

always@(*)
begin
  case (address)    
    5'b10100 : data_out = system_id;
    5'b10011 : data_out = fehlregr;
    5'b10010 : data_out = intregr;
    5'b10001 : data_out = accmask1r;
    5'b10000 : data_out = accmask2r;
    5'b01111 : data_out = preregr;
    5'b01110 : data_out = genregr;
    5'b01101 : data_out = traconr;
    5'b01100 : data_out = traar1r;
    5'b01011 : data_out = traar2r;
    5'b01010 : data_out = trad01r;
    5'b01001 : data_out = trad23r;
    5'b01000 : data_out = trad45r;
    5'b00111 : data_out = trad67r;
    5'b00110 : data_out = recconr;
    5'b00101 : data_out = recar1r;
    5'b00100 : data_out = recar2r;
    5'b00011 : data_out = recd01r;
    5'b00010 : data_out = recd23r;
    5'b00001 : data_out = recd45r;
    5'b00000 : data_out = recd67r;
    default  : data_out = 16'd0;
  endcase
end
endmodule
