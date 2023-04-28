--
-- VHDL Package Body canakari.can_pattern_gen
--
-- Created:
--          by - awalsemann.UNKNOWN (IMES17)
--          at - 09:39:02 22.02.2018
--
-- using Mentor Graphics HDL Designer(TM) 2016.1 (Build 8)
--

PACKAGE BODY can_pattern_gen IS


function to_string(x : frame_type) return String is
  variable tmp : string(1 to 9) := (others => ' ');
  begin
    case x is
      when SOF => tmp :=      "SOF      ";
      when IDENT => tmp :=    "IDENT    ";
      when RTR => tmp :=      "RTR      ";
      when SRR => tmp :=      "SRR      ";
      when IDE => tmp :=      "IDE      ";
      when RESERVED => tmp := "RESERVED ";
      when DLC => tmp :=      "DLC      ";
      when DATA => tmp :=     "DATA     ";
      when CRC => tmp :=      "CRC      ";
      when CRCDELIM => tmp := "CRCDELIM ";
      when ACK => tmp :=      "ACK      ";
      when ACKDELIM => tmp := "ACKDELIM ";
      when EOF => tmp :=      "EOF      ";
      when STUFF => tmp :=    "STUFF    ";
      when UNDEFINED => tmp :="UNDEFINED";
    end case;
  return tmp;
end to_string; 

  function crc_step
    (d_in: std_logic;
     crc:  std_logic_vector(14 downto 0);
     error_gen : std_logic_vector(3 downto 0))
    return std_logic_vector is

    variable d:      std_logic_vector(0 downto 0);
    variable crc_next: std_logic_vector(14 downto 0);
  begin
    d(0) := d_in;
    if error_gen = "1000" then
      crc_next(0) := d(0) xnor crc(14);
    else
      crc_next(0) := d(0) xor crc(14);
    end if;
    crc_next(1) := crc(0);
    crc_next(2) := crc(1);
    crc_next(3) := d(0) xor crc(2) xor crc(14);
    crc_next(4) := d(0) xor crc(3) xor crc(14);
    crc_next(5) := crc(4);
    crc_next(6) := crc(5);
    crc_next(7) := d(0) xor crc(6) xor crc(14);
    crc_next(8) := d(0) xor crc(7) xor crc(14);
    crc_next(9) := crc(8);
    crc_next(10) := d(0) xor crc(9) xor crc(14);
    crc_next(11) := crc(10);
    crc_next(12) := crc(11);
    crc_next(13) := crc(12);
    crc_next(14) := d(0) xor crc(13) xor crc(14);
    return crc_next;
  end crc_step;
  
  function gen_crc(frame : std_logic_vector; start_index, length : integer; error_gen : std_logic_vector(3 downto 0))
    return std_logic_vector is
    
    variable crc: std_logic_vector(14 downto 0);
  begin
    crc := (others => '0');
    for i in 0 to length-1 loop
      crc := crc_step(frame(start_index-i),crc, error_gen); 
    end loop;
    return crc;
  end gen_crc;
  
  
