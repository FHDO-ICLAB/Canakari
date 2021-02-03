-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell
--                                     Diplomarbeit
-------------------------------------------------------------------------------
-- TCRC_CELL
-- Für optimierte Synthese: Ein einfaches Register, synchroner
-- reset (act. low) und taktabhängigem input (pos. edge), preload für vorladen
-- des registers, wg. crc-änderung. Enable mit load
ENTITY tcrc_cell1 IS
  PORT (
    enable  : IN  bit;
    preload : IN  bit;
    clock   : IN  bit;
    reset   : IN  bit;
    load    : IN  bit;
    input   : IN  bit;
    q       : OUT bit);
END tcrc_cell1;

ARCHITECTURE behv OF tcrc_cell1 IS
BEGIN  -- behv
  FF2 : PROCESS (clock)
--    VARIABLE reg : bit;
  BEGIN  -- PROCESS FF2
    IF clock'event AND clock = '1' THEN  -- rising clock edge
      IF reset = '0' THEN                -- synchronous reset (active low)
        q <= '0';
      ELSE                               -- load ist der enable, entwd. input
                                         -- oder preload
        IF enable = '1' then                                 
          q <= (preload AND load) OR (input AND NOT load);
        END IF;
      END IF;
    END IF;
  END PROCESS FF2;

END behv;
