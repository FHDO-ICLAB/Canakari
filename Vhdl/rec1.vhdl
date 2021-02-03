LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;
USE ieee.std_logic_arith.ALL;
LIBRARY synopsys;
USE synopsys.attributes.ALL;
------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                           
-------------------------------------------------------------------------------
-- R eceive
-- E rror
-- C ounter, zählt vom MAC gemeldete Fehler und gibt an den kritischen Punkten
-- (96 und 128) Signale an faultfsm
-------------------------------------------------------------------------------
-- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  
ENTITY rec1 IS

  PORT (
    reset     : IN  bit;                -- resetgen, (OR) faultfsm
    clock     : IN  bit;
    inconerec : IN  bit;                -- MACFSM +1
    incegtrec : IN  bit;                -- MACFSM +8
    decrec    : IN  bit;                -- MACFSM -1
    rec_lt96  : OUT bit;                -- faultfsm, ok
    rec_ge96  : OUT bit;                -- faultfsm, warning
    rec_ge128 : OUT bit;               -- faultfsm, errorpassive
    reccount  : out bit_vector(7 DOWNTO 0));
END rec1;

ARCHITECTURE behv OF rec1 IS
  SIGNAL counter : integer RANGE 0 TO 511;  -- ein Register mehr= Merker für Überlauf
  SIGNAL edged   : bit;                 -- Flankenmerker, deglitch
  SIGNAL action  : bit;
 
BEGIN  -- behv

  action <= inconerec OR incegtrec OR decrec;  -- dann wird gearbeitet
  
  reccount <= to_bitvector(conv_std_logic_vector(counter,8));
  count : PROCESS (clock)
  BEGIN  -- PROCESS count
    IF clock'event AND clock = '1' THEN  -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
      IF reset = '0' THEN                -- synchronous reset (active low)
        counter <= 0;
        edged   <= '0';
      ELSIF action = '1' THEN
        IF edged = '0' THEN              -- Flankenmerker
          edged      <= '1';             -- Flanke gemerkt
          IF counter /= 0 AND decrec = '1' THEN
            counter <= counter-1;        -- runterzählen nur wenn nicht 0
          ELSIF counter <= 255 THEN

            IF inconerec = '1' THEN
              counter <= counter+1;      -- inkrementieren, reset von fsm
            ELSIF incegtrec = '1' THEN
              counter <= counter+8;      -- oder um 8 inkrementieren
            END IF;

          END IF;  -- counter
        END IF;  -- edged
      ELSE                               -- action='0'
        edged <= '0';                    -- Flankenmerker resetten
      END IF;  -- action
    END IF;
  END PROCESS count;
-------------------------------------------------------------------------------
-- Auswertung Zählerstand: 96 Warning, 128 Errorpassive
  evaluate : PROCESS (counter)
  BEGIN  -- PROCESS evaluate
    IF counter > 127 THEN
      rec_lt96  <= '0';
      rec_ge96  <= '1';
      rec_ge128 <= '1';
    ELSIF counter <= 127 AND counter >= 96 THEN
      rec_lt96  <= '0';
      rec_ge96  <= '1';
      rec_ge128 <= '0';
    ELSE
      rec_lt96  <= '1';
      rec_ge96  <= '0';
      rec_ge128 <= '0';
    END IF;
  END PROCESS evaluate;
END behv;
