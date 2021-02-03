-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell 
--                                     Diplomarbeit 
-------------------------------------------------------------------------------
--                            Datei: interruptregister.vhdl
--                     Beschreibung: Interrupt register speichert
--                                   sowohl IRQ-Informationen f�r die CPU
--                                   als auch die enable signale.
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;

ENTITY interrupregister1 IS
  PORT( clk        : IN  bit;
        rst        : IN  bit;
        cpu        : IN  bit;                   -- CPU wuenscht Zugriff
        can        : IN  bit;                   -- controller wuenscht Zugriff
        onoffnin   : IN  bit;
        iestatusp  : IN  bit;
        iesuctrap  : IN  bit;
        iesucrecp  : IN  bit;
        irqstatusp : IN  bit;
        irqsuctrap : IN  bit;
        irqsucrecp : IN  bit;
        irqstatusc : IN  bit;
        irqsuctrac : IN  bit;
        irqsucrecc : IN  bit;
        reg   : OUT bit_vector(15 DOWNTO 0));  -- Interruptregister
END interrupregister1 ;

ARCHITECTURE behv OF interrupregister1 IS

BEGIN
  PROCESS(clk, rst)
  BEGIN
    IF clk'event AND clk = '1' THEN
      IF rst = '0' THEN
        reg             <= "0000000000000000";
      ELSIF can = '1' THEN                -- Controller (Interruptunit) greift zu
        IF (irqstatusc = '1') THEN
          reg(2) <= irqstatusc;        -- Nur Setzen des Status Interruptes m�glich
        END IF; 
        IF (irqsuctrac = '1') THEN
          reg(1) <= irqsuctrac;        -- Nur Setzen des Successful transmit Interruptes m�glich
        END IF; 
        IF (irqsucrecc = '1') THEN
          reg(0) <= irqsucrecc;        -- Nur Setzen des Successful receive Interruptes m�glich
        END IF; 
      ELSIF cpu = '1' THEN             -- Treiber greift auf Interrupregister zu
        reg(15) <= onoffnin;
        reg(6) <= iestatusp;
        reg(5) <= iesuctrap;
        reg(4) <= iesucrecp;
        IF (irqstatusp = '0') THEN     -- Nur R�cksetzen des Status Interruptes m�glich
         reg(2) <= irqstatusp;
        END IF; 
        IF (irqsuctrap ='0') THEN      -- Nur R�cksetzen des Tranmit Interruptes m�glich
         reg(1) <= irqsuctrap;
        END IF;
        IF (irqsucrecp = '0') THEN     -- Nur R�cksetzen des Receive Interruptes m�glich
         reg(0) <= irqsucrecp;
        END IF;
      END IF;
    END IF;
  END PROCESS;
END;
