-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                           
-------------------------------------------------------------------------------
-- equal_id: Akzeptanzprüfung im LLC, verglichen wird id aus dem arbitration
-- register in IOCPU (rarbit) mit empfangener aus MAC, decapsulation. equal=1,
-- wenn gleich. Zur Extrahierbarkeit von LLC_fsm eingebaut
-- Empfangsbedingung wird hier ueberprüft. Acceptance Mask und idregister legen 
-- diese fest.
-------------------------------------------------------------------------------
ENTITY equal_id1 IS
  
  PORT (
    extended   : IN  bit;                      -- IOCPU, recmescontrolreg
    idregister : IN  bit_vector(28 DOWNTO 0);  -- IOCPU, rarbit
    idreceived : IN  bit_vector(28 DOWNTO 0);  -- MAC, decapsulation
    accmask    : in  bit_vector(28 downto 0);  -- NEU Acception Mask
    equal      : OUT bit);                     -- LLC_FSM

END equal_id1;

ARCHITECTURE behv OF equal_id1 IS

BEGIN  -- behv
-- Vergleich abhängig vom IDE
  eq : PROCESS (extended, idregister, idreceived, accmask)
  BEGIN  -- PROCESS eq
    IF ((extended = '1' AND ((idregister XOR idreceived) AND accmask)="00000000000000000000000000000") OR
        (extended = '0' AND ((idregister(28 DOWNTO 18) XOR idreceived(28 DOWNTO 18))and accmask(28 downto 18))="00000000000")) THEN
      equal <= '1';
    ELSE
      equal <= '0';
    END IF;
  END PROCESS eq;

END behv;
