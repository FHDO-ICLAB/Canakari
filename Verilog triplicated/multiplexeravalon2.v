////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
// Fachhochschule Dortmund
//
// Filename     : multiplexer2.v
// Author       : Leduc
// Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
// Description  : Adressmultiplexer
//                Unterteilung in Multiplexer, 
//                CPU liest: read_mux und Demux, 
//                CPU schreibt: writedemux
//                write_demultiplexer: write_demux
//                read_multiplexer: read_mux 
// Commentary   : Functions to convert bit to std_logic and vice versa (VHDL) are not translated.
//                Assign writedata_i translated outside of process (VHDL).
//                Feedthrough from writedata (input port) to regbus (output port) detected.
// Changelog:
// -------------------------------------------------------------------------------------------------
// Version | Author             | Date       | Changes
// -------------------------------------------------------------------------------------------------
// 0.9     | Leduc              | 21.05.2019 | created
// -------------------------------------------------------------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////////////////////////

//`resetall
//`timescale 1ns/10ps
//`default_nettype none

module multiplexer2( 
        output wire [15:0] readdata,
//      input  wire clock,
        input  wire [15:0] writedata, // in  std_logic_vector(15 DOWNTO 0);
        input  wire [4:0]  address,   // IN    bit_vector(4 DOWNTO 0);
        input  wire        cs,        // in  std_logic;
        input  wire        read_n,    // in  std_logic;
        input  wire        write_n,   // in  std_logic;
    // Aus�nge der Register (CPU-Read-cycle)
        input  wire [15:0] preregr,   // prescale register
        input  wire [15:0] genregr,   // general register
        input  wire [15:0] intregr,   // Interrupt register
        input  wire [15:0] traconr,   // transmit message control register
        input  wire [15:0] traar1r,   // arbitration Bits 28 - 13
        input  wire [15:0] traar2r,   // arbitration Bits 12 - 0 
        input  wire [15:0] trad01r,   // data0 + data1
        input  wire [15:0] trad23r,   // data2 + data3
        input  wire [15:0] trad45r,   // data4 + data5
        input  wire [15:0] trad67r,   // data6 + data7
        input  wire [15:0] recconr,   // receive message control register
        input  wire [15:0] accmask1r, // Acceptance Mask Register1
        input  wire [15:0] accmask2r, // Acceptance Mask Register2
        input  wire [15:0] recar1r,   // arbitration Bits 28 - 13
        input  wire [15:0] recar2r,   // arbitration Bits 12 - 0 
        input  wire [15:0] recd01r,   // data0 + data1
        input  wire [15:0] recd23r,   // data2 + data3
        input  wire [15:0] recd45r,   // data4 + data5
        input  wire [15:0] recd67r,   // data6 + data7
        input  wire [15:0] fehlregr,
        output wire [15:0]  regbus,  // Interner Bus
    // Aktivierungssignale (CPU-write-cycle)
        output wire presca,
        output wire genrega,    // activate general register
        output wire intrega,    // activate Interrupt register 
        output wire tracona,    // activate transmit message control register
        output wire traar1a,    // activate arbitration Bits 28 - 13
        output wire traar2a,    // activate arbitration Bits 12 - 0 
        output wire trad01a,    // activate data0 + data1
        output wire trad23a,    // activate data2 + data3
        output wire trad45a,    // activate data4 + data5
        output wire trad67a,    // activate data6 + data7
        output wire reccona,    // activate receive message control register
        output wire recar1a,    // activate arbitration Bits 28 - 13w
        output wire recar2a,    // activate arbitration Bits 12 - 0 + 3 Bits reserved
        output wire accmask1a,  // activate Acceptance Mask Register1
        output wire accmask2a   // activate Acceptance Mask Register2
);

//tmrg default triplicate
//tmrg tmr_error false

parameter [15:0] system_id = 16'hCA05; // HW-ID

  // wire [15:0] data_regin_i ;
  wire [15:0] data_regout_i;  // Ausgang des gew�hlten Registers
  wire [15:0] writedata_i;
  reg  [15:0] data_tri_out;
  reg         activ_i;
  wire        write_sig, read_sig;

// Registerausg�nge liegen nur von der Adresse abh�ngig auf dem internen Signal data_out_i

 read_mux2 #(
      .system_id (system_id))    // HW-ID Prameter
      read_multiplexer (
      .address   ( address   ),
      .preregr   ( preregr   ),
      .genregr   ( genregr   ),
      .intregr   ( intregr   ),
      .traconr   ( traconr   ),
      .traar1r   ( traar1r   ),
      .traar2r   ( traar2r   ),
      .trad01r   ( trad01r   ),
      .trad23r   ( trad23r   ),
      .trad45r   ( trad45r   ),
      .trad67r   ( trad67r   ),
      .recconr   ( recconr   ),
      .accmask1r ( accmask1r ),
      .accmask2r ( accmask2r ),
      .recar1r   ( recar1r   ),
      .recar2r   ( recar2r   ),
      .recd01r   ( recd01r   ),
      .recd23r   ( recd23r   ),
      .recd45r   ( recd45r   ),
      .recd67r   ( recd67r   ),
      .fehlregr  ( fehlregr  ),
      .data_out  ( data_regout_i)
      );
      
// Abh�ngig von der Adresse wird das activ_i (intern) Signal auf die Register verteilt. 
      
  write_demux2 write_demultiplexer(
      .address    ( address ),
      .activ_in   ( activ_i ),
      .activ_out  ({intrega,      //activ_out[14]
                    accmask1a,    //activ_out[13]
                    accmask2a,    //activ_out[12]
                    presca,       //activ_out[11]
                    genrega,      //activ_out[10]
                    tracona,      //activ_out[9]
                    traar1a,      //activ_out[8]
                    traar2a,      //activ_out[7]
                    trad01a,      //activ_out[6]
                    trad23a,      //activ_out[5]
                    trad45a,      //activ_out[4]
                    trad67a,      //activ_out[3]
                    reccona,      //activ_out[2]
                    recar1a,      //activ_out[1]
                    recar2a})     //activ_out[0]
      );
        
// Buszugriffslogik    

assign regbus   = writedata_i;    // Verbindung aller Eing�nge auf regbus
assign readdata = data_tri_out;

assign read_sig  = cs & (~ read_n);    // 1, wenn cs=1, read_n=0 
assign write_sig = cs & (~ write_n);   // 1, wenn cs=1, write_n=0  
assign writedata_i = writedata;      
  
// Tristate: CPU liest, Controller schreibt auf Datenbus  

always@(read_sig, data_regout_i) 
begin
  if (read_sig == 1'b1)
    data_tri_out = data_regout_i;
  else 
    data_tri_out = 16'd0;
  end

// CPU schreibt, aktivierungssignal an write_demux leiten, die das entsprechende Register aktiviert 
// und die Daten ueber den regbus dorthin weiterleitet

always@(write_sig)  // Process RW
begin
  if (write_sig == 1'b1)
    activ_i = 1'b1;
  else
    activ_i = 1'b0;
  end    
  
endmodule
