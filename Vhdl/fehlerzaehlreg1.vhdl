-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell 
--                                     Diplomarbeit 
-------------------------------------------------------------------------------
--                            Datei: fehlerzaehlreg.vhdl
--                     Beschreibung: Fehlerzaehler Register

-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;

ENTITY fehlercountreg1 IS
  PORT( clk          : IN  bit;
        rst          : IN  bit;
        teccan       : IN bit_vector(7 DOWNTO 0);
        reccan       : IN bit_vector(7 DOWNTO 0);
        reg          : OUT bit_vector(15 DOWNTO 0));  -- Fehlerzaehler Register
END fehlercountreg1;

ARCHITECTURE behv OF fehlercountreg1 IS
BEGIN
      reg(15 downto 8) <= teccan; -- TEC
      reg(7  downto 0) <= reccan; -- REC
END;
