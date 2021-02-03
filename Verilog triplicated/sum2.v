////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : sum2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : arithmetische Einheit f�r die FSM
// Commentary   :  
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 15.01.2019 | created
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module sum2 (
 input wire [3:0] count,           // timecount
 input wire [2:0] tseg1org,        // 5(6) IOCPU, genreg.
 input wire [4:0] tseg1mpl,        // 5(6) tseg_reg
 input wire [2:0] tseg2,           // 4(5) IOCPU, genreg
 input wire [2:0] sjw,             // IOCPU, genreg
 output reg notnull,               // fsm
 output reg gtsjwp1,               // fsm
 output reg gttseg1p1,             // fsm
 output reg cpsgetseg1ptseg2p2,    // fsm 
 output reg cetseg1ptseg2p1,       // fsm
 output reg countesmpltime,        // fsm
 output reg [4:0] tseg1p1psjw,     // tseg_reg   
 output reg [4:0] tseg1pcount	     // tseg_reg            
 );	
 
//tmrg default triplicate
//tmrg tmr_error false 

 reg [2:0] tseg1m1;
 reg [4:0] tseg1p1mpl;
 reg [3:0] tseg1p1org;
 reg [3:0] sjwp1;
 reg [4:0] countpsjw;
 reg [4:0] tseg1ptseg2p1;
 reg [4:0] tseg1ptseg2p2;
 
///////////////////////////////////////////////////////////////////////////////
 always @(tseg1mpl) 
 begin
   tseg1p1mpl <= tseg1mpl + 1;
 end
 
////////////////////////////////////////////////////////////////////////////////
 always @(tseg1org) 
 begin
  tseg1p1org <= tseg1org+1;
 end
 
////////////////////////////////////////////////////////////////////////////////
 always @(tseg1org) 
 begin
  if (tseg1org > 0)
    tseg1m1 <= tseg1org-1;
  else
    tseg1m1 <= 0;   
 end
 
////////////////////////////////////////////////////////////////////////////////
 always @(sjw) 
 begin
  sjwp1 <= sjw + 1;
 end
 
////////////////////////////////////////////////////////////////////////////////
 always @(count, sjw) 
 begin
  countpsjw <= count+sjw;
 end
 
////////////////////////////////////////////////////////////////////////////////
 always @(tseg1p1mpl, tseg2) 
 begin
  tseg1ptseg2p1 <= tseg1p1mpl+{2'b00,tseg2};
 end
 
////////////////////////////////////////////////////////////////////////////////
 always @(tseg1ptseg2p1) 
 begin
  tseg1ptseg2p2 <= tseg1ptseg2p1+1;
 end
 
////////////////////////////////////////////////////////////////////////////////
 always @(tseg1m1, count) 
 begin
  tseg1pcount <= tseg1m1+count;
 end
 
////////////////////////////////////////////////////////////////////////////////
 always @(tseg1p1org, sjw) 
 begin
  tseg1p1psjw <= tseg1p1org+sjw;
 end
 
////////////////////////////////////////////////////////////////////////////////
 always @(count) 
 begin
  if (count != 0)		// Check in Simulation
    notnull <= 1'b1;
  else
    notnull <= 1'b0;
 end
 
////////////////////////////////////////////////////////////////////////////////
 always @(count, sjwp1) 
 begin
  if (count > sjwp1)
    gtsjwp1 <= 1'b1;
  else
    gtsjwp1 <= 1'b0;
 end
 
//////////////////////////////////////////////////////////////////////////////// 
 always @(count, tseg1p1mpl) 
 begin
  if ({1'b0,count} > tseg1p1mpl)
    gttseg1p1 <= 1'b1;
  else
    gttseg1p1 <= 1'b0;
 end
 
//////////////////////////////////////////////////////////////////////////////// 
 always @(countpsjw, tseg1ptseg2p2) 
 begin
   if (countpsjw >= tseg1ptseg2p2)
     cpsgetseg1ptseg2p2 <= 1'b1;
   else
     cpsgetseg1ptseg2p2 <= 1'b0;
 end
 
//////////////////////////////////////////////////////////////////////////////// 
 always @(count, tseg1ptseg2p1) 
 begin
  if ({1'b0,count} == tseg1ptseg2p1)
    cetseg1ptseg2p1 <= 1'b1;
  else
    cetseg1ptseg2p1 <= 1'b0;
 end
 
//////////////////////////////////////////////////////////////////////////////// 
 always @(count, tseg1p1mpl) 
 begin
  if ({1'b0,count} == tseg1p1mpl)
    countesmpltime <= 1'b1;
  else
    countesmpltime <= 1'b0;
 end
endmodule
