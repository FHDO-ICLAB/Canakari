-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                           
-------------------------------------------------------------------------------
-- TSHIFT_CELL
-- Für optimierte Synthese: Ein einfaches Register, synchroner
-- reset (act. low) und taktabhängigem input (pos. edge), preload mit enable
-- Eingang load.
ENTITY tshift_cell1 IS
  PORT (
    enable  : IN  bit;
    preload : IN  bit;
    clock   : IN  bit;
    reset   : IN  bit;
    load    : IN  bit;
    input   : IN  bit;
    q       : OUT bit);
END tshift_cell1;

ARCHITECTURE behv OF tshift_cell1 IS

BEGIN  -- behv
  FF2: PROCESS (clock, reset)
--   VARIABLE reg : bit;
  BEGIN  -- PROCESS FF2
    IF clock'event AND clock = '1' THEN  -- rising clock edge
      IF reset = '0' THEN                 -- asynchronous reset (active low)
        q <= '0';
      ELSE
        IF enable = '1' THEN                     -- load ist enable, entwd. input oder preload
          q <= (preload AND load) OR (input AND NOT load);
        END if;
      END IF;
    END IF;
  END PROCESS FF2;
END behv;
