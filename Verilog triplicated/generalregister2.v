////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : generalregister2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : general register
// Commentary   : Changed port name reg to register during translation (VHDL). 
//
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 22.05.2019 | created
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module generalregister2(
        input wire clk,
        input wire rst,
        input wire cpu,   // CPU wuenscht Zugriff
        input wire can,   // controller wuenscht Zugriff
        input wire bof,   // bus off
        input wire era,   // error activ
        input wire erp,   // error passive
        input wire war,   // warning error count level
        input wire [2:0] sjw,
        input wire [2:0] tseg1,
        input wire [2:0] tseg2,
        input wire ssp,   // succesfull send processor
        input wire srp,   // succesfull received processor
        input wire ssc,   // succesfull send can
        input wire src,   // succesfull received can
        input wire rsp,   // reset/initialization processor
        output wire [15:0] register  // generalregister
);

//tmrg default triplicate
//tmrg tmr_error false 

reg [15:0] register_i;

//triplication signals
wire [15:0] register_iVoted = register_i;
assign register = register_iVoted;

always@(posedge clk)
begin
  if (rst == 1'b0) begin
    register_i <= 16'b0000000010101100;
    end
  else begin
    register_i <= register_iVoted;
    register_i[15]    <= bof;
    register_i[14]    <= era;
    register_i[13]    <= erp;
    register_i[12]    <= war;

    if (can == 1'b1) begin
      register_i[11]  <= ssc;
      register_i[10]  <= src;
      end
    else if (cpu == 1'b1) begin
      register_i[11]  <= ssp;
      register_i[10]  <= srp;
      register_i[ 9]  <= rsp;
      register_i[8:6] <= sjw;
      register_i[5:3] <= tseg1;
      register_i[2:0] <= tseg2;  
      end
    end
end   

endmodule
