--
-- VHDL Package Header canakari.config
--
-- Created:
--          by - awalsemann.UNKNOWN (IMES17)
--          at - 14:17:26 19.02.2018
--
-- using Mentor Graphics HDL Designer(TM) 2016.1 (Build 8)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
PACKAGE config IS
    procedure write_register(
    register_address : in std_logic_vector(4 downto 0);
    register_data : in std_logic_vector(15 downto 0);
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic); 

  
  procedure read_register(
    register_address : in std_logic_vector(4 downto 0);
    register_data : out std_logic_vector(15 downto 0);
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);

    
   procedure configure_prescaler (
    divider : in integer range 2 to 32;
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);

	
  procedure configure_general (
    tseg1 : in integer range 1 to 8;
    tseg2 : in integer range 1 to 8;
    sjw : in integer range 0 to 7;
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);
  
  
  procedure soft_reset(
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);

  
  procedure enable_pl(
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);
  
  
  procedure configure_accmask(
    mask : in std_logic_vector(28 downto 0);
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);
      
  
  procedure configure_payload(
    payload : in std_logic_vector(63 downto 0);
    length : in integer range 0 to 8;
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);
  
  
  procedure configure_identifier(
    identifier : in std_logic_vector(10 downto 0);
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);
 
 
  procedure configure_ext_identifier(
    identifier : in std_logic_vector(28 downto 0);
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);

  
  procedure configure_tx_control(
    start_tx : in std_logic;
    remote : in std_logic;
    extended : in std_logic;
    length : in integer range 0 to 8;
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);

  
  procedure send_std_message(
    payload : in std_logic_vector(63 downto 0);
    length : in integer range 0 to 8;
    identifier : in std_logic_vector(10 downto 0);
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);

  
  procedure send_ext_message(
    payload : in std_logic_vector(63 downto 0);
    length : in integer range 0 to 8;
    identifier : in std_logic_vector(28 downto 0);
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);
 
 
  procedure send_ext_remote(
    identifier : in std_logic_vector(28 downto 0);
    length : in integer range 0 to 8;
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);
  
  
  procedure send_std_remote(
    identifier : in std_logic_vector(10 downto 0);
    length : in integer range 0 to 8;
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);
   
  procedure send_package(
    payload : in std_logic_vector(63 downto 0);
    length : in integer range 0 to 8;
    identifier : in std_logic_vector(28 downto 0);
    remote : in std_logic;
    extended : in std_logic;
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);
   
  function calculate_bitrate(clock , prescaler , tseg1, tseg2 : integer)
    return integer; 
  
  function calculate_samplepoint(tseg1, tseg2 : integer)
    return integer;
    
    
  procedure read_rx_control(
    received : out std_logic;
    length : out integer range 0 to 8;
    remote : out std_logic;
    extended : out std_logic; 
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);
    
  procedure wait_rx(
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);
    procedure read_payload(
    payload : out std_logic_vector(63 downto 0);
    length : in integer range 0 to 8;
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);
  
    
  procedure read_identifier(
    identifier : out std_logic_vector(10 downto 0);
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);
  
  
  procedure read_ext_identifier(
    identifier : out std_logic_vector(28 downto 0);
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);
   
   
  procedure read_package(
    payload : out std_logic_vector(63 downto 0);
    length : out integer range 0 to 8;
    identifier : out std_logic_vector(28 downto 0);
    remote : out std_logic;
    extended : out std_logic;   
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);
    
  procedure reset_rx_control(
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);
    
    
  procedure init_controller (
    prescaler : in integer range 2 to 32;
    tseg1 : in integer range 1 to 8;
    tseg2 : in integer range 1 to 8;
    sjw : in integer range 0 to 7;
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic);
END config;
