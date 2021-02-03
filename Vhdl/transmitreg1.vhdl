-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell 
--                                     Diplomarbeit 
-------------------------------------------------------------------------------
--                            Datei: transreg.vhd
--                     Beschreibung: ordinary transmit data register
-------------------------------------------------------------------------------
-- Adressen: 0x14, 0x12, 0x10, 0x0e (v.u.n.o)
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;

ENTITY transmitreg1 IS
  PORT( clk    : IN  bit;
        rst    : IN  bit;
        cpu    : IN  bit;                       -- CPU wuenscht Zugriff
        reginp : IN  bit_vector(15 DOWNTO 0);   -- Registerbus
        regout : OUT bit_vector(15 DOWNTO 0));  -- generalregister
END transmitreg1;

ARCHITECTURE behv OF transmitreg1 IS
BEGIN
  PROCESS(clk, rst)
  BEGIN
    IF clk'event AND clk = '1' THEN     -- neg. Flanke
      IF rst = '0' THEN                 -- synchroner Reset
        regout <= (OTHERS => '0');
      ELSIF cpu = '1' THEN                 -- cpu schreibt zu
        regout <= reginp;               -- sendende Daten
      END IF;
    END IF;
  END PROCESS;
END;
