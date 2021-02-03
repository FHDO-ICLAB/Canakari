-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell  
--                                     Diplomarbeit 
-------------------------------------------------------------------------------
--                            Datei: tmesreg.vhd
--                     Beschreibung: transmit message control register
-------------------------------------------------------------------------------
-- Adresse: 0x1a
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;

ENTITY transmesconreg1 IS
  PORT( clk    : IN  bit;
        rst    : IN  bit;
        cpu    : IN  bit;                       -- IOCPU, CPU wuenscht Zugriff
        can    : IN  bit;                       -- controller wuenscht Zugriff
        tsucf  : IN  bit;                       -- llc, successful transmission
        reginp : IN  bit_vector(15 DOWNTO 0);   -- Register Bus (daten)
        regout : OUT bit_vector(15 DOWNTO 0));  -- generalregister
END transmesconreg1;

ARCHITECTURE behv OF transmesconreg1 IS
BEGIN
  PROCESS(clk)
  BEGIN
    IF clk'event AND clk = '1' THEN     -- neg. Flanke
      IF rst = '0' THEN                 -- synchroner Reset
        regout <= (OTHERS => '0');
      ELSIF cpu = '1' THEN                 -- cpu schreibt
        regout <= reginp;
      ELSIF can = '1' THEN              -- can schreibt nur
        regout(15) <= '0';              -- treq auf 0
        regout(14) <= tsucf;            -- transmit indication (llc)
      END IF;
    END IF;
  END PROCESS;
END;