procedure gen_data_frame (
	identifier : in std_logic_vector(28 downto 0);
	extended : in std_logic;
	payload : in std_logic_vector(63 downto 0);
	length : in integer range 0 to 8;
	error_gen: in std_logic_vector(3 downto 0);
	can_frame : out std_logic_vector(127 downto 0);
	type_frame : out can_frame_type;
	frame_end : out integer range 0 to 127  
	) is
	
	 variable t_frame :  can_frame_type := (others=>UNDEFINED);
	 variable c_frame :  std_logic_vector(127 downto 0) := (others=>'U');
	 variable count : integer range 0 to 127 := 0;
	 
  begin    
      c_frame(127) := '0';
      t_frame(127) := SOF;

    if(extended = '1')then
        c_frame(126 downto 116) := identifier(28 downto 18);
        t_frame(126 downto 116) := (others=>IDENT);
        
        c_frame(115 downto 114) := "11";
        t_frame(115) := SRR; 
        t_frame(114) := IDE;
        
        c_frame(113 downto 96) := identifier(17 downto 0);
        t_frame(113 downto 96) := (others=>IDENT);
        
        c_frame(95) := '0'; --rtr bit
        t_frame(95) := RTR;
        
        c_frame(94 downto 93) := "00";
        t_frame(94 downto 93) := (others=>RESERVED);
        
        count := 92;
    else
        c_frame(126 downto 116) := identifier(10 downto 0);
        t_frame(126 downto 116) := (others=>IDENT);
        
        c_frame(115) := '0'; --rtr bit
        t_frame(115) := RTR;
        
        c_frame(114 downto 113) := "00";
        t_frame(114) := IDE; 
        t_frame(113) := RESERVED;
        
        count := 112;
    end if;

    c_frame(count downto count -3) := std_logic_vector(to_unsigned(length,4));
    t_frame(count downto count -3) := (others=>DLC);
    count := count - 4;

    for i in 0 to length - 1 loop
      c_frame(count downto count -7) := payload(63-i*8 downto 56-i*8);
      t_frame(count downto count -7) := (others=>DATA);
      count := count -8;
    end loop;

    c_frame(count downto count -14) := gen_crc(c_frame(127 downto count+1),127,127-count, error_gen);
    t_frame(count downto count -14) := (others=>CRC);
    count := count -15;
    
   -- if error_gen(1) = '0' then --Form Error generation
      c_frame(count) := '1'; --crc delimiter
      t_frame(count) := CRCDELIM;
   -- elsif error_gen(1) ='1' then --Form error 1
   --   c_frame(count) := '0'; --crc delimiter
   --   t_frame(count) := CRCDELIM;
    --end if;
      
    c_frame(count-1) := '1'; --ack slot
    t_frame(count-1) := ACK;
    
   if error_gen(1) = '0' then --Form Error generation
      c_frame(count-2) := '1'; --ack delimiter
      t_frame(count-2) := ACKDELIM; 
    elsif error_gen(1) ='1' then --Form error 1
      c_frame(count-2) := '0'; --ack delimiter
      t_frame(count-2) := ACKDELIM; 
    end if;
    
    -- Error Test: Form Error Exception:
    -- A receiver monitoring a dominant bit at the last bit of EOF, or any node monitoring a dominant bit at
    -- the last bit of error delimiter or of overload delimiter, shall not interpret this as a form error. 

    c_frame(count-3 downto count -9) := "1111111"; --EOF
    t_frame(count-3 downto count -9) := (others=>EOF);
 
    can_frame := c_frame;
    type_frame := t_frame;
    frame_end := count-9;      
  return; 
end gen_data_frame;

procedure gen_remote_frame(
	identifier : in std_logic_vector(28 downto 0);
	extended : in std_logic;
	length : in integer range 0 to 8;
	can_frame : out std_logic_vector(127 downto 0);
	type_frame : out can_frame_type;
	frame_end : out integer range 0 to 127;
	error_gen : in std_logic_vector(3 downto 0)  
	) is
	
	 variable t_frame :  can_frame_type := (others=>UNDEFINED);
	 variable c_frame :  std_logic_vector(127 downto 0) := (others=>'U');
	 variable count : integer range 0 to 127 := 0;
	 
  begin    
    c_frame(127) := '0';
    t_frame(127) := SOF;

    if(extended = '1')then
        c_frame(126 downto 116) := identifier(28 downto 18);
        t_frame(126 downto 116) := (others=>IDENT);
        
        c_frame(115 downto 114) := "11";
        t_frame(115) := SRR; 
        t_frame(114) := IDE;
        
        c_frame(113 downto 96) := identifier(17 downto 0);
        t_frame(113 downto 96) := (others=>IDENT);
        
        c_frame(95) := '1'; --rtr bit
        t_frame(95) := RTR;
        
        c_frame(94 downto 93) := "00";
        t_frame(94 downto 93) := (others=>RESERVED);
        
        count := 92;
    else
        c_frame(126 downto 116) := identifier(10 downto 0);
        t_frame(126 downto 116) := (others=>IDENT);
        
        c_frame(115) := '1'; --rtr bit
        t_frame(115) := RTR;
        
        c_frame(114 downto 113) := "00";
        t_frame(114) := IDE; 
        t_frame(113) := RESERVED;
        
        count := 112;
    end if;

    c_frame(count downto count -3) := std_logic_vector(to_unsigned(length,4));
    t_frame(count downto count -3) := (others=>DLC);
    count := count - 4;

    c_frame(count downto count -14) := gen_crc(c_frame(127 downto count+1),127,127-count, error_gen);
    t_frame(count downto count -14) := (others=>CRC);
    count := count -15;
    
    c_frame(count) := '1'; --crc delimiter
    t_frame(count) := CRCDELIM;
    
    c_frame(count-1) := '1'; --ack slot
    t_frame(count-1) := ACK;
    
    c_frame(count-2) := '1'; --ack delimiter
    t_frame(count-2) := ACKDELIM; 
    
    c_frame(count-3 downto count -9) := "1111111"; --EOF
    t_frame(count-3 downto count -9) := (others=>EOF);
 
    can_frame := c_frame;
    type_frame := t_frame;
    frame_end := count-9;      
  return; 
