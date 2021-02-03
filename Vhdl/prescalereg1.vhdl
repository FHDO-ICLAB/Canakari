-------------------------------------------------------------------------------
-- Prescaleregister m. reset Ausgang res_scale
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;

ENTITY prescalereg1 IS
  PORT( clk    : IN  bit;
        rst    : IN  bit;               -- reset
        cpu    : IN  bit;                      -- CPU wuenscht Zugriff
        reginp : IN  bit_vector(15 DOWNTO 0);  -- CPU schreibt
        regout : OUT bit_vector(15 DOWNTO 0));  -- Prescaler liest --Beer 2018_06_18, erweitert auf 16bit
END prescalereg1;


ARCHITECTURE behv OF prescalereg1 IS
BEGIN
  PROCESS(clk)
  BEGIN
    IF clk'event AND clk = '1' THEN
      IF rst = '0' THEN                 -- synchroner reset, neg. clock-flanke
        regout <= (OTHERS => '0');
      ELSIF cpu = '1' THEN
        regout <= "00000000" & reginp(7 DOWNTO 0);  -- werden nur 8 Bit benutzt
      END IF;
    END IF;
  END PROCESS;
END;
