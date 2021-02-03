-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                           
-------------------------------------------------------------------------------
-- E leven
-- R eceived
-- B its
-- count er: für BUSOFF Zustand, MACFSM sendet Signal, wenn 11 zusammenhängende
-- rezessive Bits gesamplet wurden. erb_eq128 sorgt für faultfsm
-- Zustandsübergang nach Erroractive
-------------------------------------------------------------------------------
-- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  
ENTITY erbcount1 IS
  
  PORT (
    clock     : IN  bit;
    reset     : IN  bit;
    elevrecb  : IN  bit;                -- MACFSM
    erb_eq128 : OUT bit);               -- faultfsm

END erbcount1;

ARCHITECTURE behv OF erbcount1 IS
  SIGNAL counter : integer RANGE 0 TO 128;  -- ein Register mehr= Merker für Überlauf
  SIGNAL edged : bit;                   -- Flankenmerker, deglitch

BEGIN  -- behv

  count: PROCESS (clock)
  BEGIN  -- PROCESS count
    IF clock'event AND clock = '1' THEN  -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
      IF reset = '0' THEN                 -- synchronous reset (active low)
        counter <= 0;
        edged <= '0';
      elsIF elevrecb='1' THEN
        IF edged='0' THEN               -- Flanke merken
          edged <= '1';
          IF counter<128 THEN
            counter <= counter+1;       -- inkrementieren, reset macht faultfsm
          END IF;
        END IF;                         -- edged
      ELSE
        edged <= '0';                   -- Flanke zurücksetzen
      END IF;                           -- elevrecb
    END IF;
  END PROCESS count;
-------------------------------------------------------------------------------
-- Auswertung, Überlauf stattgefunden?
  evaluate: PROCESS (counter)
  BEGIN  -- PROCESS evaluate
    IF counter=128 THEN
      erb_eq128 <= '1';
    ELSE
      erb_eq128 <= '0';
    END IF;
  END PROCESS evaluate;
END behv;
