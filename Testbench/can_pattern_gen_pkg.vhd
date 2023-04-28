--
-- VHDL Package Header canakari.can_pattern_gen
--
-- Created:
--          by - awalsemann.UNKNOWN (IMES17)
--          at - 11:44:50 22.02.2018
--
-- using Mentor Graphics HDL Designer(TM) 2016.1 (Build 8)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

PACKAGE can_pattern_gen IS

TYPE frame_type IS (SOF, IDENT, RTR, SRR, IDE, RESERVED, DLC, DATA, CRC,CRCDELIM, ACK, ACKDELIM, EOF, STUFF, UNDEFINED);
constant default_frame_type : frame_type := UNDEFINED;
type can_frame_type is array (127 downto 0) of frame_type;
type can_frame_stuffed_type is array (153 downto 0) of frame_type;
 
function to_string(x : frame_type)
  return String;

function crc_step(d_in: std_logic;
	crc:  std_logic_vector(14 downto 0);
	error_gen : std_logic_vector(3 downto 0))
    return std_logic_vector;
  
  
function gen_crc(frame : std_logic_vector; start_index, length : integer; error_gen : std_logic_vector(3 downto 0))
	return std_logic_vector; 

  
procedure gen_data_frame (
	identifier : in std_logic_vector(28 downto 0);
	extended : in std_logic;
	payload : in std_logic_vector(63 downto 0);
	length : in integer range 0 to 8;
	error_gen : in std_logic_vector(3 downto 0);
	can_frame : out std_logic_vector(127 downto 0);
	type_frame : out can_frame_type;
	frame_end : out integer range 0 to 127);
	

procedure gen_remote_frame(
	identifier : in std_logic_vector(28 downto 0);
	extended : in std_logic;
	length : in integer range 0 to 8;
	can_frame : out std_logic_vector(127 downto 0);
	type_frame : out can_frame_type;
	frame_end : out integer range 0 to 127;
	error_gen : in std_logic_vector(3 downto 0));  
	
  
procedure stuff_signals(c_frame : in std_logic_vector(127 downto 0);
  t_frame : in can_frame_type;
  frame_end : in integer range 0 to 127;
	stuffed_can_frame : out std_logic_vector(153 downto 0);
  stuffed_type_frame : out can_frame_stuffed_type;
  stuffed_frame_end : out integer range 0 to 153);
 

 function calc_bitclk(clk_freq_hz : integer range 0 to 2147483647;
    bit_freq_hz : integer range 0 to 2147483647)
	return integer;
  
  
 procedure wait_bit_clk(signal clk : in std_logic;
	div : integer range 0 to 512);
		

procedure gen_tx_message( payload : in std_logic_vector(63 downto 0);
  length : in integer range 0 to 8;
  identifier : in std_logic_vector(28 downto 0);
  remote : in std_logic;
  extended : in std_logic;
  clk_freq_hz : integer range 0 to 2147483647;
  bit_freq_hz : integer range 0 to 2147483647;
  tx_error_gen : in std_logic_vector(3 downto 0);
  signal clk : in std_logic;
  signal start : in std_logic;
 	signal tx : out std_logic;
	signal tx_type : out frame_type;
	signal ack_gen : out std_logic);

procedure gen_rx_message( payload : in std_logic_vector(63 downto 0);
  length : in integer range 0 to 8;
  identifier : in std_logic_vector(28 downto 0);
  remote : in std_logic;
  extended : in std_logic;
  clk_freq_hz : integer range 0 to 2147483647;
  bit_freq_hz : integer range 0 to 2147483647;
  rx_error_gen : std_logic_vector(3 downto 0);
  signal clk : in std_logic;
 	signal tx : out std_logic;
	signal tx_type : out frame_type;
	signal ack_gen : out std_logic);
  
END can_pattern_gen;
