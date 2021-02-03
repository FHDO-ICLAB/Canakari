-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell
--                                     Diplomarbeit 
-------------------------------------------------------------------------------
--                            Datei: bittime.vhd
--                     Beschreibung: Bittiming FSM
--                          Teil von bittiming
-------------------------------------------------------------------------------
-- Änderungen: Latches für smpldbit und tsegreg ausgelagert für Extraktion
-- DW 2005.06.21 Prescale Enable eingefügt

-- | Leduc | 12.02.2020 | Added Changes done in Verilog Triplication Files
  
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY bittime1 IS
  PORT(clock              : IN  bit;
       Prescale_EN : IN  bit;           -- DW 2005.06.21 Prescale Enable
       reset              : IN  bit;
       hardsync           : IN  bit;    -- von MACFSM
       notnull            : IN  bit;    -- von sum counter /= 0
       gtsjwp1            : IN  bit;    --   "     counter > sjw+1
       gttseg1p1          : IN  bit;    --   "     counter > tseg1+1 (nach smplpoint)
       cpsgetseg1ptseg2p2 : IN  bit;    --   "     counter ist sjw vor ende
       cetseg1ptseg2p1    : IN  bit;    --   "     counter ist am ende der bitzeit
       countesmpltime     : IN  bit;    --   "     counter = smplpoiunt
       puffer             : IN  bit;    -- von edgepuffer (smpldbit ein Bit verzögert)
       rx                 : IN  bit;    -- von aussen (CAN-BUS in)
       increment          : OUT bit;    -- zu timecount
       setctzero          : OUT bit;    -- zu  "
       setctotwo          : OUT bit;    -- zu  "
       sendpoint          : OUT bit;    -- zu MACFSM
       smplpoint          : OUT bit;    -- zu MACFSM
       smpldbit_reg_ctrl  : OUT bit_vector(1 DOWNTO 0);   -- steuert ext. Latch smpldbit
       tseg_reg_ctrl      : OUT bit_vector(1 DOWNTO 0);   -- steuert externes Latch
       bitst              : OUT std_logic_vector(3 downto 0));  -- debug-state
END bittime1;

-- smpldbit_reg_ctrl: "01": '1' ; "10": 'puffer' ; others: hold
-- tseg_reg_ctrl: "01" : tseg1 (aus Register) "10": tseg1pcount (aus sum) "11":
--                      tseg1p1psjw (aus sum) "00": hold


ARCHITECTURE behv OF bittime1 IS
  TYPE STATE_TYPE IS (normal, hardset, stretchok, stretchnok, slimok, slimnok,
                      sndprescnt, samplepoint, resetstate);

  SIGNAL current_state, next_state : STATE_TYPE;
  ATTRIBUTE STATE_VECTOR           : string;
  ATTRIBUTE STATE_VECTOR OF behv   : ARCHITECTURE IS "CURRENT_STATE";
