-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                         
-------------------------------------------------------------------------------
-- Ausgelagert aus bittime-FSM um extrahierbar zu bekommen. ctrl steurt
-- Verhalten: Bei "01" AUsgang "1", Bei "10" Ausgang Puffer (Aus edge_puffer),
-- das Bit um eine Bitzeit verzögert.
ENTITY smpldbit_reg1 IS
  PORT (
    clock    : IN  bit;
    reset    : IN  bit;
    ctrl     : IN  bit_vector(1 DOWNTO 0);  -- bittime fsm: smpldbit_reg_ctrl
    smpldbit : OUT bit;                     -- MAC, destuff, biterrordetect
    puffer   : IN  bit);                    -- edgepuffer: puffer
END smpldbit_reg1;

ARCHITECTURE behv OF smpldbit_reg1 IS

BEGIN  -- behv
-------------------------------------------------------------------------------
  reg : PROCESS (clock, reset)
  BEGIN  -- PROCESS latch
--    IF clock'event AND clock = '1' THEN       -- (vorher neg. Flanke)
                                              -- DW: 2005.06.26 auf
                                              -- pos. Flanke geändert
--      IF reset = '0' THEN                     -- synchroner Reset
--        smpldbit <= '1';                      -- rezessiv
--      ELSE
--        CASE ctrl IS
--          WHEN "01"   => smpldbit <= '1';     -- rezessiv
--          WHEN "10"   => smpldbit <= puffer;  -- verspätet
--          WHEN OTHERS => NULL;
--        END CASE;
--      END IF;
--    END IF;

  if (reset = '0') then
    smpldbit <= '1';
  elsif (clock'event and clock = '1') then
       CASE ctrl IS
          WHEN "01"   => smpldbit <= '1';     -- rezessiv
          WHEN "10"   => smpldbit <= puffer;  -- verspätet
          WHEN OTHERS => NULL;
        END CASE;
  end if;
    
  END PROCESS reg;

END behv;
