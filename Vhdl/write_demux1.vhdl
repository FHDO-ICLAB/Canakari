-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                         
-------------------------------------------------------------------------------
-- WRITE_DEMUX erzeugt aktivierungssignale, wenn CPU auf ein REgister schreiben
-- will. Abhängig von der Adresse wird das Signal activ_in zu einem der 15
-- möglichen activ_out durchgeschaltet, die in multiplexer_top gemappt werden.
LIBRARY ieee, synopsys;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;
USE synopsys.attributes.ALL;

ENTITY write_demux1 IS
  PORT (
    address   : IN  bit_vector(4 DOWNTO 0);    -- aussen
    activ_in  : IN  bit;                       -- multiplexer_top
    activ_out : OUT bit_vector(14 DOWNTO 0));  --        "
END write_demux1;
-------------------------------------------------------------------------------
ARCHITECTURE behv OF write_demux1 IS
BEGIN  -- behv
  demux : PROCESS (address, activ_in)
  BEGIN  -- PROCESS demux
    CASE address IS
      WHEN "10010" => activ_out(14) <= activ_in;  -- Interruptregister
                     activ_out(13 DOWNTO 0) <= (OTHERS => '0'); 
      WHEN "10001" => activ_out(13) <= activ_in;  -- Acceptionmaskregister 28...13
                     activ_out(14 DOWNTO 14) <= (OTHERS => '0');
                     activ_out(12 DOWNTO 0) <= (OTHERS => '0'); 
      WHEN "10000" => activ_out(12) <= activ_in;  -- Acceptionmaskregister 12...0
                     activ_out(14 DOWNTO 13) <= (OTHERS => '0');
                     activ_out(11 DOWNTO 0) <= (OTHERS => '0');
      WHEN "01111" => activ_out(11) <= activ_in;  -- Prescaleregister
                     activ_out(14 DOWNTO 12) <= (OTHERS => '0');
                     activ_out(10 DOWNTO 0) <= (OTHERS => '0');
      WHEN "01110" => activ_out(10) <= activ_in;  -- Generalregister
                     activ_out(14 DOWNTO 11) <= (OTHERS => '0');
                     activ_out( 9 DOWNTO 0)  <= (OTHERS => '0');
      WHEN "01101" => activ_out( 9) <= activ_in;  -- tranmit message control register
                     activ_out(14 DOWNTO 10) <= (OTHERS => '0');
                     activ_out( 8 DOWNTO 0)  <= (OTHERS => '0');
      WHEN "01100" => activ_out( 8) <= activ_in;  -- transmit id bit 28..13
                     activ_out(14 DOWNTO 9) <= (OTHERS => '0');
                     activ_out( 7 DOWNTO 0) <= (OTHERS => '0');
      WHEN "01011" => activ_out( 7) <= activ_in;  -- transmit id bit 12..0
                     activ_out(14 DOWNTO 8) <= (OTHERS => '0');
                     activ_out( 6 DOWNTO 0) <= (OTHERS => '0');
      WHEN "01010" => activ_out( 6) <= activ_in;  -- transmit data 1,2
                     activ_out(14 DOWNTO 7) <= (OTHERS => '0');
                     activ_out( 5 DOWNTO 0) <= (OTHERS => '0');
      WHEN "01001" => activ_out( 5) <= activ_in;  -- transmit data 3,4
                     activ_out(14 DOWNTO 6) <= (OTHERS => '0');
                     activ_out( 4 DOWNTO 0) <= (OTHERS => '0');
      WHEN "01000" => activ_out( 4) <= activ_in;  -- transmit data 5,6
                     activ_out(14 DOWNTO 5) <= (OTHERS => '0');
                     activ_out( 3 DOWNTO 0) <= (OTHERS => '0');
      WHEN "00111" => activ_out( 3) <= activ_in;  -- transmit data 7,8
                     activ_out(14 DOWNTO 4) <= (OTHERS => '0');
                     activ_out( 2 DOWNTO 0) <= (OTHERS => '0');
      WHEN "00110" => activ_out( 2) <= activ_in;  -- receive message control register
                     activ_out(14 DOWNTO 3) <= (OTHERS => '0');
                     activ_out( 1 DOWNTO 0) <= (OTHERS => '0');
      WHEN "00101" => activ_out( 1) <= activ_in;  -- receive id 28..13
                     activ_out(14 DOWNTO 2) <= (OTHERS => '0');
                     activ_out( 0 DOWNTO 0) <= (OTHERS => '0');
      WHEN "00100" => activ_out( 0) <= activ_in;  -- receive id 12..0
                     activ_out(14 DOWNTO 1) <= (OTHERS => '0');
      WHEN OTHERS => activ_out <= (OTHERS => '0');  -- receive data ist nicht
                                                    -- von der cpu beschreibbar
    END CASE;
  END PROCESS demux;
END behv;
