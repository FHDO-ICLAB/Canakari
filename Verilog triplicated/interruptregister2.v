////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : interrupregister2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : Interrupt register speichert sowohl IRQ-Informationen f�r die CPU
//                als auch die enable signale.
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

module interrupregister2(
    input wire clk,
    input wire rst,
    input wire cpu,            // CPU wuenscht Zugriff
    input wire can,            // controller wuenscht Zugriff
    input wire onoffnin,
    input wire iestatusp,
    input wire iesuctrap,
    input wire iesucrecp,
    input wire irqstatusp,
    input wire irqsuctrap,
    input wire irqsucrecp,
    input wire irqstatusc,
    input wire irqsuctrac,
    input wire irqsucrecc,
    output wire [15:0] register  // Interruptregister
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
    register_i <= 16'd0;
  end
  else if (can == 1'b1) begin
    if (irqstatusc == 1'b1)
      register_i[2] <= irqstatusc;   // Nur Setzen des Status Interruptes m�glich
    if (irqsuctrac == 1'b1)
      register_i[1] <= irqsuctrac;   // Nur Setzen des Successful transmit Interruptes moeglich 
    if (irqsucrecc == 1'b1)
        register_i[0] <= irqsucrecc;   // Nur Setzen des Successful receive Interruptes moeglich       
    end
  else if (cpu == 1'b1) begin
    register_i[15] <= onoffnin;
    register_i[6]  <= iestatusp;
    register_i[5]  <= iesuctrap;
    register_i[4]  <= iesucrecp;
    if (irqstatusp == 1'b0)       // Nur R�cksetzen des Status Interruptes m�glich
     register_i[2] <= irqstatusp;
    if (irqsuctrap == 1'b0)       // Nur R�cksetzen des Tranmit Interruptes m�glich
     register_i[1] <= irqsuctrap;
    if (irqsucrecp == 1'b0)       // Nur R�cksetzen des Receive Interruptes m�glich
     register_i[0] <= irqsucrecp;      
    end
  else
    register_i <= register_iVoted;
end
    
endmodule