end gen_remote_frame;
  
procedure stuff_signals(c_frame : in std_logic_vector(127 downto 0);
    t_frame : in can_frame_type;
    frame_end : in integer range 0 to 127;
	  stuffed_can_frame : out std_logic_vector(153 downto 0);
    stuffed_type_frame : out can_frame_stuffed_type;
    stuffed_frame_end : out integer range 0 to 153)
    is
      
    variable index : integer range 0 to 153 := 153;
    variable st_frame : can_frame_stuffed_type := (others=> UNDEFINED);
    variable sc_frame : std_logic_vector(153 downto 0) := (others=> 'U');
	
    begin
  
    for i in 127 downto frame_end loop
      st_frame(index) := t_frame(i);
      sc_frame(index) := c_frame(i);
      index := index -1;
      if((i < 124) and (t_frame(i) /= CRCDELIM) and (t_frame(i) /= ACK) and (t_frame(i) /= ACKDELIM) and (t_frame(i) /= EOF))then
        if((sc_frame(index+1) = sc_frame(index+2)) and (sc_frame(index+1) = sc_frame(index+3)) and (sc_frame(index+1) = sc_frame(index+4)) and (sc_frame(index+1) = sc_frame(index+5))) then
          if((st_frame(index+1) /= STUFF) and (st_frame(index+2) /= STUFF) and (st_frame(index+3) /= STUFF) and (st_frame(index+4) /= STUFF)) then              
            st_frame(index) := STUFF;
            sc_frame(index) := not c_frame(i);
            index := index -1;
          end if;          
        end if;
      end if;
    end loop;
    
    stuffed_can_frame := sc_frame;
    stuffed_type_frame := st_frame;
    stuffed_frame_end := index;  
  
  return;
end stuff_signals;



 function calc_bitclk(clk_freq_hz : integer range 0 to 2147483647;
    bit_freq_hz : integer range 0 to 2147483647)
	return integer is
	
	variable divider : integer range 0 to 513 := 0;  
  begin
    assert(clk_freq_hz > 0) report "clk_freq_hz invalid!" severity failure;
    assert(bit_freq_hz > 0) report "bit_freq_hz invalid!" severity failure;
    divider := clk_freq_hz / bit_freq_hz;
    assert(divider > 1) report "divider invalid!" severity failure;
	assert(divider < 513) report "divider invalid!" severity failure;
    report "Bitrate is: " & integer'image(clk_freq_hz/divider) & "Bit/s";
	
  return divider;  
  end calc_bitclk;
  
  
 procedure wait_bit_clk(signal clk : in std_logic;
	div : integer range 0 to 512)
	is	
  begin
	for i in 0 to div-1 loop
		wait until rising_edge(clk);
	end loop;
   
  return; 
end wait_bit_clk; 
	
	

