-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                         
-------------------------------------------------------------------------------
-- RSHIFT_CELL
-- Für optimierte Synthese: Ein einfaches Register, synchroner
-- reset (act. low) und taktabhängigem input (pos. edge)
ENTITY rshift_cell1 IS
  PORT (
	  enable  : IN bit;
    clock   : IN  bit;
    reset   : IN  bit;
    input   : IN  bit;
    q       : OUT bit);
END rshift_cell1;

ARCHITECTURE behv OF rshift_cell1 IS

BEGIN  -- behv
  FF2: PROCESS (clock)
--   VARIABLE reg : bit;
  BEGIN  -- PROCESS FF2
    IF clock'event AND clock = '1' THEN  -- rising clock edge
      IF reset = '0' THEN                 -- synchronous reset (active low)
        q <= '0';
      ELSE
	     IF enable = '1' THEN
        q <= input;
		   END IF;
      END if;
    END IF;
  END PROCESS FF2;

END behv;
