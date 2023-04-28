--
-- VHDL Package Body canakari.config
--
-- Created:
--          by - awalsemann.UNKNOWN (IMES17)
--          at - 14:40:30 19.02.2018
--
-- using Mentor Graphics HDL Designer(TM) 2016.1 (Build 8)
--
PACKAGE BODY config IS
 
--
-- VHDL Architecture canakari.config.behave
--
-- Created:
--          by - awalsemann.UNKNOWN (IMES17)
--          at - 15:08:38 01.02.2018
--
-- using Mentor Graphics HDL Designer(TM) 2016.1 (Build 8)
--

USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;


--

    
  procedure write_register(
    register_address : in std_logic_vector(4 downto 0);
    register_data : in std_logic_vector(15 downto 0);
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic
    ) is
    begin
      
      wait until rising_edge(clk);
      
      address <= register_address;
      writedata <= register_data;
      read_n  <= '1';  
      write_n <= '0';
      cs <= '0';
  
      wait until rising_edge(clk);
      cs <= '1';
  
      wait until rising_edge(clk);
      cs <= '0';
      write_n  <= '1';
      wait until rising_edge(clk);

                          
  return;    
  end write_register;
  
  procedure read_register(
    register_address : in std_logic_vector(4 downto 0);
    register_data : out std_logic_vector(15 downto 0);
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic
    ) is
    begin
      
      wait until rising_edge(clk);
      
      address <= register_address;
      writedata <= (others => '0');
      read_n  <= '0';  
      write_n <= '1';
      cs <= '0';
  
      wait until rising_edge(clk);
      cs <= '1';
  
      wait until rising_edge(clk);
      register_data := readdata;
      cs <= '0';
      read_n  <= '0';    
                      
  return;     
  end read_register;

    
   procedure configure_prescaler (
    divider : in integer range 2 to 32;
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic
    ) is
-- * * * *  RIZWAN * * * * * 
--    variable div : integer range 2 to 32 := (divider-2/2);
--    variable reg1: std_logic_vector(3 downto 0);
--    variable reg0: std_logic_vector(3 downto 0);
--    
--    begin
--    reg1 := std_logic_vector(to_unsigned(div,4));
--    reg0 := std_logic_vector(to_unsigned(div,4));
-- * * * * * * * * * * * * *     
    
    
-- * * * *  WALSEMANN * * * * 
    variable div : integer range 0 to 30 := divider - 2;
    variable reg1 : std_logic_vector(3 downto 0);
    variable reg0 : std_logic_vector(3 downto 0);
  begin
    
    if(div > 15)then
      reg1 := std_logic_vector(to_unsigned(div-15,4));
      reg0 := X"F";
    else
      reg1 := (others => '0');
      reg0 := std_logic_vector(to_unsigned(div,4));
    end if;
