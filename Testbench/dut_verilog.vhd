----------------------------------------------------------------------------------------------------
--
-- Interessengruppe fuer Mikroelektronik und Eingebettete Systeme (IMES)
-- Fachhochschule Dortmund
--
-- Filename     : dut_verilog.vhd
-- Author       : Beer
-- Tool         : Mentor Graphics HDL Designer(TM) 2015.1b (Build 4)
-- Description  : Wrapper Block for the verification of the verilog CANakari
--                 
--
-- Changelog:
-- -------------------------------------------------------------------------------------------------
-- Version | Author             | Date       | Changes
-- -------------------------------------------------------------------------------------------------
-- 1.0     | Beer              | 09.06.2019 | created
-- -------------------------------------------------------------------------------------------------
--
----------------------------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY dut_verilog IS
   PORT(clock            : IN std_logic;
       reset             : IN  std_logic;
       address           : IN  std_logic_vector(4 DOWNTO 0);
       writedata         : IN  std_logic_vector (15 DOWNTO 0);
       cs                : IN  std_logic;
       read_n            : IN  std_logic;
       write_n           : IN  std_logic;
	   rx                : IN  std_logic;
       irq               : OUT std_logic;
       irqstatus         : OUT std_logic;
       irqsuctra         : OUT std_logic;
       irqsucrec         : OUT std_logic;
	   readdata          : OUT std_logic_vector(15 DOWNTO 0);
       tx                : OUT std_logic; 
       statedeb          : OUT std_logic_vector(7 DOWNTO 0);
       Prescale_EN_debug : OUT std_logic; 
       bitst             : OUT std_logic_vector(6 DOWNTO 0) ); 
END ENTITY dut_verilog;

ARCHITECTURE behv OF dut_verilog IS

	COMPONENT can2 IS
	
	--GENERIC (
	--	system_id : bit_vector(15 DOWNTO 0) := (x"CA05") );
	
	PORT(clock             : IN  std_logic;
		 reset             : IN  std_logic;
		 address           : IN  std_logic_vector(4 DOWNTO 0);
		 readdata          : OUT std_logic_vector(15 DOWNTO 0);  -- Avalon lesedaten
		 writedata         : IN  std_logic_vector (15 DOWNTO 0);
		 cs                : IN  std_logic;  -- Avalon Chip Select
		 read_n            : IN  std_logic;  -- Avalon read enable active low
		 write_n           : IN  std_logic;  -- Avalon write enable active low
		 irq               : OUT std_logic;
		 irqstatus         : OUT std_logic;
		 irqsuctra         : OUT std_logic;
		 irqsucrec         : OUT std_logic;
		 rx                : IN  std_logic;     -- CAN-BUS
		 tx                : OUT std_logic;     -- CAN-BUS
		 statedeb          : OUT std_logic_vector(7 DOWNTO 0);
		 Prescale_EN_debug : OUT std_logic;     -- DW 2005.06.25 Debug Prescale
		 bitst             : OUT std_logic_vector(6 DOWNTO 0) );
	END COMPONENT can2;    
	
	BEGIN
	
	can_controller : can2 PORT MAP (
	 clock 				=> clock,
	 reset 				=> reset,
	 address 			=> address,
	 readdata			=> readdata,        
	 writedata 			=> writedata,
	 cs 				=> cs,              
	 read_n 			=> read_n,           
	 write_n 			=> write_n,          
	 irq 				=> irq,
	 irqstatus 			=> irqstatus,
	 irqsuctra 			=> irqsuctra,
	 irqsucrec 			=> irqsucrec,
	 rx 				=> rx,               
	 tx 				=> tx,              
	 statedeb 			=> statedeb,
	 Prescale_EN_debug 	=> Prescale_EN_debug,
	 bitst 				=> bitst
	 );
	 
	 END ARCHITECTURE behv;