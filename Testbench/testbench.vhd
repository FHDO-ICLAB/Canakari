--
-- VHDL Architecture canakari.testbench.behave
--
-- Created:
--          by - awalsemann.UNKNOWN (IMES17)
--          at - 11:29:44 12.02.2018
--
-- using Mentor Graphics HDL Designer(TM) 2016.1 (Build 8)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

LIBRARY work;
USE work.config;
USE work.can_pattern_gen;

ENTITY testbench IS
END ENTITY testbench;

--
ARCHITECTURE behave OF testbench IS

  component dut_verilog IS
   PORT(clock            : IN  std_logic;
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
  end component dut_verilog;


  TYPE stimulus_type IS (H_RESET,S_RESET,N_CONFIG,SEND_N1_E,SEND_N1,SEND_N2,SEND_REMOTE,SEND_EXTENDED,STUFF_ERROR,CRC_ERROR,BIT_ERROR,RECV1,RECV2, N1_IDLE, FORM_ERROR, OVERLOAD_FRAME);

--############ Node1 DUT Connections ####################### 
  signal clk : std_logic := '1';
  signal reset : std_logic := '0';
  signal address : std_logic_vector(4 downto 0) := (others => '0');
  signal writedata : std_logic_vector(15 downto 0) := (others => '0');
  signal readdata : std_logic_vector(15 downto 0) := (others => '0');
  signal cs : std_logic := '0';
  signal read_n : std_logic := '0';
  signal write_n : std_logic := '0';
  signal irq : std_logic := '0';
  signal rx : std_logic := '0';
  signal tx : std_logic := '0';
  signal statedeb : std_logic_vector(7 DOWNTO 0) := (others=>'0');
  signal Prescale_EN_debug : std_logic := '0';
  signal bitst : std_logic_vector(6 DOWNTO 0)  := (others=>'0'); 
  signal irqstatus : std_logic;
  signal irqsuctra : std_logic;
  signal irqsucrec : std_logic;
  signal short : std_logic := '0';
  
--############ Node 2 DUT Connections #######################
  signal address2 : std_logic_vector(4 downto 0) := (others => '0');
  signal writedata2 : std_logic_vector(15 downto 0) := (others => '0');
  signal readdata2 : std_logic_vector(15 downto 0) := (others => '0');
  signal cs2 : std_logic := '0';
  signal read_n2 : std_logic := '0';
  signal write_n2 : std_logic := '0';
  --signal rx2 : std_logic := '0';
  signal tx2 : std_logic := '0'; 
 
--############ Patterngenerator Signals #######################  
  signal start_pg : std_logic := '0';
  signal tx_pg : std_logic := 'U';
  signal rx_pg : std_logic := '1';
  signal tx_ack_pg : std_logic := '1'; -- ACK for tx
  signal rx_ack_pg : std_logic := '1'; -- ACK for rx
  signal tx_type : can_pattern_gen.frame_type := can_pattern_gen.default_frame_type;

--############  Simulation signals #######################
  signal stimulus_step : stimulus_type := H_RESET;  
  signal error_gen : std_logic := '0';
  signal done : std_logic := '0';
  -- signal bit to show bit time in simulation
  signal bit_duration : std_logic := '0';

--############  Simulation config #######################
  --change clk_freq (main clk) only    
  constant clk_freq : integer range 2 to 2147483647 := 10000000;
  constant clk_half_period : time := (500000000/clk_freq)*1 ns;
  constant reset_time : time := (1000000000/clk_freq)*4 ns;

--############  DUT Configuration #######################  
  --change configuration parameter here 
  signal can_prescaler : integer range 2 to 32 := 10;
  signal can_tseg1 : integer range 1 to 8 := 4;
  signal can_tseg2 : integer range 1 to 8 := 5;
  signal can_sjw : integer range 0 to 7 := 2;

--############ Patterngenerator Check #######################
  --set canbus bitrate here 
  signal can_bitrate : integer range 1 to 2147483647 := 100000;
  --value must match the configured bitrate of the dut(tseg1,tseg2,etc.) 
  
--############ statedeb interpretation #######################  
--  alias idle : std_logic_vector(7 downto 0) := "00001001";


BEGIN
  assert(can_bitrate = config.calculate_bitrate(clk_freq,can_prescaler,can_tseg1,can_tseg2))
  report "Bitrate mismatch: DUT - " & integer'image(config.calculate_bitrate(clk_freq,can_prescaler,can_tseg1,can_tseg2)) & " vs. PG - " & integer'image(can_bitrate)  severity failure;

--############ DUT Portmap #######################  
can_node_1: dut_verilog port map(
     clock => clk,
     reset => reset,
     address => address,
     readdata => readdata,
     writedata => writedata,
     cs => cs,
     read_n => read_n,
     write_n => write_n,
     irq => irq,
     irqstatus => irqstatus,
     irqsuctra => irqsuctra,
     irqsucrec => irqsucrec,
     rx => rx,
     tx => tx,
     statedeb => statedeb,
     Prescale_EN_debug => Prescale_EN_debug, 
     bitst => bitst); 
     
can_node_2: dut_verilog port map(
     clock => clk,
     reset => reset,
     address => address2,
     readdata => readdata2,
     writedata => writedata2,
     cs => cs2,
     read_n => read_n2,
     write_n => write_n2,
     irq => open,
     irqstatus => open,
     irqsuctra => open,
     irqsucrec => open,
     rx => rx,
     tx => tx2,
     statedeb => open,
     Prescale_EN_debug => open, 
     bitst => bitst); 
     
--############ Main-CLK generation #######################    
  clk_stimulus: process
  begin
    clk <= '1';
    wait for clk_half_period;
    clk <= '0';
    wait for clk_half_period;
  end process;

--############ Patterngen Sync #######################    
  sync: process
  begin
    wait until falling_edge(tx);
    start_pg <= '1';
    wait until rising_edge(clk);
    start_pg <= '0';
    wait until rising_edge(tx);
  end process;
  
--############ State Machine #######################    
  fsm_name : process(statedeb)
  variable state_name : string(1 to 9) := (others => ' ');
  begin
      
  end process;
      
--############ Signal Comparision #######################     
  compare: process(clk)
  begin
    if rising_edge(clk) then
      case stimulus_step is
         when SEND_N1 =>
            assert((tx = tx_pg) or (tx_pg = 'U')) report "Error during TX - Waveform mismatch: " & can_pattern_gen.to_string(tx_type) severity note;
         when SEND_N2 =>
            assert((tx = tx_pg) or (tx_pg = 'U')) report "Error during TX - Waveform mismatch: " & can_pattern_gen.to_string(tx_type) severity note;
          when RECV1 => 
            assert((rx = '0') or (rx_ack_pg /= '0'))  report "Error during RX - No ACK" severity note; 
        when others =>
      end case;
    end if;
  end process;

--############ ACK / Bit Error Generation #######################
--  ack_error: process(clk)
--    begin
--      if can_pattern_gen.to_string(tx_type) = "ACK      " then
--        error_gen <= '1';
--        report "Ack Error generated";
--      else
--        error_gen <= '0';
--    end if;
--  end process;

--  bit_error: process(clk) --Bus off auslösen
--    begin
--      if can_pattern_gen.to_string(tx_type) = "DATA     " then
--        error_gen <= '1';
--        --report "Data Error generated";
--      else
--        error_gen <= '0';
--    end if;
--  end process;

         
        
--############ Main Stimulus Process #######################  
  stimulus: process
  
--############  RX-Package variables #######################  
  variable rx_payload : std_logic_vector(63 downto 0);
  variable rx_length : integer range 0 to 8;
  variable rx_identifier : std_logic_vector(28 downto 0);
  variable rx_remote : std_logic;
  variable rx_extended : std_logic; 
  variable rx_error_gen : std_logic_vector(3 downto 0) := (others => '0');
  
--############  TX-Package variables #######################  
  variable identifier : std_logic_vector(28 downto 0) :=  (others=>'0'); 
  variable ext_frame : std_logic := '0';
  variable remote : std_logic := '0';
  variable payload : std_logic_vector(63 downto 0) := (others=>'0'); 
  variable length : integer range 0 to 8 := 0;
  variable tx_error_gen : std_logic_vector(3 downto 0) := (others => '0');
  
  begin
    wait until rising_edge(clk);
    case stimulus_step is
 
--############  Async(hard)-Reset #######################       
        when H_RESET =>
          reset <= '0';
          wait for reset_time;
          reset <= '1';
          
          stimulus_step <= S_RESET;
          
--############  Soft-Reset #######################            
        when S_RESET =>
          --node 1
          config.soft_reset(clk,address,writedata,readdata,cs,read_n,write_n);
          -- node 2
          config.soft_reset(clk,address2,writedata2,readdata2,cs2,read_n2,write_n2);
          wait for reset_time;
          
          stimulus_step <= N_CONFIG;
          
--############  Configuration #######################            
        when N_CONFIG =>        
          -- Node 1
          config.init_controller(can_prescaler,can_tseg1,can_tseg2,can_sjw,clk,address,writedata,readdata,cs,read_n,write_n);
          config.configure_accmask(X"0000000" & '0', clk,address,writedata,readdata,cs,read_n,write_n);      
          wait for 100 ns;
          config.write_register("10010","1000000001110000",clk,address,writedata,readdata,cs,read_n,write_n); -- configure IRQUnit 
          -- Node 2
          config.init_controller(can_prescaler,can_tseg1,can_tseg2,can_sjw,clk,address2,writedata2,readdata2,cs2,read_n2,write_n2);
          config.configure_accmask(X"0000000" & '0', clk,address2,writedata2,readdata2,cs2,read_n2,write_n2);      
          wait for 100 ns;
          config.write_register("10010","1000000001110000",clk,address2,writedata2,readdata2,cs2,read_n2,write_n2); -- configure IRQUnit
          
          wait until statedeb = "00001001";
            stimulus_step <= SEND_REMOTE;
          
--############ SEND_REMOTE #######################                
        when SEND_REMOTE =>
          identifier := "100000000000000000" & "10101010100";
          ext_frame := '0';
          remote := '1';
          payload := X"00AAAAAAAAA00000";
          length := 3; --error with 3
          tx_error_gen := "0000";
          error_gen <= '0';
            
          config.send_package(payload,length,identifier,remote,ext_frame,clk,address,writedata,readdata,cs,read_n,write_n);
          can_pattern_gen.gen_tx_message(payload,length,identifier,remote,ext_frame,clk_freq,can_bitrate,tx_error_gen,clk,start_pg,tx_pg,tx_type,tx_ack_pg);

          wait until statedeb = "00001001"; 
          stimulus_step <= SEND_EXTENDED;
          
--############ SEND_EXTENDED #######################           
        when SEND_EXTENDED =>
          wait for 10 us; 
          identifier := "100110000001100000" & "10101010100";
          ext_frame := '1';
          remote := '0';
          payload := X"0000000000000000";
          length := 2;  
          error_gen <= '0';
          
          config.send_package(payload,length,identifier,remote,ext_frame,clk,address,writedata,readdata,cs,read_n,write_n);
          can_pattern_gen.gen_tx_message(payload,length,identifier,remote,ext_frame,clk_freq,can_bitrate,tx_error_gen,clk,start_pg,tx_pg,tx_type,tx_ack_pg);
          
          assert(rx_payload = payload) report "Error during RX - Payload mismatch" severity note;
          assert(rx_length = length) report "Error during RX - Length mismatch" severity note;
          assert(rx_identifier = identifier) report "Error during RX - Identifier mismatch" severity note;
          assert(rx_extended = ext_frame) report "Error during RX - Frameformat mismatch" severity note;
          assert(rx_remote = remote) report "Error during RX - Remotetype mismatch" severity note;
          
          wait until statedeb = "00001000";       
          stimulus_step <= OVERLOAD_FRAME;
          
--############ OVERLOAD_FRAME #######################     
        when OVERLOAD_FRAME =>
          wait for 10 us;
          identifier := "100110000001100000" & "10101010100";
          ext_frame := '0';
          remote := '0';
          payload := X"00AAAAAAAAA00000";
          length := 2;
          error_gen <= '0';
          config.send_package(payload,length,identifier,remote,ext_frame,clk,address,writedata,readdata,cs,read_n,write_n);
          can_pattern_gen.gen_tx_message(payload,length,identifier,remote,ext_frame,clk_freq,can_bitrate,tx_error_gen,clk,start_pg,tx_pg,tx_type,tx_ack_pg);

          wait until statedeb = "00000101";  -- inter_check       
          error_gen <= '1';
          wait until statedeb = "01000011";  -- over_firstdom  
          error_gen <= '0';
          wait until statedeb = "00001000";
          stimulus_step <= STUFF_ERROR;
          
 --############ STUFF_ERROR #######################            
        when STUFF_ERROR => 
          wait for 10us;
          rx_error_gen := "0001";
          identifier := "000000000000000000" & "10101010100";
          ext_frame := '0';
          remote := '0'; 
          payload := X"A1B1100000000000";
          length := 3;
          
          can_pattern_gen.gen_rx_message(payload,length,identifier,remote,ext_frame,clk_freq,can_bitrate,rx_error_gen,clk,rx_pg,tx_type,rx_ack_pg);
          --config.wait_rx(clk,address,writedata,readdata,cs,read_n,write_n);
          --config.read_package(rx_payload,rx_length,rx_identifier,rx_remote,rx_extended,clk,address,writedata,readdata,cs,read_n,write_n);
          wait until statedeb = "00001001";  
          stimulus_step <= FORM_ERROR;
          
--############ FORM_ERROR #######################            
        when FORM_ERROR => 
          wait for 10us;
          rx_error_gen := "0010";
          identifier := "000000000000000000" & "10101010100";
          ext_frame := '0';
          remote := '0'; 
          payload := X"A1B1100000000000";
          length := 3;
          
          can_pattern_gen.gen_rx_message(payload,length,identifier,remote,ext_frame,clk_freq,can_bitrate,rx_error_gen,clk,rx_pg,tx_type,rx_ack_pg);
          --config.wait_rx(clk,address,writedata,readdata,cs,read_n,write_n);
          --config.read_package(rx_payload,rx_length,rx_identifier,rx_remote,rx_extended,clk,address,writedata,readdata,cs,read_n,write_n);
          
          wait until statedeb = "00001001";  
          stimulus_step <= BIT_ERROR;
          
--############ BIT_ERROR #######################            
        when BIT_ERROR => 
          identifier := "100000000000000000" & "10101010100";
          ext_frame := '0';
          remote := '0';
          payload := X"00AAAAAAAAA00000";
          length := 3; --error with 3
          tx_error_gen := "0000";
          error_gen <= '0';
          
          config.send_package(payload,length,identifier,remote,ext_frame,clk,address,writedata,readdata,cs,read_n,write_n);
          --can_pattern_gen.gen_tx_message(payload,length,identifier,remote,ext_frame,clk_freq,can_bitrate,tx_error_gen,clk,start_pg,tx_pg,tx_type,tx_ack_pg);
          
          wait until statedeb = "00011000"; --tra_data_shifting
          error_gen <= '1';
          wait until statedeb = "01010011";  --erroractiv_senddomb
          error_gen <= '0';
          wait until statedeb = "00001001";
          stimulus_step <= CRC_ERROR;
          
 --############ CRC_ERROR #######################
        when CRC_ERROR => 
          wait for 100 us;
          identifier := "000000000000000000" & "10101010100";
          ext_frame := '0';
          remote := '0';
          payload := X"A1B1100000000000";
          length := 3;  
          rx_error_gen := "1000";
          
          can_pattern_gen.gen_rx_message(payload,length,identifier,remote,ext_frame,clk_freq,can_bitrate,rx_error_gen,clk,rx_pg,tx_type,rx_ack_pg);
          --config.wait_rx(clk,address,writedata,readdata,cs,read_n,write_n);
          --config.read_package(rx_payload,rx_length,rx_identifier,rx_remote,rx_extended,clk,address,writedata,readdata,cs,read_n,write_n);
          assert(rx_payload = payload) report "Error during RX - Payload mismatch" severity note;
          assert(rx_length = length) report "Error during RX - Length mismatch" severity note;
          assert(rx_identifier = identifier) report "Error during RX - Identifier mismatch" severity note;
          assert(rx_extended = ext_frame) report "Error during RX - Frameformat mismatch" severity note;
          assert(rx_remote = remote) report "Error during RX - Remotetype mismatch" severity note;
          
          --End Simulation
          wait until statedeb = "00001001";       
          assert false report "simulation done" severity failure;
        
        when others =>
          stimulus_step <= H_RESET;
    end case;
  end process;
  
rx <= ((tx and tx2) and tx_ack_pg) xor error_gen; --(((tx and reset) or (not reset)) and tx_ack_pg and rx_pg) or error_gen; --rx <= tx for bus off

END ARCHITECTURE behave;

