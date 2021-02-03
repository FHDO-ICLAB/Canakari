-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell
--                                     Diplomarbeit
-------------------------------------------------------------------------------
-- RCRC_CELL
-- Für optimierte Synthese: Ein einfaches Register, synchroner
-- reset (act. low) und taktabhängigem input (pos. edge)

  
ENTITY rcrc_cell1 IS
  PORT (
    enable  : IN bit;
    clock   : IN  bit;
    reset   : IN  bit;
    input   : IN  bit;
    q       : OUT bit);
END rcrc_cell1;

ARCHITECTURE behv OF rcrc_cell1 IS

BEGIN  -- behv
  FF2: PROCESS (clock)
  variable edge : bit := '0';
  BEGIN  -- PROCESS FF2
    IF clock'event AND clock = '1' THEN  -- rising clock edge
      IF reset = '0' THEN                 -- synchronous reset (active low)
        q <= '0';
        edge := '0';
      ELSE
        IF enable = '1' and edge = '0' THEN
          q <= input;
          edge := '1';
         ELSIF enable = '0' and edge = '1' THEN
          edge := '0';
        END IF;
      END IF;
    END IF;
  END PROCESS FF2;
END behv;
