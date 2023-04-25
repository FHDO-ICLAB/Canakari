`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.12.2022 17:56:06
// Design Name: 
// Module Name: AxiCan_Zustands
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//TO-DO:
//Schnittstelle um Speichern der Read-Daten erweitern???
//Speicher auf negedge Clk und read_n, cs Signale??
//Speichern damit bei posedge für Read vom Axi die Daten sicher vorliegen!!
module AxiCan_Zustands(
//Axi Signale
input s_axi_aclk,
input s_axi_aresetn,
input wire [7:0] s_axi_araddr,
input wire s_axi_arvalid,
output reg s_axi_arready,
input wire [7:0] s_axi_awaddr,
input wire s_axi_awvalid,
output reg s_axi_awready,
input wire s_axi_bready,
output wire [1:0] s_axi_bresp,
output reg s_axi_bvalid,
input wire s_axi_rready,
output reg [31:0] s_axi_rdata,
output wire [1:0] s_axi_rresp,
output reg s_axi_rvalid,
input wire [31:0] s_axi_wdata,
input wire [3:0] s_axi_wstrb,
input wire s_axi_wvalid,
output reg s_axi_wready,
//output reg [3:0] state,//Infovariable für Simulation (welcher Zustand) 
//Canakari Signale (ungenutzt)
output wire irq,
output wire irqstatus,
output wire irqsuctra,
output wire irqsucrec,
input wire rx,
output wire tx,
output wire [7:0] statedeb,
output wire Prescale_EN_debug,
output wire [6:0] bitst
//test
//output reg [15:0] WriteDatainfo
);

//Signale für Kommunikation mit Canakari    
 reg  [ 4:0] address;
 wire [15:0] readdata;           // Avalon lesedaten
 reg  [15:0] writedata;
 reg         cs;                 // Avalon Chip Select
 reg         read_n;             // Avalon read enable active low
 reg         write_n;            // Avalon write enable active low
 
 //Zustände der Zustandsmaschine
 parameter Off=0,w_Adr=1,w_Data=2,w_Resp=3,r_Adr=4,r_Is=5,r_Data=6;   // //_1=2,w_Data_2=3
 reg [2:0] next_state=0,state=0;
 
 //Zwischenspeicher
 reg [7:0] address_ZS; 
 reg [15:0] writedata_ZS;
 reg [15:0] readdata_ZS;
 //Aufruf Can Controller
 can2 CANSourceCode(
 .clock(s_axi_aclk),
 .reset(s_axi_aresetn),
 .address(address),
 .writedata(writedata),
 .readdata(readdata),
 .read_n(read_n),
 .write_n(write_n),
 .cs(cs),
 .irq(irq),
 .irqstatus(irqstatus),
 .irqsuctra(irqsuctra),
 .irqsucrec(irqsucrec),
 .rx(rx),
 .tx(tx),
 .statedeb(statedeb),
 .Prescale_EN_debug(Prescale_EN_debug),
 .bitst(bitst)
 );
 //Feste Zuweisungen
 assign s_axi_bresp = 2'b00;//OKAY 
 assign s_axi_rresp = 2'b00; 
 
always@(posedge s_axi_aclk,negedge s_axi_aresetn)
begin//Clocktakt und Reset
if (~s_axi_aresetn)
 state <= Off;
else
 state <= next_state;
end

always@(*)
 begin//state_transition_logic
  case(state) 
     Off:begin
      if(s_axi_awvalid && s_axi_wvalid)
       next_state <= w_Adr;
      else if(s_axi_arvalid && s_axi_rready)
       next_state <= r_Adr;
      else 
       next_state <= Off;
     end
//Write Address
     w_Adr: next_state <= w_Data;
//Write Data
     w_Data:  next_state <= w_Resp;
//Write Response
     w_Resp: next_state <= Off;
//Read Address
     r_Adr: next_state <= r_Is;
//Read_ZS
     r_Is: next_state <= r_Data;
//Read Data
     r_Data: next_state <= Off;
 endcase
end    

always@(state)
 begin//output_logic
 //default AXI
 s_axi_awready <= 0;
 s_axi_wready  <= 0;
 s_axi_bvalid  <= 0;
 s_axi_arready <= 0;
 s_axi_rvalid  <= 0; 
 s_axi_rdata <= 32'd0;
 //default CAN
 cs <= 0;
 write_n <= 1;
 read_n <= 1;
 address <= 5'd0;
 writedata <= 16'd0;
 
  case(state)
//Write Address Data to Canakari 
   w_Adr: begin
           write_n <= 0;
           address <= address_ZS[6:2];
           writedata <= writedata_ZS;  
          end
//Write Data in Canakari
   w_Data: begin
            s_axi_awready <= 1;
            s_axi_wready <= 1;
            write_n <= 0;
            cs <= 1;
            address <= address_ZS[6:2];
            writedata <= writedata_ZS;   
           end
//Write Response 
   w_Resp: begin
            s_axi_bvalid <= 1;
            write_n <= 0;
            cs <= 1;
            address <= address_ZS[6:2];
            writedata <= writedata_ZS; 
           end
//Read  Address **********************************************************************
   r_Adr: begin
           address <= address_ZS[6:2];
           read_n <= 0;
          end
//Read ZS
   r_Is: begin
          s_axi_arready <= 1;
          address <= address_ZS[6:2];
          read_n <= 0;
          cs <= 1;
         end   
//Read Data   
   r_Data:begin
           s_axi_rvalid <= 1;
           s_axi_rdata <= {16'd0,readdata_ZS};
           read_n <= 0;
           cs <= 1;
          end
  endcase
 end
 
 //Zwischenspeichern der Adresse
 always@(posedge s_axi_aclk,negedge s_axi_aresetn)
 begin
  if(s_axi_awvalid && s_axi_wvalid && ~s_axi_awready)
   address_ZS <= s_axi_awaddr[7:0];
  else if(s_axi_arvalid && s_axi_rready && ~s_axi_rvalid)
   address_ZS <= s_axi_araddr[7:0];
  else if(~s_axi_aresetn)
   address_ZS <= 8'd0;
  end
  
 //Zwischenspeichern Write Data
 always@(posedge s_axi_aclk,negedge s_axi_aresetn)
 begin
  if(s_axi_wvalid && s_axi_awvalid && ~s_axi_awready )
   writedata_ZS <= s_axi_wdata[15:0];
  else if(~s_axi_aresetn)
   writedata_ZS <= 16'd0;
  end
  
//Zwischenspeichern Read Data  
 always@(posedge s_axi_aclk,negedge s_axi_aresetn)
 begin
  if(~read_n && cs && ~s_axi_rvalid)
   readdata_ZS <= readdata;
  else if(~s_axi_aresetn)
   readdata_ZS <= 16'd0;
 end

endmodule
