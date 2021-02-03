-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell
--                                     Diplomarbeit
-------------------------------------------------------------------------------
-- Der Prescaler teilt den 10 MHz Eingangstakt herunter:
-------------------------------------------------------------------------------
-- DW 2005.06.21 Prescale Enable eingefügt
-- DW 2005.06.26 Prescale Enable korregiert

-- | Leduc | 12.02.2020 | Added Changes done in Verilog Triplication Files

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;
ENTITY prescale1 IS
  
  PORT (
    clock       : IN  bit;
    reset       : IN  bit;
    high        : IN  bit_vector(3 DOWNTO 0);  -- IOCPU, prescaleregister
    low         : IN  bit_vector(3 DOWNTO 0);  -- IOCPU, prescaleregister
    Prescale_EN : OUT bit);                     -- DW 2005.06.21 Prescale Enable

END prescale1;
-------------------------------------------------------------------------------
ARCHITECTURE behv OF prescale1 IS
  SIGNAL lo_count, hi_count : integer RANGE 0 TO 15;
  SIGNAL hilo               : bit;      -- hi=1 , lo=0, Merker für akt, Flanke
  SIGNAL int_high, int_low  : integer RANGE 0 TO 15;
-------------------------------------------------------------------------------  
BEGIN  -- behv
-- Konvertierungen für Vergleich
  int_high  <= conv_integer(unsigned(to_stdLogicVector(high)));  -- bit_v zu int
  int_low   <= conv_integer(unsigned(to_stdLogicVector(low)));
-------------------------------------------------------------------------------  
  teil : PROCESS (clock, reset)
  BEGIN  -- PROCESS teil
    IF reset = '0' THEN                 -- asynchroner Reset
      lo_count <= 0;
      hi_count <= 0;
      hilo     <= '1';
      Prescale_EN <= '0';               -- DW 2005.06.21 Prescale Enable
    ELSIF (clock'event AND clock = '1') THEN
      -------------------------------------------------------------------------
      IF hilo = '1' THEN                -- Positiv Flanke
         Prescale_EN <= '0';           -- DW 2005.06.21 Prescale Enable        
        IF hi_count = int_high then    -- DW 2005.06.26 Übergang von hilo von
                                        -- 1 auf 0
          Prescale_EN <= '0';           -- DW 2005.06.26 Prescale Enable
          hi_count <= 0;                -- zurücksetzen
          hilo     <= '0';              -- umschalten
        ELSE
          hi_count <= hi_count+1;       -- inkrementieren
        END IF;
        -----------------------------------------------------------------------
      ELSE                              -- Negative Flanke

        IF lo_count = int_low THEN
          lo_count <= 0;                -- zurücksetzen
          hilo     <= '1';              -- umschalten
          Prescale_EN <= '1';         -- DW 2005.06.26 Prescale Enable         
        ELSE
          Prescale_EN <= '0';         -- DW 2005.06.21 Prescale Enable 
          lo_count <= lo_count+1;       -- inkrementieren         
        END IF;
        -------------------------------------------------------------------------
      END IF;
    END IF;
  END PROCESS teil;
END behv;
