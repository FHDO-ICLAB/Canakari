-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell 
--                                     Diplomarbeit  
-------------------------------------------------------------------------------
--                            Datei: rmesreg.vhd
--                     Beschreibung: receive message control register
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;

ENTITY recmescontrolreg1 IS
  PORT( clk  : IN  bit;
        rst  : IN  bit;
        cpu  : IN  bit;                 -- CPU wuenscht Zugriff
        can  : IN  bit;                 -- controller wuenscht Zugriff
        ofp  : IN  bit;                 -- IOCPU,overflow indication processor
        ofc  : IN  bit;                 -- llc, overflow indication can
        rip  : IN  bit;                 -- IOCPU, receive indication processor
        ric  : IN  bit;                 -- llc, receive indication can
        ien  : IN  bit;                 -- interrupt enable (not used)
        rtr  : IN  bit;                 -- MAC, remote flag
        ext  : IN  bit;                 -- IOCPU,extended flag
--        prom : IN  bit;  -- Promiscous Mode (alle Daten werden empfangen)
        dlc  : IN  bit_vector(3 DOWNTO 0);    -- data length code
        reg  : OUT bit_vector(15 DOWNTO 0));  -- generalregister
END recmescontrolreg1;

ARCHITECTURE behv OF recmescontrolreg1 IS
BEGIN
  PROCESS(clk)
  BEGIN
    IF clk'event AND clk = '1' THEN     -- neg. Flanke
      IF rst = '0' THEN                 -- synchroner Reset
        reg <= (OTHERS => '0');
      ELSIF cpu = '1' THEN                 -- IOCPU, write_demux
        reg(15) <= ofp;
        reg(14) <= rip;
--        reg(13) <= prom;                -- neu
        reg( 8) <= ien;
        reg( 4) <= ext;
      ELSIF can = '1' THEN              -- llc, aktiv-signal
        reg(15)         <= ofc;         -- llc
        reg(14)         <= ric;         -- llc
        reg( 5)         <= rtr;         -- mac
        reg(3 DOWNTO 0) <= dlc;         -- dlc
      END IF;
    END IF;
  END PROCESS;
END;
