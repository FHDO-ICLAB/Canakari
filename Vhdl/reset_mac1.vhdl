-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                         
-------------------------------------------------------------------------------
-- Reset Generator für MAC. Für 3 langsame (prescaler) Taktflanken das
-- Resetsignal aktivieren, damit langsam getaktete, synchrone Register
-- zurückgesetzt werden.
-- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.

-- | Leduc | 12.02.2020 | Added Changes done in Verilog Triplication Files
  
ENTITY reset_mac1 IS
  
  PORT (
    reset      : IN  bit;               -- resetgen
    sync_reset : OUT bit;               -- MAC-Komponenten
    clock      : IN  bit;
    prescaler  : IN  bit);              -- prescaler

END reset_mac1;

ARCHITECTURE behv OF reset_mac1 IS
  SIGNAL count : integer RANGE 0 TO 3;
  SIGNAL active : bit;                  -- high, solange reset counter aktiv

BEGIN  -- behv
  sync_reset <= reset AND NOT active;
  activate: PROCESS (reset,clock)
  BEGIN  -- PROCESS activate
    IF reset='0' THEN                   -- asynchroner Reset (low aktiv)
      active <= '1';                    -- Aktivieren
      count <= 0;                       -- Zähler klarmachen
    ELSIF clock'event AND clock='1' THEN  -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
     IF (prescaler = '1') THEN 
      IF active='1' THEN
        IF count=3 THEN                 -- 0,1,2= drei Taktflanken
          active <= '0';                -- deaktivieren
        ELSE
          count <= count +1;            -- inkrementieren
        END IF;
      END IF;
    END IF;
   END IF;
  END PROCESS activate;
END behv;
