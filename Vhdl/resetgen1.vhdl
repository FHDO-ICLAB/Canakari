-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                         
-------------------------------------------------------------------------------
-- Reset Generator für  Für 3 normale (clock_in) Taktflanken das
-- Resetsignal aktivieren, damit synchrone Register
-- zurückgesetzt werden.
ENTITY resetgen1 IS
  PORT (
    reset      : IN  bit;               -- aussen
    sync_reset : OUT bit;               -- Alle Komponenten, bis auf prescaler
    clock      : IN  bit);              -- aussen
END resetgen1;

ARCHITECTURE behv OF resetgen1 IS
  SIGNAL count : integer RANGE 0 TO 3;
  SIGNAL active : bit;                  -- high, solange reset counter aktiv

BEGIN  -- behv
  sync_reset <= reset AND NOT active;
  activate: PROCESS (reset,clock)
  BEGIN  -- PROCESS activate
    IF reset='0' THEN                   -- asynchroner Reset (low aktiv)
      active <= '1';                    -- Aktivieren
      count <= 0;                       -- Zähler klarmachen
    elsIF clock'event AND clock='1' THEN  -- positive Flanke
      IF active='1' THEN
        IF count=3 THEN                 -- 0,1,2= drei Taktflanken
          active <= '0';                -- deaktivieren
        ELSE
          count <= count +1;            -- inkrementieren
        END IF;
      END IF;
    END IF;
  END PROCESS activate;
END behv;