-- * * * * * * * * * * * * * * 
    write_register("01111",X"00" & reg1 & reg0,clk,address,writedata,readdata,cs,read_n,write_n);
    
  return; 
  end configure_prescaler;
  
  
  
  
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
    signal write_n : out  std_logic
    ) is
    variable tseg1_vec : std_logic_vector(2 downto 0);
    variable tseg2_vec : std_logic_vector(2 downto 0);
    variable sjw_vec : std_logic_vector(2 downto 0);
  begin
    
    sjw_vec := std_logic_vector(to_unsigned(sjw,3));
    tseg2_vec := std_logic_vector(to_unsigned(tseg2-1,3));
    tseg1_vec := std_logic_vector(to_unsigned(tseg1-1,3));
    write_register("01110","0000000" & sjw_vec & tseg1_vec & tseg2_vec ,clk,address,writedata,readdata,cs,read_n,write_n);
    
  return; 
  end configure_general;
  
  procedure soft_reset(
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic
    ) is
  begin
    
    write_register("01110", X"0200",clk,address,writedata,readdata,cs,read_n,write_n);
    
  return; 
  end soft_reset;
  
  procedure enable_pl(
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic
    ) is
  begin
    
    write_register("10010", X"8000",clk,address,writedata,readdata,cs,read_n,write_n);
    
  return; 
  end enable_pl;
  
  procedure configure_accmask(
    mask : in std_logic_vector(28 downto 0);
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic
    ) is
  begin
    
    write_register("10001", mask(28 downto 13) ,clk,address,writedata,readdata,cs,read_n,write_n);
    write_register("10000", mask(12 downto 0) & "000" ,clk,address,writedata,readdata,cs,read_n,write_n);
    
  return; 
  end configure_accmask;
  
  
  
  procedure configure_payload(
    payload : in std_logic_vector(63 downto 0);
    length : in integer range 0 to 8;
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic
    ) is
    variable tmp_address : integer range 0 to 10 := 10;
    variable i : integer range 0 to 8 := 0;
  begin
    if(length > 0) then
      while (i < length) loop
        if(length-i > 1)then
          write_register(std_logic_vector(to_unsigned(tmp_address,5)), payload(63-i*8 downto 63-(i*8)-15),clk,address,writedata,readdata,cs,read_n,write_n);
        else
          write_register(std_logic_vector(to_unsigned(tmp_address,5)), payload(63-(i*8) downto 63-(i*8)-7) & X"00" ,clk,address,writedata,readdata,cs,read_n,write_n);
        end if;
        tmp_address := tmp_address-1;
        i := i+2;
      end loop;
    end if;
    
  return; 
  end configure_payload;
  
  
  procedure configure_identifier(
    identifier : in std_logic_vector(10 downto 0);
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic
    ) is
  begin

    --write_register("01011", "00" & identifier & "000" ,clk,address,writedata,readdata,cs,read_n,write_n);
    write_register("01100",  identifier & "00000" ,clk,address,writedata,readdata,cs,read_n,write_n);
    
  return; 
  end configure_identifier;
  
  procedure configure_ext_identifier(
    identifier : in std_logic_vector(28 downto 0);
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic
    ) is
  begin
    
    write_register("01100", identifier(28 downto 13) ,clk,address,writedata,readdata,cs,read_n,write_n);
    write_register("01011", identifier(12 downto 0) & "000" ,clk,address,writedata,readdata,cs,read_n,write_n);
    
  return; 
  end configure_ext_identifier;
  
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
    signal write_n : out  std_logic
    ) is
  begin
    
    write_register("01101", start_tx & "000000000" & remote & extended & std_logic_vector(to_unsigned(length,4)) ,clk,address,writedata,readdata,cs,read_n,write_n);
       
    return; 
  end configure_tx_control;
  
  
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
    signal write_n : out  std_logic
    ) is
  begin
    configure_identifier(identifier,clk,address,writedata,readdata,cs,read_n,write_n);
    configure_payload(payload,length,clk,address,writedata,readdata,cs,read_n,write_n);
    configure_tx_control('1','0','0',length,clk,address,writedata,readdata,cs,read_n,write_n); 
  return; 
  end send_std_message;
  
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
    signal write_n : out  std_logic
    ) is
  begin
    configure_ext_identifier(identifier,clk,address,writedata,readdata,cs,read_n,write_n);
    configure_payload(payload,length,clk,address,writedata,readdata,cs,read_n,write_n);
    configure_tx_control('1','0','1',length,clk,address,writedata,readdata,cs,read_n,write_n); 
  return; 
  end send_ext_message;
  
  procedure send_ext_remote(
    identifier : in std_logic_vector(28 downto 0);
    length : in integer range 0 to 8;
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic
    ) is
  begin
    configure_ext_identifier(identifier,clk,address,writedata,readdata,cs,read_n,write_n);
    configure_tx_control('1','1','1',length,clk,address,writedata,readdata,cs,read_n,write_n); 
  return; 
  end send_ext_remote;
  
  procedure send_std_remote(
    identifier : in std_logic_vector(10 downto 0);
    length : in integer range 0 to 8;
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic
    ) is
  begin
    configure_identifier(identifier,clk,address,writedata,readdata,cs,read_n,write_n);
    configure_tx_control('1','1','0',length,clk,address,writedata,readdata,cs,read_n,write_n); 
  return; 
  end send_std_remote;
  
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
    signal write_n : out  std_logic
    ) is
  begin
    if(remote = '1')then
      if(extended = '1')then
        send_ext_remote(identifier,length,clk,address,writedata,readdata,cs,read_n,write_n);
      else
        send_std_remote(identifier(10 downto 0),length,clk,address,writedata,readdata,cs,read_n,write_n);
      end if;      
    else
      if(extended = '1')then
        send_ext_message(payload,length,identifier,clk,address,writedata,readdata,cs,read_n,write_n);
      else
        send_std_message(payload,length,identifier(10 downto 0),clk,address,writedata,readdata,cs,read_n,write_n);
      end if;
    end if;
  return; 
  end send_package;
    
  function calculate_bitrate(clock , prescaler , tseg1, tseg2 : integer)
    return integer is
  begin
    return (clock /prescaler)/(tseg1+1+tseg2);
  end calculate_bitrate;
  
  function calculate_samplepoint(tseg1, tseg2 : integer)
    return integer is
  begin
    return ((tseg1+1)*100)/((tseg1+1) + tseg2);
  end calculate_samplepoint;
  
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
    signal write_n : out  std_logic
    ) is
    variable reg : std_logic_vector(15 downto 0) := (others => '0');
    begin
      read_register("00110",reg,clk,address,writedata,readdata,cs,read_n,write_n);
      received := reg(14);
      remote := reg(5);
      extended := reg(4);
      length := to_integer(unsigned(reg(3 downto 0)));
    return;
  end read_rx_control;
  
  procedure wait_rx(
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic
    ) is
    variable reg : std_logic_vector(15 downto 0) := (others => '0');
    begin
      while(reg(14) = '0') loop
        read_register("00110",reg,clk,address,writedata,readdata,cs,read_n,write_n);
      end loop; 
    return;  end wait_rx;
  
    
  procedure read_payload(
    payload : out std_logic_vector(63 downto 0);
    length : in integer range 0 to 8;
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic
    ) is
    variable tmp_address : integer range 0 to 3 := 3;
    variable i : integer range 0 to 8 := 0;
  begin
    if(length > 0) then
      while (i < length) loop
        read_register(std_logic_vector(to_unsigned(tmp_address,5)), payload(63-i*8 downto 63-(i*8)-15),clk,address,writedata,readdata,cs,read_n,write_n);
        if(length-i <= 1)then
          payload(63-(i*8)-8 downto 63-(i*8)-15) := (others=> '0');
        end if;
        tmp_address := tmp_address-1;
        i := i+2;
      end loop;
    end if;
    
  return; 
  end read_payload;
  
    
  procedure read_identifier(
    identifier : out std_logic_vector(10 downto 0);
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic
    ) is
    variable reg : std_logic_vector(15 downto 0) := (others => '0');
  begin

    read_register("00101",reg,clk,address,writedata,readdata,cs,read_n,write_n);
    identifier := reg(15 downto 5);
    
  return; 
  end read_identifier;
  
  procedure read_ext_identifier(
    identifier : out std_logic_vector(28 downto 0);
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic
    ) is
    variable reg : std_logic_vector(15 downto 0) := (others => '0');
  begin
    
    write_register("00100", reg, clk,address,writedata,readdata,cs,read_n,write_n);
    identifier(28 downto 13) :=  reg;
    write_register("00101", reg, clk,address,writedata,readdata,cs,read_n,write_n);
    identifier(12 downto 0) :=  reg(15 downto 3); 
  return; 
  end read_ext_identifier;  
    
  procedure reset_rx_control(
    signal clk : in std_logic;
    signal address  : out  std_logic_vector(4 downto 0);
    signal writedata : out std_logic_vector(15 downto 0);
    signal readdata : in std_logic_vector(15 downto 0);
    signal cs : out  std_logic;
    signal read_n : out std_logic;
    signal write_n : out  std_logic
    ) is
    variable reg : std_logic_vector(15 downto 0) := (others => '0');
    begin
      write_register("00110",reg,clk,address,writedata,readdata,cs,read_n,write_n);
    return;
  end reset_rx_control; 

  
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
    signal write_n : out  std_logic
    ) is
    variable done : std_logic := '0';
    variable received : std_logic := '0';
    variable remote_tmp : std_logic := '0';
    variable extended_tmp : std_logic := '0';
    variable payload_tmp :std_logic_vector(63 downto 0) := (others=>'0');
    variable length_tmp : integer range 0 to 8 := 0;
    variable identifier_tmp : std_logic_vector(28 downto 0) := (others=>'0');
  begin
    read_rx_control(done,length_tmp,remote_tmp,extended_tmp,clk,address,writedata,readdata,cs,read_n,write_n);
      if(done = '1') then
        if(extended_tmp = '1')then
          read_ext_identifier(identifier_tmp,clk,address,writedata,readdata,cs,read_n,write_n);
        else
          read_identifier(identifier_tmp(10 downto 0),clk,address,writedata,readdata,cs,read_n,write_n);
        end if;
        if((remote_tmp = '0') and (length_tmp >0))then
          read_payload(payload_tmp,length_tmp,clk,address,writedata,readdata,cs,read_n,write_n);
        end if;
      end if; 
      reset_rx_control(clk,address,writedata,readdata,cs,read_n,write_n);
      
      payload := payload_tmp;
      remote := remote_tmp;
      extended := extended_tmp;
      payload := payload_tmp;
      length := length_tmp;
      identifier := identifier_tmp;
  return;
  end read_package;

  
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
    signal write_n : out  std_logic
    ) is
  begin
    
    configure_prescaler(prescaler,clk,address,writedata,readdata,cs,read_n,write_n);
    configure_general(tseg1,tseg2,sjw,clk,address,writedata,readdata,cs,read_n,write_n);
    enable_pl(clk,address,writedata,readdata,cs,read_n,write_n);
    
  return; 
  end init_controller ;
  

  
  
END config;
