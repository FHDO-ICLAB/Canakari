-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell 
--                                     Diplomarbeit
-------------------------------------------------------------------------------
--                            Datei: recarbitreg.vhd
--                     Beschreibung: receive arbitration register
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;
LIBRARY Synopsys;
USE Synopsys.attributes.ALL;

ENTITY recarbitreg1 IS
  PORT( clk     : IN  bit;
        rst     : IN  bit;
        cpu     : IN  bit;              -- CPU wuenscht Zugriff
        can     : IN  bit;              -- controller will zugreifen (im
                                        -- promiscous mode)
        reginp  : IN  bit_vector(15 DOWNTO 0);  --
        recidin : IN  bit_vector(15 DOWNTO 0);  --
        regout  : OUT bit_vector(15 DOWNTO 0));
END recarbitreg1;

ARCHITECTURE behv OF recarbitreg1 IS
--  attribute async_set_reset of rst : signal IS "true";
--  attribute infer_multibit of regout : signal is "true";
BEGIN
  PROCESS(clk)
  BEGIN
    IF clk'event AND clk = '1' THEN
      IF rst = '0' THEN                 -- synchroner reset (neg.)
        regout <= (OTHERS => '0');
      ELSIF cpu = '1' THEN                 -- cpu zugriff (von write_demux)
        regout <= reginp;
      ELSIF can = '1' THEN              -- llc zugriff
        regout <= recidin;
      END IF;
    END IF;
  END PROCESS;
END;
