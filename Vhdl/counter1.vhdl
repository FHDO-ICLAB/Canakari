-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell 
--                                     Diplomarbeit 
-------------------------------------------------------------------------------
--                            Datei: counter.vhd
--                     Beschreibung: received/sent bits counter 
-------------------------------------------------------------------------------
-- reset synchron, negative clock-Flanke
-- DW 2005.06.30 Prescale Enable eingefügt.
-- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  
USE work.ALL;
ENTITY counter1 IS
  PORT(clock         : IN  bit;
       Prescale_EN   : IN  bit;
       inc           : IN  bit;         -- MACFSM, Zähler inkrementieren
       reset         : IN  bit;
       lt3, gt3, eq3 : OUT bit;         -- MACFSM, lower, greater, equal 3
       lt11, eq11    : OUT bit;         -- MACFSM, lower, equal 11
       counto        : OUT integer RANGE 0 TO 127);
END counter1;

ARCHITECTURE behv OF counter1 IS
  SIGNAL inc_rise_merker : bit;         -- de-glitchen
  SIGNAL count           : integer RANGE 0 TO 127;
BEGIN
  PROCESS(clock)
  BEGIN
    IF (clock'event AND clock = '1') THEN   -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
      IF Prescale_EN = '1' THEN            -- DW 2005.06.30 Prescale Enable eingefügt.
        IF(reset = '0') THEN
          count           <= 0;
          inc_rise_merker <= '0';
        ELSIF inc = '1' THEN
          IF inc_rise_merker = '0' THEN  -- flanke merken
            inc_rise_merker <= '1';     -- flanke war schon
            IF(count = 127) THEN        -- Überlauf
              count <= 0;
            ELSE
              count <= count+1;         -- hochzählen
            END IF;
          END IF;
        ELSE
          inc_rise_merker <= '0';  -- flankenmerker für nächste flanke vorbereiten
        END IF;
      END IF;
    END IF;
  END PROCESS;
-------------------------------------------------------------------------------  
-- purpose: für intermission werden hier signale für <,>,= 3 und 11 generiert,
-- um MACFSM mit DC extrahierbar zu bekommen.
-- type   : combinational
-- inputs : count
-- outputs: lt11, eq11, lt3, gt3, eq3
  FSM_events : PROCESS (count)
  BEGIN  -- PROCESS FSM_events
--Kleiner/Gleich/Grösser 11?
    IF count < 3 THEN
      lt3 <= '1'; gt3 <= '0'; eq3 <= '0';
    ELSIF count = 3 THEN
      lt3 <= '0'; gt3 <= '0'; eq3 <= '1';
    ELSE
      lt3 <= '0'; gt3 <= '1'; eq3 <= '0';
    END IF;
-- Kleiner/Gleich 11?
    IF count < 11 THEN
      lt11 <= '1'; eq11 <= '0';
    ELSIF count = 11 THEN
      lt11 <= '0'; eq11 <= '1';
    ELSE
      lt11 <= '0'; eq11 <= '0';
    END IF;
  END PROCESS FSM_events;
  counto <= count;                      -- Signal raus

END behv;

