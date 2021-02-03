-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell
--                                     Diplomarbeit
-------------------------------------------------------------------------------
--                            Datei: encaps.vhd
--                     Beschreibung: encapsulation unit
-------------------------------------------------------------------------------
-- reset synchron, neg. flanke
-- Data nun direkt aus Registern IOCPU in tshift

-- | Leduc | 12.02.2020 | Added Changes done in Verilog Triplication Files

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;

ENTITY encapsulation1 IS
  PORT(clock      : IN  bit; -- main clock
       identifier : IN  bit_vector( 28 DOWNTO 0);  -- IOCPU, tarbit
       extended   : IN  bit;            -- IOCPU, transmesconreg
       remote     : IN  bit;            -- IOCPU, transmesconreg
       activ      : IN  bit;            -- LLC: actvtcap
       reset      : IN  bit;
       datalen    : IN  bit_vector( 3 DOWNTO 0);   -- IOCPU, transmesconreg
       tmlen      : OUT bit_vector(3 DOWNTO 0);  -- reale Datalänge (0 bei RTR)
       message    : OUT bit_vector(38 DOWNTO 0));  -- tshift, tcrc, Id-Feld
                                                   -- richtig sortiert
END encapsulation1;

ARCHITECTURE behv OF encapsulation1 IS

SIGNAL datalen_buf : bit_vector(3 DOWNTO 0);
SIGNAL rem_sig : bit;  -- Changed name to rem_sig (rem is singalword)
  
BEGIN
  tmlen <= datalen_buf;                 -- tatsächlicher DLC
  datalenbuf : PROCESS (clock)
  BEGIN  -- PROCESS datalenbuf
    IF clock'event AND clock = '1' THEN -- rising active edge
      IF reset = '0' THEN               -- synchronous reset (active low)
        datalen_buf <= "0000";
        rem_sig <= '0';
      ELSE
        IF activ = '1' THEN
          IF (rem_sig = '0') THEN
            rem_sig <= '1';      
            IF remote = '1' THEN
             datalen_buf <= "0000";        -- RTR haben realen DLC=0
            ELSE
             datalen_buf <= datalen;       -- alle anderen: realer DLC=DLC
            END IF;
          END IF;      
        ELSE
          rem_sig <= '0';
        END IF;  
      END IF;
    END IF;  
  END PROCESS datalenbuf;
-------------------------------------------------------------------------------
  idres : PROCESS(identifier, datalen, remote, extended)
  BEGIN
    message(38)         <= '0';         -- start of frame    outbit: 102
    message(6)          <= remote;      -- RTR-Feld
    message(5 DOWNTO 4) <= "00";        -- Basic: IDE,r0; Extended r0,r1
    message(3 DOWNTO 0) <= datalen;     -- DLC Feld
    IF extended = '1' THEN              -- extended Datenrahmen
      message(37 DOWNTO 27) <= identifier (28 DOWNTO 18);  -- Basic id
      message(26 DOWNTO 25) <= "11";    -- SRR und IDE
      message(24 DOWNTO 7)  <= identifier(17 DOWNTO 0);    -- Extended id
      
    ELSE
      message(37 DOWNTO 18) <= (OTHERS => '0');           -- leer
      message(17 DOWNTO 7)  <= identifier(28 DOWNTO 18);  -- Basic id nach unten 
    END IF;
  END PROCESS;

END;
