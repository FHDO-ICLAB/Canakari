-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell 
--                                     Diplomarbeit 
-------------------------------------------------------------------------------
--                            Datei: accmaskreg.vhd
--                     Beschreibung: Acceptance Mask Register
--                                     
-------------------------------------------------------------------------------
-- Adressen: 10000 und 10001
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;

ENTITY accmaskreg1 IS
  PORT( clk    : IN  bit;
        rst    : IN  bit;
        cpu    : IN  bit;                       -- CPU wuenscht Zugriff
        reginp : IN  bit_vector(15 DOWNTO 0);   -- Registerbus
        regout : OUT bit_vector(15 DOWNTO 0));  -- Acceptance Mask Register
END accmaskreg1;

ARCHITECTURE behv OF accmaskreg1 IS
BEGIN
  PROCESS(clk)
  BEGIN
    IF clk'event AND clk = '1' THEN             -- steigende Flanke
      IF rst = '0' THEN                         -- synchroner Reset
        regout <= (OTHERS => '0');
      ELSIF cpu = '1' THEN                         -- cpu schreibt
        regout <= reginp;                      
      END IF;
    END IF;
  END PROCESS;
END;
