-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell  
--                                     Diplomarbeit
-------------------------------------------------------------------------------
--                            Datei: decaps.vhd
--                     Beschreibung: decapsulation unit
-------------------------------------------------------------------------------
-- Nur noch Identitifier für LLC, Register aufbereiten, Daten nun direkt aus
-- rshift in IOCPU, da fastshift an gleiche Positionen schiebt. Keine Register
-- mehr, message_b, message_c kommen aus rshift (b: 88 downto 71 (18 Bit ext-id))
-- (c: 101 downto 91 (11 Bit bas-id))

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;


ENTITY decapsulation1 IS

  PORT (
    message_b  : IN  bit_vector(17 DOWNTO 0);  -- ext-id, rshift
    message_c  : IN  bit_vector(10 DOWNTO 0);  -- bas-id, rshift
    extended   : IN  bit;               -- aus FSM-register (über MACFSM)
    identifier : OUT bit_vector( 28 DOWNTO 0));

END decapsulation1;

ARCHITECTURE behv OF decapsulation1 IS
BEGIN
  idres : PROCESS(message_b, message_c, extended)
  BEGIN
    IF extended = '0' THEN              -- BASIC Datenrahmen, id sitzt unten
                                        -- am Anfang des Extended Feldes
      identifier(28 DOWNTO 18) <= message_b( 10 DOWNTO 0); 
      identifier(17 DOWNTO 0)  <= (OTHERS => '0');
    ELSE                                -- Extended Datenrahmen, id sitzt passend
      identifier(17 DOWNTO 0)  <= message_b;
      identifier(28 DOWNTO 18) <= message_c;
    END IF;
  END PROCESS;
END;
