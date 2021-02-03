////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : rcrc_cell2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : RCRC_CELL
//                F�r optimierte Synthese: Ein einfaches Register, synchroner
//                reset (act. low) und taktabh�ngigem input (pos. edge)
// Commentary   : Changed portname input (VHDL) to Input. 
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

module rcrc_cell2(
    input  wire enable,
    input  wire clock,
    input  wire reset,
    input  wire Input,    
    output wire q
    );

//tmrg default triplicate
//tmrg tmr_error false

reg edge_var;
reg q_i;

//triplication signal
wire edge_varVoted = edge_var;
wire q_iVoted = q_i;
assign q = q_iVoted;

always@(posedge clock)
begin
  if (reset == 1'b0) begin    // synchronous reset (active low)
        q_i <= 1'b0;
        edge_var = 1'b0;
        end
  else begin
    q_i <= q_iVoted;
    edge_var = edge_varVoted;
    if ((enable == 1'b1) && (edge_varVoted == 1'b0)) begin
        q_i <= Input;
        edge_var = 1'b1;
        end
    else if ((enable == 1'b0) && (edge_varVoted == 1'b1)) begin
        edge_var = 1'b0;
        end
    end
end 
endmodule