BEGIN
  -----------------------------------------------------------------------------
  -- Kombinatorik
  -----------------------------------------------------------------------------
  COMBIN : PROCESS (current_state, hardsync, rx, puffer, notnull, gtsjwp1, gttseg1p1,
                   cpsgetseg1ptseg2p2, cetseg1ptseg2p1, countesmpltime)
  BEGIN
    CASE current_state IS
      ---------------------------------------------------------------------------
      WHEN resetstate =>
        increment  <= '0'; setctzero <= '0'; setctotwo <= '0'; sendpoint <= '0';
        smplpoint  <= '0'; smpldbit_reg_ctrl <= "01"; tseg_reg_ctrl <= "01";
        next_state <= hardset;
        ---------------------------------------------------------------------------
      WHEN normal =>
        increment <= '1'; setctzero <= '0'; setctotwo <= '0'; sendpoint <= '0';
        smplpoint <= '0'; smpldbit_reg_ctrl <= "00"; tseg_reg_ctrl <= "00";
        IF(rx = '0' AND puffer = '1') THEN
          IF(hardsync = '1') THEN
            next_state <= hardset;
          ELSE
            IF(notnull = '1' AND gtsjwp1 = '0') THEN
              next_state <= stretchok;
            ELSIF(gtsjwp1 = '1' AND gttseg1p1 = '0') THEN
              next_state <= stretchnok;
            ELSIF(gttseg1p1 = '1' AND cpsgetseg1ptseg2p2 = '0') THEN
              next_state <= slimnok;
            ELSIF(cpsgetseg1ptseg2p2 = '1') THEN
              next_state <= slimok;
            ELSE
              next_state <= normal;
            END IF;
          END IF;
        ELSE
          IF(cetseg1ptseg2p1 = '1') THEN
            next_state <= sndprescnt;
          ELSIF(countesmpltime = '1') THEN
            next_state <= samplepoint;
          ELSE
            next_state <= normal;
          END IF;
        END IF;
        ---------------------------------------------------------------------------
      WHEN hardset =>
        increment  <= '0'; setctzero <= '0'; setctotwo <= '1'; sendpoint <= '1';
        smplpoint  <= '0'; smpldbit_reg_ctrl <= "00"; tseg_reg_ctrl <= "01";
        next_state <= normal;
        ---------------------------------------------------------------------------
      WHEN sndprescnt =>
        increment <= '0'; setctzero <= '1'; setctotwo <= '0'; sendpoint <= '1';
        smplpoint <= '0'; smpldbit_reg_ctrl <= "00"; tseg_reg_ctrl <= "01";
        IF (rx = '0' AND puffer = '1') THEN
          IF(hardsync = '1') THEN
            next_state <= hardset;
          ELSE
            next_state <= slimok;
          END IF;
        ELSE
          next_state <= normal;
        END IF;
        ---------------------------------------------------------------------------
      WHEN stretchok =>
        increment  <= '1'; setctzero <= '0'; setctotwo <= '0'; sendpoint <= '0';
        smplpoint  <= '0'; smpldbit_reg_ctrl <= "00"; tseg_reg_ctrl <= "10";
        next_state <= normal;
        ---------------------------------------------------------------------------
      WHEN stretchnok =>
        increment  <= '1'; setctzero <= '0'; setctotwo <= '0'; sendpoint <= '0';
        smplpoint  <= '0'; smpldbit_reg_ctrl <= "00"; tseg_reg_ctrl <= "11";
        next_state <= normal;
        ---------------------------------------------------------------------------
      WHEN slimok =>
        increment  <= '0'; setctzero <= '0'; setctotwo <= '1'; sendpoint <= '1';
        smplpoint  <= '0'; smpldbit_reg_ctrl <= "00"; tseg_reg_ctrl <= "01";
        next_state <= normal;
        ---------------------------------------------------------------------------
      WHEN slimnok =>
        increment <= '1'; setctzero <= '0'; setctotwo <= '0'; sendpoint <= '0';
        smplpoint <= '0'; smpldbit_reg_ctrl <= "00"; tseg_reg_ctrl <= "00";
        IF(cpsgetseg1ptseg2p2 = '1') THEN
          next_state <= slimok;
        ELSE
          next_state <= slimnok;
        END IF;
        ---------------------------------------------------------------------------
      WHEN samplepoint =>
        increment <= '1'; setctzero <= '0'; setctotwo <= '0'; sendpoint <= '0';
        smplpoint <= '1'; smpldbit_reg_ctrl <= "10"; tseg_reg_ctrl <= "00";
        IF(rx = '0' AND puffer = '1') THEN
          IF(hardsync = '1') THEN
            next_state <= hardset;
          ELSE
            IF(cpsgetseg1ptseg2p2 = '1') THEN
              next_state <= slimok;
            ELSE
              next_state <= slimnok;
            END IF;
          END IF;
        ELSE
          next_state <= normal;
        END IF;
        ---------------------------------------------------------------------------
    END CASE;
  END PROCESS;
-------------------------------------------------------------------------------
-- sequentielles:
-------------------------------------------------------------------------------
  SYNCH : PROCESS(CLOCK, RESET)
  BEGIN
    IF (RESET = '0') THEN               -- define an asynchronous reset
      CURRENT_STATE <= resetstate;      -- define the reset state
    ELSIF (CLOCK'event AND CLOCK = '1') THEN
      IF Prescale_EN = '1' THEN
        CURRENT_STATE <= NEXT_STATE; -- DW 2005.06.21 Prescale Enable
      END IF;
    END IF;
  END PROCESS;

  statedeb_p : PROCESS (current_state)
  BEGIN  -- PROCESS e
    CASE current_state IS
      WHEN normal      => bitst <= x"0";
      WHEN hardset     => bitst <= x"1";
      WHEN stretchok   => bitst <= x"2";
      WHEN stretchnok  => bitst <= x"3";
      WHEN slimok      => bitst <= x"4";
      WHEN slimnok     => bitst <= x"5";
      WHEN sndprescnt  => bitst <= x"6";
      WHEN samplepoint => bitst <= x"7";
      WHEN resetstate  => bitst <= x"8";
      WHEN OTHERS      => bitst <= x"a";
    END CASE;
  END PROCESS statedeb_p;



END;