procedure gen_tx_message( payload : in std_logic_vector(63 downto 0);
  length : in integer range 0 to 8;
  identifier : in std_logic_vector(28 downto 0);
  remote : in std_logic;
  extended : in std_logic;
	clk_freq_hz : integer range 0 to 2147483647;
  bit_freq_hz : integer range 0 to 2147483647;
  tx_error_gen : std_logic_vector(3 downto 0);
	signal clk : in std_logic;
	signal start : in std_logic;
	signal tx : out std_logic;
	signal tx_type : out frame_type;
	signal ack_gen : out std_logic)
    is
	
	variable frame_end : integer range 0 to 127 := 127;
	variable s_frame_end : integer range 0 to 153 := 153;
	variable t_frame : can_frame_type := (others=> UNDEFINED);
	variable c_frame : std_logic_vector(127 downto 0) := (others=> 'U');   
	variable st_frame : can_frame_stuffed_type := (others=> UNDEFINED);
	variable sc_frame : std_logic_vector(153 downto 0) := (others=> 'U');
	
	variable index : integer range 0 to 153 := 153;
	variable div : integer range 0 to 512 := 1;
  begin
	ack_gen <= '1';
	if(remote = '0') then
	  gen_data_frame(identifier,extended,payload,length,tx_error_gen,c_frame,t_frame,frame_end);
  else
    gen_remote_frame(identifier,extended,length,c_frame,t_frame,frame_end, tx_error_gen);
  end if;
  if tx_error_gen(3) = '0' then -- STUFFING ERROR GENERATION
  	stuff_signals(c_frame,t_frame,frame_end,sc_frame,st_frame,s_frame_end);
  	div := calc_bitclk(clk_freq_hz,bit_freq_hz);
	end if;
	wait until (start = '1');
	tx_type <= st_frame(index);
	tx <= sc_frame(index);
	index := index-1;
	wait_bit_clk(clk,div);
    while(index > s_frame_end) loop
		tx_type <= st_frame(index);
    tx <= sc_frame(index);
    if(st_frame(index) = ACK)then
      ack_gen <= '0';
    else
      ack_gen <= '1';
    end if;
    index := index-1;
		wait_bit_clk(clk,div);
	end loop;
	tx <= 'U';
	tx_type <= UNDEFINED;	
  return;
end gen_tx_message;

procedure gen_rx_message( payload : in std_logic_vector(63 downto 0);
	length : in integer range 0 to 8;
	identifier : in std_logic_vector(28 downto 0);
	remote : in std_logic;
	extended : in std_logic;
	clk_freq_hz : integer range 0 to 2147483647;
	bit_freq_hz : integer range 0 to 2147483647;
	rx_error_gen : in std_logic_vector(3 downto 0);
	signal clk : in std_logic;
	signal tx : out std_logic;
	signal tx_type : out frame_type;
	signal ack_gen : out std_logic)
    is
	
	variable frame_end : integer range 0 to 127 := 127;
	variable s_frame_end : integer range 0 to 153 := 153;
	variable t_frame : can_frame_type := (others=> UNDEFINED);
	variable c_frame : std_logic_vector(127 downto 0) := (others=> 'U');   
	variable st_frame : can_frame_stuffed_type := (others=> UNDEFINED);
	variable sc_frame : std_logic_vector(153 downto 0) := (others=> 'U');
  variable error_gen : std_logic_vector(3 downto 0);	
	variable index : integer range 0 to 153 := 153;
	variable div : integer range 0 to 512 := 1;
  begin
  error_gen := rx_error_gen;
  ack_gen <= '1';
	if(remote = '0') then
	  gen_data_frame(identifier,extended,payload,length,rx_error_gen,c_frame,t_frame,frame_end);
  else
    gen_remote_frame(identifier,extended,length,c_frame,t_frame,frame_end, rx_error_gen);
  end if;
	if rx_error_gen(0) = '0' then -- STUFFING ERROR
		stuff_signals(c_frame,t_frame,frame_end,sc_frame,st_frame,s_frame_end);
	end if;
	div := calc_bitclk(clk_freq_hz,bit_freq_hz);
	tx_type <= st_frame(index);
	tx <= sc_frame(index);
	index := index-1;
	wait_bit_clk(clk,div);
    while(index > s_frame_end) loop
		tx_type <= st_frame(index);
    tx <= sc_frame(index);
    if(st_frame(index) = ACK)then
      ack_gen <= '0';
    else
      ack_gen <= '1';
    end if;
    index := index-1;
		wait_bit_clk(clk,div);
	end loop;
	tx <= '1';
	tx_type <= UNDEFINED;	
  return;
end gen_rx_message;      
  
END can_pattern_gen;
