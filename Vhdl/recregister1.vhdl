-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell 
--                                     Diplomarbeit    
-------------------------------------------------------------------------------
--                            Datei: recregister.vhd
--                     Beschreibung: ordinary receive data register
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;

ENTITY recregister1 IS
  PORT( clk    : IN  bit;
        rst    : IN  bit;               -- reset
        can    : IN  bit;                       -- CPU wuenscht Zugriff
        regin1 : IN  bit_vector(7 DOWNTO 0);    -- MAC, rshift
        regin2 : IN  bit_vector(7 DOWNTO 0);    -- MAC, rshift
        regout : OUT bit_vector(15 DOWNTO 0));  -- generalregister
END recregister1;

ARCHITECTURE behv OF recregister1 IS
BEGIN
  PROCESS(clk)
  BEGIN
    IF clk'event AND clk = '1' THEN     -- neg. Flanke
      IF rst = '0' THEN                 -- synchroner Reset
        regout <= (OTHERS => '0');
      ELSIF can = '1' THEN                 -- wird nur von MAC beschrieben
        regout(15 DOWNTO 8) <= regin1(7 DOWNTO 0);
        regout( 7 DOWNTO 0) <= regin2(7 DOWNTO 0);
      END IF;                           -- kein CPU-Zugriff
    END IF;
  END PROCESS;
END;
