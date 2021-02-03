////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : decapsulation2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : decapsulation unit
// Commentary   : Nur noch Identitifier für LLC, Register aufbereiten, Daten nun direkt aus
//                rshift in IOCPU, da fastshift an gleiche Positionen schiebt. Keine Register
//                mehr, message_b, message_c kommen aus rshift (b: 88 downto 71 (18 Bit ext-id))
//                (c: 101 downto 91 (11 Bit bas-id))
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

module decapsulation2 (
  input  wire [17:0] message_b,
  input  wire [10:0] message_c,
  input  wire        extended,
  output reg  [28:0] identifier
  );

always@(message_b, message_c, extended)
begin
  if(extended == 1'b0)  // BASIC Datenrahmen, id sitzt unten am Anfang des Extended Feldes
   begin
    identifier [28:18] = message_b[10:0];
    identifier [17: 0] = 18'd0;
   end
  else                 
   begin   // Extended Datenrahmen, id sitzt passend
    identifier [28:18] = message_c;
    identifier [17: 0] = message_b;
   end
end

endmodule
