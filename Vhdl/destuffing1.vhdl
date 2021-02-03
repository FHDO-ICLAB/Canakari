-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell
--                                     Diplomarbeit
-------------------------------------------------------------------------------
--                            Datei: destuff.vhd
--                     Beschreibung: destuffing unit
-------------------------------------------------------------------------------
-- activ zählt, direct überbrückt (bei Errorflags etc.)
-- reset synchron mit neg. clock Flanke, da von MACFSM ausgelöst (auch)
-- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;

ENTITY destuffing1 IS
  PORT( clock  : IN  bit;
        bitin  : IN  bit;               -- bittiming: sampledbit
        activ  : IN  bit;               -- MACFSM: actvrstf
        reset  : IN  bit;               -- MACFSM: resetdst or reset
        direct : IN  bit;               -- MACFSM: actvrdct
        stfer  : OUT bit;               -- MACFSM: stferror
        stuff  : OUT bit;               -- MACFSM: stuffr
        bitout : OUT bit);              -- MACFSM: inbit; rcrc,rshift:bitin
END destuffing1;

ARCHITECTURE behv OF destuffing1 IS
BEGIN
  PROCESS(clock)
    VARIABLE count : integer RANGE 0 TO 7;
    VARIABLE buf   : bit;
    VARIABLE state : bit_vector(3 DOWNTO 0);
    VARIABLE edged : bit;               -- Flankenmerker, deglitch
  BEGIN
    IF clock'event AND clock = '1' THEN -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.  
      IF reset = '0' THEN
        count := 0;
        state := "0000";
        stuff <= '0';
        stfer <= '0';
		    edged := '0';
      ELSE
      IF activ = '1' THEN
        IF edged = '0' THEN
          edged := '1';
          IF bitin = buf THEN           -- gleiches Bit
            state(3) := '1';
          ELSE
            state(3) := '0';
          END IF;
          IF count = 0 THEN             -- Anfang
            state(2) := '1';
          ELSE
            state(2) := '0';
          END IF;
          IF count = 5 THEN             -- Stufffall
            state(1) := '1';
          ELSE
            state(1) := '0';
          END IF;
          IF direct = '1' THEN          -- übergehen
            state(0) := '1';
          ELSE
            state(0) := '0';
          END IF;

          CASE state IS
            WHEN "0100"|"1100"|"0000" => buf :=bitin;  -- erstes Bit, da count=0
                                         count := 1;   -- oder Buf/=Bit, dann
                                         stuff <= '0'; -- count 'resetten'
                                         stfer <= '0';
            WHEN "0010" => count :=1;   -- Stuffbit entfernen, da count=5
                           stuff <= '1';
                           buf   := bitin;
            WHEN "1010" => stfer <='1';      -- stuff error, buf=bitin und count=5
                           stuff <= '0';
                           count := 0;
            WHEN "1000" => count :=count+1;  -- gleiches Bit aber keine Regelverletzung
                           stuff <= '0';     -- buf=bitin, count <6
            WHEN "0001"|"1001"|"0101"|"1101"|"0011"|"1011" => NULL ; -- Durchschalten  
            WHEN OTHERS => NULL;
          END CASE;
          bitout <= bitin;              -- Bit weitergeben
        ELSE
          edged := '1';
        END IF;
      ELSE
        edged := '0';
      END IF;
      END IF;
    END IF;
  END PROCESS;
END;
