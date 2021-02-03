-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell
--                                     Diplomarbeit
-------------------------------------------------------------------------------
--                            Datei: timecount.vhd
--                     Beschreibung: Grundzeiteinheitenzähler
-------------------------------------------------------------------------------
-- DW 2005.06.21 Prescale Enable eingefügt
  
  
ENTITY timecount1 IS
  PORT(clock     : IN  bit;                     -- prescaler
       Prescale_EN : IN  bit;                   -- DW 2005.06.21 Prescale Enable
       reset     : IN  bit;                     -- resetgen
       increment : IN  bit;                     -- fsm
       setctzero : IN  bit;                     -- fsm
       setctotwo : IN  bit;                     -- fsm
       counto    : OUT integer RANGE 0 TO 15);  -- sum (arithmetik)
END timecount1;

ARCHITECTURE behv OF timecount1 IS
  SIGNAL count : integer RANGE 0 TO 15;
------------------------------------------------------------------------------- 
BEGIN
  counto <= count;                           -- übergeben
  PROCESS(clock, reset)
  BEGIN
    IF (reset = '0') THEN                    -- asynchroner reset
      count <= 0;
    ELSIF(clock'event AND clock = '1') THEN  -- pos. flanke
      IF Prescale_EN = '1' THEN              -- DW 2005.06.21 Prescale Enable
        IF(setctzero = '1') THEN             -- null setzen
          count <= 0;
        ELSIF(increment = '1') THEN          -- erhöhen
          count <= count+1;
        ELSIF(setctotwo = '1') THEN          -- auf 2 setzen
          count <= 2;
        ELSE
          count <= count;                    -- halten
        END IF;
      END IF;  
    END IF;
  END PROCESS;
END behv;
