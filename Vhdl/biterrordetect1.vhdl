-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell
--                                     Diplomarbeit
-------------------------------------------------------------------------------
--                            Datei: biterror.vhd
--                     Beschreibung: biterror detection
--                               Teil des MAC
-------------------------------------------------------------------------------
-- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;

ENTITY biterrordetect1 IS
  PORT( clock    : IN  bit;
        bitin    : IN  bit;             -- vergleich 1
        bitout   : IN  bit;             -- vergleich 2
        activ    : IN  bit;             -- synchron neg. clock
        reset    : IN  bit;             -- synchron neg. clock
        biterror : OUT bit);            -- ergebnis
END biterrordetect1;

ARCHITECTURE behv OF biterrordetect1 IS
BEGIN
  PROCESS(clock)
    --VARIABLE edged : bit;                -- flankenmerker für active neg. clock
  BEGIN
    IF clock'event AND clock = '1' THEN  -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
      IF reset = '0' THEN                -- reset
        biterror <= '0';
        --edged    := '0';
      ELSIF activ = '1' THEN
        --IF edged = '0' THEN              -- flanke?
          --edged := '1';                  -- nein, dann ab jetzt ja.

          IF bitin /= bitout THEN       -- vergleich
            biterror <= '1';
          ELSE
            biterror <= '0';
          END IF;
        --ELSE
          --edged := '1';                 -- noch posi.
        --END IF;
        --edged := '0';                   -- jetzt war neg. flanke
      END IF;
    END IF;
  END PROCESS;
END;
