////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : meslencompare2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : startrcrc: FSM, rcrc: Daten empfang vorbei, CRC Empfangen
//                starttcrc: FSM, wenn CRC gesendet werden muss.
//                zerointcrc: Nullen in Tranmit CRC schieben (letzte 15 Takte)
//                en_zerointcrc: von FSM, erst ab SOF erlaubt (enable)
//                rmzero: realer DLC ist 0, direkter �bergang von Arbit in CRC Empfang
//                --------------------------------------------------------------------
//                Vergleichsprinzip: Bspl.: tmlen+39 = count
//                tmlen=0: 39 = 100 111 ; 100-100=  0 (0)
//                tmlen=1: 47 = 101 111 ; 101-100=  1 (1)
//                tmlen=2: 55 = 110 111 ; 110-100= 10 (2)
//                untere Bits m�ssen 111 sein, obere sind tmlen (in Byte)-4
// Commentary   :  
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 01.07.2019 | created
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module meslencompare2 (
    input  wire [6:0] count,         // counter
    input  wire [3:0] rmlen,         // recmeslen: rmlb
    input  wire [3:0] tmlen,         // encapsulation
    input  wire       ext_r,         // fsm_regs: rext
    input  wire       ext_t,         // IOCPU, transmesconreg
    input  wire       en_zerointcrc, // MACFSM
    output reg        startrcrc,     // MACFSM
    output reg        rmzero,        // MACFSM
    output reg        starttcrc,     // MACFSM
    output wire       zerointcrc     // tcrc, Nullen nachschieben (15)  
    );

//tmrg default triplicate
//tmrg tmr_error false

wire [6:0] count_s;        
wire [3:0] count_top_us;   
wire [2:0] count_bot_us;   
wire [3:0] tmlb19_us;      
wire [3:0] tmlb39_us;      
wire [3:0] rmlb19_us;      
wire [3:0] rmlb39_us;      
wire [6:0] tmlen_bit_us4;  
wire [6:0] tmlen_bit_us24; 
reg        zerointcrc_i;

assign count_s      = count;
assign count_top_us = count_s [6:3];
assign count_bot_us = count_s [2:0];

assign tmlb19_us    = tmlen +4'd2;  
assign tmlb39_us    = tmlen +4'd4;
assign rmlb19_us    = rmlen +4'd2;
assign rmlb39_us    = rmlen +4'd4;

assign tmlen_bit_us4  [6:3] = tmlen;
assign tmlen_bit_us4  [2:0] = 3'b011;   //100
assign tmlen_bit_us24 [6:3] = tmlen +4'd2;
assign tmlen_bit_us24 [2:0] = 3'b111;

assign zerointcrc = (zerointcrc_i | (~en_zerointcrc));

always@(count_top_us, count_bot_us, tmlb19_us, tmlb39_us, ext_t)
begin // transmit crc startet bei basic an Posi: 19+tmlen
      // bei extended 39+tmlen
  if (((count_top_us == tmlb19_us) && (count_bot_us == 3'd3) && (ext_t == 1'b0)) || 
     ( (count_top_us == tmlb39_us) && (count_bot_us == 3'd7) && (ext_t == 1'b1)))
    starttcrc = 1'b1;
  else
    starttcrc = 1'b0;  
end

always@(count_top_us, count_bot_us, rmlb19_us, rmlb39_us, ext_r)
begin // receive crc startet bei gleichen Positionen (rmlen)
  if (((count_top_us == rmlb19_us) && (count_bot_us == 3'd3) && (ext_r == 1'b0)) ||
     ( (count_top_us == rmlb39_us) && (count_bot_us == 3'd7) && (ext_r == 1'b1))) 
    startrcrc = 1'b1;
  else
    startrcrc = 1'b0;
end 

always@(ext_t, count_s, tmlen_bit_us24, tmlen_bit_us4)
begin // basic: crc startet bei 19+rmlen, Nullen also 15 vorher (4+rmlen) starten
      // extended: crc startet 39+rmlen, Nullen also 24 vorher reinschieben (-15)
  if (((count_s >  tmlen_bit_us4) && (ext_t == 1'b0))  || 
     ( (count_s > tmlen_bit_us24) && (ext_t == 1'b1)))
    zerointcrc_i = 1'b0;  // Nullen ins tcrc schieben = 1'b0;  // Nullen ins tcrc schieben
  else
    zerointcrc_i = 1'b1;  // Outbit ins tcrc schieben
end

always@(rmlen)
begin // Signal f�r Datenversenden �berspringen (reale Datenl�nge ist 0)
  if (rmlen == 4'b0000)
    rmzero = 1'b1;
  else
    rmzero = 1'b0;
end

endmodule














