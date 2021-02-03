LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;
USE ieee.std_logic_arith.ALL;
LIBRARY synopsys;
USE synopsys.attributes.ALL; 
-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                           
-------------------------------------------------------------------------------
-- R eceive
-- E rror
-- C ounter zählt vom MAC gemeldete Fehler und gibt an den kritischen Punkten
-- (96,128,256) Signale an faultfsm
-------------------------------------------------------------------------------
-- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  
ENTITY tec1 IS

  PORT (
    reset     : IN  bit;                -- resetgen
    clock     : IN  bit;
    incegttra : IN  bit;                -- MACFSM +8
    dectra    : IN  bit;                -- MACFSM -1
    tec_lt96  : OUT bit;                -- faultfsm, ok
    tec_ge96  : OUT bit;                -- faultfsm, warning
    tec_ge128 : OUT bit;                -- faultfsm, errorpassive
    tec_ge256 : OUT bit;               -- faultfsm, busoff
    teccount  : out bit_vector(7 DOWNTO 0));
END tec1;

ARCHITECTURE behv OF tec1 IS
  SIGNAL counter : integer RANGE 0 TO 511;-- ein Register mehr= Merker für Überlauf
  SIGNAL edged   : bit; -- Flankenmerker, deglitch
  SIGNAL action  : bit;
BEGIN  -- behv

  action <= incegttra OR dectra;-- dann wird gearbeitet
  teccount <= to_bitvector(conv_std_logic_vector(counter,8)); 
  count : PROCESS (clock)
  BEGIN  -- PROCESS count
    IF clock'event AND clock = '1' THEN       -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
      IF reset = '0' THEN                     -- synchronous reset (active low)
        counter        <= 0;
        edged <= '0';
        
      ELSIF action = '1' THEN
        IF edged = '0' THEN             -- Flankenmerker
          edged      <= '1';            -- jetzt war sie
          IF counter <= 255 AND incegttra = '1' THEN  -- erhöhen, wenn geht
            counter  <= counter+8;
          ELSIF counter/=0 AND dectra = '1' THEN
            counter  <= counter-1;      -- dekrement, wenn geht
          END IF;
        END IF;  -- edged
      ELSE       -- action='0'
        edged        <= '0';
      END IF;  -- action          
    END IF;
  END PROCESS count;
-------------------------------------------------------------------------------
-- Auswertung
  evaluate : PROCESS (counter)
  BEGIN  -- PROCESS evaluate
    IF counter >= 256 THEN              -- busoff
      tec_lt96    <= '0';               
      tec_ge96    <= '1';               -- >=96
      tec_ge128   <= '1';               -- >=128
      tec_ge256   <= '1';               -- >=256
    ELSIF counter >= 128 AND counter < 256 THEN  -- errorpassive
      tec_lt96    <= '0';
      tec_ge96    <= '1';               -- >=96
      tec_ge128   <= '1';               -- >=128
      tec_ge256   <= '0';
    ELSIF counter <= 127 AND counter >= 96 THEN  -- warning
      tec_lt96    <= '0';
      tec_ge96    <= '1';               -- >=96
      tec_ge128   <= '0';
      tec_ge256   <= '0';
    ELSE                                -- erroractive
      tec_lt96    <= '1';               -- <96
      tec_ge96    <= '0';
      tec_ge128   <= '0';
      tec_ge256   <= '0';
    END IF;
  END PROCESS evaluate;
END behv;
