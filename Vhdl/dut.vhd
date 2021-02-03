
-- VHDL Architecture canakari.dut.behave
--
-- Created:
--          by - awalsemann.UNKNOWN (IMES17)
--          at - 09:09:21 13.02.2018
--
-- using Mentor Graphics HDL Designer(TM) 2016.1 (Build 8)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY dut IS
   PORT(clock            : IN std_logic;
       reset             : IN  std_logic;
       address           : IN  std_logic_vector(4 DOWNTO 0);
       readdata          : OUT std_logic_vector(15 DOWNTO 0);
       writedata         : IN  std_logic_vector (15 DOWNTO 0);
       cs                : IN  std_logic;
       read_n            : IN  std_logic;
       write_n           : IN  std_logic;
       irq               : OUT std_logic;
       irqstatus         : OUT std_logic;
       irqsuctra         : OUT std_logic;
       irqsucrec         : OUT std_logic;
       rx                : IN  std_logic;
       tx                : OUT std_logic; 
       statedeb          : OUT std_logic_vector(7 DOWNTO 0);
       Prescale_EN_debug : OUT std_logic; 
       bitst             : OUT std_logic_vector(6 DOWNTO 0) ); 
END ENTITY dut;

--
ARCHITECTURE behave OF dut IS
  
  signal clock_bit : bit;
  signal reset_bit : bit;
  signal rx_bit : bit;
  signal Prescale_EN_debug_bit : bit;
  signal irq_bit : bit;
  signal tx_bit : bit;
  signal address_bit : bit_vector(4 DOWNTO 0);
  signal irqstatus_bit : bit;
  signal irqsuctra_bit : bit;
  signal irqsucrec_bit : bit;
  function bit_to_stdlogic(x : bit)
    return std_logic is
  begin
    if(x = '1') then
      return '1';
    else
      return '0';
    end if;
  end bit_to_stdlogic;
  
  component can1 is
    GENERIC (
        system_id : bit_vector(15 DOWNTO 0) := (x"CA05") );    -- an ID to probe for existence
                                                                     -- of HW
    PORT(clock             : IN bit;
         reset             : IN  bit;
         address           : IN  bit_vector(4 DOWNTO 0);
         readdata          : OUT std_logic_vector(15 DOWNTO 0);  -- Avalon lesedaten
         writedata         : IN  std_logic_vector (15 DOWNTO 0);
         cs                : IN  std_logic;  -- Avalon Chip Select
         read_n            : IN  std_logic;  -- Avalon read enable active low
         write_n           : IN  std_logic;  -- Avalon write enable active low
         irq               : OUT bit;
         irqstatus         : OUT bit;
         irqsuctra         : OUT bit;
         irqsucrec         : OUT bit;
         rx                : IN  bit;     -- CAN-BUS
         tx                : OUT bit;     -- CAN-BUS
         statedeb          : OUT std_logic_vector(7 DOWNTO 0);
         Prescale_EN_debug : OUT bit;     -- DW 2005.06.25 Debug Prescale
         bitst             : OUT std_logic_vector(6 DOWNTO 0) );
  END component can1;
    
BEGIN
  clock_bit <= to_bit(clock);
  reset_bit <= to_bit(reset);
  rx_bit <= to_bit(rx); 
  Prescale_EN_debug <= bit_to_stdlogic(Prescale_EN_debug_bit);
  irq <= bit_to_stdlogic(irq_bit);
  tx <= bit_to_stdlogic(tx_bit);
  address_bit <= to_bitvector(address);
  irqstatus <= bit_to_stdlogic(irqstatus_bit);
  irqsuctra <= bit_to_stdlogic(irqsuctra_bit);   
  irqsucrec <= bit_to_stdlogic(irqsucrec_bit);               
  
  can_controller: can1 port map(clock => clock_bit,
     reset => reset_bit,
     address => address_bit,
     readdata => readdata,
     writedata => writedata,
     cs  => cs,
     read_n => read_n,
     write_n => write_n,
     irq => irq_bit,
     irqstatus => irqstatus_bit,
     irqsuctra => irqsuctra_bit,
     irqsucrec => irqsucrec_bit,
     rx => rx_bit,
     tx => tx_bit,
     statedeb => statedeb,
     Prescale_EN_debug => Prescale_EN_debug_bit,
     bitst => bitst);
END ARCHITECTURE behave;



