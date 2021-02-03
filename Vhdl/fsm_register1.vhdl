-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                           
-------------------------------------------------------------------------------
-- fsm_register: Auslagerung der MACFSM Latches
-- Diese Signale waren intern. Jetzt werden sie aus der macfsm so gesteuert:
-- signalxx_set="11"; -- auf 1 setzen
-- signalxx_set="10"; -- auf 0 setzen
-- signalxx_set="00"; -- Unverändert lassen;
-- signalxx_set="01"; --         
--
-- signalxx steht für:
--   ackerror 
--   onarbit     
--   transmitter 
--   receiver    
--   error       
--   first       
--   puffer
--   rext
--   rrtr
-------------------------------------------------------------------------------
-- reset synchron, neg. FLanke
-- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;


ENTITY fsm_register1 IS
  
  PORT (
    clock           : IN  bit;
    reset           : IN  bit;
    ackerror_set    : IN  bit_vector(1 DOWNTO 0);  -- Steuereingang
    onarbit_set     : IN  bit_vector(1 DOWNTO 0);
    transmitter_set : IN  bit_vector(1 DOWNTO 0);
    receiver_set    : IN  bit_vector(1 DOWNTO 0);
    error_set       : IN  bit_vector(1 DOWNTO 0);
    first_set       : IN  bit_vector(1 DOWNTO 0);
    puffer_set      : IN  bit_vector(1 DOWNTO 0);
    rext_set        : IN  bit_vector(1 DOWNTO 0);
    rrtr_set        : IN  bit_vector(1 DOWNTO 0);
    ackerror        : OUT bit;                     -- Register Ausgang
    onarbit         : OUT bit;
    transmitter     : OUT bit;
    receiver        : OUT bit;
    error           : OUT bit;
    first           : OUT bit;
    puffer          : OUT bit;
    rext            : OUT bit;
    rrtr            : OUT bit);

END fsm_register1;

ARCHITECTURE behv OF fsm_register1 IS

BEGIN  -- behv
-------------------------------------------------------------------------------
  ackerror_proc : PROCESS (clock)
  BEGIN  -- PROCESS ackerror
    IF clock'event AND clock = '1' THEN  -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
      IF reset = '0' THEN                -- synchroner Reset
        ackerror <= '0';
      ELSE
        CASE ackerror_set IS
          WHEN "11" =>                   -- Setzen
            ackerror <= '1';
          WHEN "10" =>                   -- Zurücksetzen
            ackerror <= '0';
          WHEN OTHERS => NULL;           -- Halten (00 und 01)
        END CASE;
      END IF;
    END IF;
  END PROCESS ackerror_proc;
-------------------------------------------------------------------------------
  onarbit_proc : PROCESS (clock)
  BEGIN  -- PROCESS onarbit
    IF clock'event AND clock = '1' THEN  -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
      IF reset = '0' THEN
        onarbit <= '0';
        CASE onarbit_set IS
          WHEN "11" =>
            onarbit <= '1';
          WHEN "10" =>
            onarbit <= '0';
          WHEN OTHERS => NULL;
        END CASE;
      END IF;
    END IF;
  END PROCESS onarbit_proc;
-------------------------------------------------------------------------------
  transmitter_proc : PROCESS (clock)
  BEGIN  -- PROCESS transmitter
    IF clock'event AND clock = '1' THEN  -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
      IF reset = '0' THEN
        transmitter <= '0';
      ELSE
        CASE transmitter_set IS
          WHEN "11" =>
            transmitter <= '1';
          WHEN "10" =>
            transmitter <= '0';
          WHEN OTHERS => NULL;
        END CASE;
      END IF;
    END IF;
  END PROCESS transmitter_proc;
-------------------------------------------------------------------------------
  receiver_proc : PROCESS (clock)
  BEGIN  -- PROCESS receiver
    IF clock'event AND clock = '1' THEN  -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
      IF reset = '0' THEN
        receiver <= '0';
      ELSE
        CASE receiver_set IS
          WHEN "11" =>
            receiver <= '1';
          WHEN "10" =>
            receiver <= '0';
          WHEN OTHERS => NULL;
        END CASE;
      END IF;
    END IF;
  END PROCESS receiver_proc;
-------------------------------------------------------------------------------  
  error_proc : PROCESS (clock)
  BEGIN  -- PROCESS error
    IF clock'event AND clock = '1' THEN  -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
      IF reset = '0' THEN
        error <= '0';
      ELSE
        CASE error_set IS
          WHEN "11" =>
            error <= '1';
          WHEN "10" =>
            error <= '0';
          WHEN OTHERS => NULL;
        END CASE;
      END IF;
    END IF;
  END PROCESS error_proc;
-------------------------------------------------------------------------------
  first_proc : PROCESS (clock)
  BEGIN  -- PROCESS first
    IF clock'event AND clock = '1' THEN  -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
      IF reset = '0' THEN
        first <= '0';
      ELSE
        CASE first_set IS
          WHEN "11" =>
            first <= '1';
          WHEN "10" =>
            first <= '0';
          WHEN OTHERS => NULL;
        END CASE;
      END IF;
    END IF;
  END PROCESS first_proc;
-------------------------------------------------------------------------------
  puffer_proc : PROCESS (clock)
  BEGIN  -- PROCESS puffer
    IF clock'event AND clock = '1' THEN  -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
      IF reset = '0' THEN
        puffer <= '0';
      ELSE
        CASE puffer_set IS
          WHEN "11" =>
            puffer <= '1';
          WHEN "10" =>
            puffer <= '0';
          WHEN OTHERS => NULL;
        END CASE;
      END IF;
    END IF;
  END PROCESS puffer_proc;
-------------------------------------------------------------------------------  
  rext_proc : PROCESS (clock)
  BEGIN  -- PROCESS rext
    IF clock'event AND clock = '1' THEN  -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
      IF reset = '0' THEN
        rext <= '0';
      ELSE
        CASE rext_set IS
          WHEN "11" =>
            rext <= '1';
          WHEN "10" =>
            rext <= '0';
          WHEN OTHERS => NULL;
        END CASE;
      END IF;
    END IF;
  END PROCESS rext_proc;
-------------------------------------------------------------------------------  
  rrtr_proc : PROCESS (clock)
  BEGIN  -- PROCESS rrtr
    IF clock'event AND clock = '1' THEN  -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
      IF reset = '0' THEN
        rrtr <= '0';
      ELSE
        CASE rrtr_set IS
          WHEN "11" =>
            rrtr <= '1';
          WHEN "10" =>
            rrtr <= '0';
          WHEN OTHERS => NULL;
        END CASE;
      END IF;
    END IF;
  END PROCESS rrtr_proc;
END behv;
