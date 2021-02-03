-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                           
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- LLC- FSM
-- neu: Promiscuous Mode: Vergleich skippen und ID ins rarbit Register
-- schreiben.
-------------------------------------------------------------------------------
ENTITY llc_fsm1 IS
  PORT(clock      : IN  bit;
       reset      : IN  bit;
       initreqr   : IN  bit;  -- CPU signalises the reset / initialisation of the CAN Controller
       traregbit  : IN  bit;  -- bit indicating data for transmission 
       sucfrecvc  : IN  bit;  -- mac unit indicates the succesful reception of a message
       sucftranc  : IN  bit;  -- mac unit indicates the succesful transmission of a message
       sucfrecvr  : IN  bit;            -- general register bit
       sucftranr  : IN  bit;            -- general register bit
       equal      : IN  bit;  -- abhängig von extended, empfangene und 
                              --gespeicherte id gleich
--       promiscous : IN  bit;            -- Promiscous MOde (aus rec-ctrl. reg.)
       activtreg  : OUT bit;  -- enables writing to the transmission register
       activrreg  : OUT bit;  -- enables writing to the reception register
       activgreg  : OUT bit;  -- enables writing to the general register
       ldrecid    : OUT bit;            -- rec_id ins rec_arbitreg laden
       sucftrano  : OUT bit;  -- sets the suctran bit in the general register
       sucfrecvo  : OUT bit;  -- sets the sucrecv bit in the general register
       overflowo  : OUT bit;  -- sets the overflow bit in the reception register
       trans      : OUT bit;  -- signalises the wish of the CPU to send a message
       load       : OUT bit;  -- enables loading of the shift register
       actvtsft   : OUT bit;            -- activates the shift register
       actvtcap   : OUT bit;            -- activates the encapsulation entity 
       resettra   : OUT bit;            -- resets the transmission entities
       resetall   : OUT bit);           -- full can reset
END;

ARCHITECTURE behv OF llc_fsm1 IS
  SIGNAL sctrrcin    : bit_vector(1 DOWNTO 0);
  SIGNAL activrreg_i : bit;
  TYPE STATE_TYPE IS (waitoact, tradrvdat, traruncap, tralodsft, trawtosuc, trasetvall, trareset,
                      trasetvalh, recwrtmesll, recwrtmeslh, recwrtmeshl, recwrtmeshh, resetste);
  SIGNAL CURRENT_STATE, NEXT_STATE : STATE_TYPE;
  --The next two lines are synopsys state machine attributes
  --see chapter 4, section on state vector attributes
  ATTRIBUTE STATE_VECTOR           : string;
  ATTRIBUTE STATE_VECTOR OF behv   : ARCHITECTURE IS "CURRENT_STATE";
BEGIN
  sctrrcin  <= sucftranr & sucfrecvr;   --recindicr;
  ldrecid   <=  activrreg_i; --promiscous AND  
  activrreg <=  activrreg_i;
  combin : PROCESS(CURRENT_STATE, traregbit, sucfrecvc, sucftranc, sucfrecvr, sucftranr,
                   sctrrcin, initreqr, equal) -- promiscous,
  BEGIN
    activtreg   <= '0';
    activrreg_i <= '0';
    activgreg   <= '0';
    sucftrano   <= '0';
    sucfrecvo   <= '0';
    trans       <= '0';
    load        <= '0';
    actvtsft    <= '0';
    actvtcap    <= '0';
    overflowo   <= '0';
    resettra    <= '1';
    resetall    <= '1';
    
    CASE CURRENT_STATE IS
-------------------------------------------------------------------------------
-- Warten auf Aktion (Sendeaufforderung, Empfang)
      WHEN waitoact =>
        activtreg   <= '0';
        activrreg_i <= '0';
        activgreg   <= '0';
        sucftrano   <= '0';
        sucfrecvo   <= '0';
        trans       <= '0';
        load        <= '0';
        actvtsft    <= '0';
        actvtcap    <= '0';
        overflowo   <= '0';
        resettra    <= '1';
        resetall    <= '1';
        IF initreqr = '1' THEN
          NEXT_STATE <= resetste;
        ELSIF (initreqr = '0' AND traregbit = '1' AND sucfrecvc = '0') THEN
          NEXT_STATE <= tradrvdat;
        ELSIF (sctrrcin = "00" AND sucfrecvc='1' AND initreqr='0' AND equal='1') THEN  -- promiscous='1' 
          NEXT_STATE <= recwrtmesll;
        ELSIF (sctrrcin = "01" AND sucfrecvc='1' AND initreqr='0' AND equal='1') THEN  -- promiscous='1' 
          NEXT_STATE <= recwrtmeslh;
        ELSIF (sctrrcin = "10" AND sucfrecvc='1' AND initreqr='0' AND equal='1') THEN  -- promiscous='1' 
          NEXT_STATE <= recwrtmeshl;
        ELSIF (sctrrcin = "11" AND sucfrecvc='1' AND initreqr='0' AND equal='1') THEN  -- promiscous='1' 
          NEXT_STATE <= recwrtmeshh;
        ELSE
          NEXT_STATE <= waitoact;
        END IF;
-------------------------------------------------------------------------------
-- Alles zurücksetzen
      WHEN resetste =>
        activtreg   <= '0';
        activrreg_i <= '0';
        activgreg   <= '1';
        sucftrano   <= '0';
        sucfrecvo   <= '0';
        trans       <= '0';
        load        <= '0';
        actvtsft    <= '0';
        actvtcap    <= '0';
        overflowo   <= '0';
        --recindico   <= '0';
        resettra    <= '1';
        resetall    <= '0';
        NEXT_STATE  <= waitoact;
-------------------------------------------------------------------------------
-- 1. Schritt Sendeaufforderung, MAC resetten
      WHEN trareset =>
        activtreg   <= '0';
        activrreg_i <= '0';
        activgreg   <= '0';
        sucftrano   <= '0';
        sucfrecvo   <= '0';
        trans       <= '0';
        load        <= '0';
        actvtsft    <= '0';
        actvtcap    <= '0';
        overflowo   <= '0';
        resettra    <= '0';
        resetall    <= '1';
        IF initreqr = '1' THEN
          NEXT_STATE <= resetste;
        ELSE
          NEXT_STATE <= tradrvdat;
        END IF;
-------------------------------------------------------------------------------
-- 2. Schritt: Reset weg
      WHEN tradrvdat =>
        activtreg   <= '0';
        activrreg_i <= '0';
        activgreg   <= '0';
        sucftrano   <= '0';
        sucfrecvo   <= '0';
        trans       <= '0';
        load        <= '0';
        actvtsft    <= '0';
        actvtcap    <= '0';
        overflowo   <= '0';
        resettra    <= '1';
        resetall    <= '1';
        IF initreqr = '1' THEN
          NEXT_STATE <= resetste;
        ELSE
          NEXT_STATE <= traruncap;
        END IF;
-------------------------------------------------------------------------------
-- 3. Schritt, Register laden und Encapsulation
      WHEN traruncap =>
        activtreg   <= '0';
        activrreg_i <= '0';
        activgreg   <= '0';
        sucftrano   <= '0';
        sucfrecvo   <= '0';
        trans       <= '0';
        load        <= '1';
        actvtsft    <= '0';
        actvtcap    <= '1';
        overflowo   <= '0';
        resettra    <= '1';
        resetall    <= '1';
        IF initreqr = '1' THEN
          NEXT_STATE <= resetste;
        ELSE
          NEXT_STATE <= tralodsft;
        END IF;
-------------------------------------------------------------------------------
-- 4. Schritt, trans setzen, dann gehts los
      WHEN tralodsft =>
        activtreg   <= '0';
        activrreg_i <= '0';
        activgreg   <= '0';
        sucftrano   <= '0';
        sucfrecvo   <= '0';
        trans       <= '0';
        load        <= '1';
        actvtsft    <= '1';
        actvtcap    <= '0';
        overflowo   <= '0';
        resettra    <= '1';
        resetall    <= '1';
        IF initreqr = '1' THEN
          NEXT_STATE <= resetste;
        ELSE
          NEXT_STATE <= trawtosuc;
        END IF;
-------------------------------------------------------------------------------
-- warten auf geglückten Versand
      WHEN trawtosuc =>
        activtreg   <= '0';
        activrreg_i <= '0';
        activgreg   <= '0';
        sucftrano   <= '0';
        sucfrecvo   <= '0';
        trans       <= '1';
        load        <= '0';
        actvtsft    <= '0';
        actvtcap    <= '0';
        overflowo   <= '0';
        resettra    <= '1';
        resetall    <= '1';
        IF initreqr = '1' THEN
          NEXT_STATE <= resetste;
        ELSIF (initreqr = '0' AND sucftranc = '1' AND sucfrecvc = '0' AND sucfrecvr = '0') THEN
          NEXT_STATE <= trasetvall;
        ELSIF (initreqr = '0' AND sucftranc = '1' AND sucfrecvc = '0' AND sucfrecvr = '1') THEN
          NEXT_STATE <= trasetvalh;
        ELSIF (sctrrcin = "00" AND sucfrecvc='1' AND initreqr='0' AND equal='1') THEN  -- promiscous='1' 
          NEXT_STATE <= recwrtmesll;
        ELSIF (sctrrcin = "01" AND sucfrecvc='1' AND initreqr='0' AND equal='1') THEN  -- promiscous='1' 
          NEXT_STATE <= recwrtmeshl;
        ELSIF (sctrrcin = "10" AND sucfrecvc='1' AND initreqr='0' AND equal='1') THEN  -- promiscous='1' 
          NEXT_STATE <= recwrtmeshl;
        ELSIF (sctrrcin = "11" AND sucfrecvc='1' AND initreqr='0' AND equal='1') THEN  -- promiscous='1'  
          NEXT_STATE <= recwrtmeshh;
        ELSE
          NEXT_STATE <= trawtosuc;
        END IF;
-------------------------------------------------------------------------------
-- Succesful transmit Bit im Genreg setzen
      WHEN trasetvall =>
        activtreg   <= '1';
        activrreg_i <= '0';
        activgreg   <= '1';
        sucftrano   <= '1';
        sucfrecvo   <= '0';
        trans       <= '0';
        load        <= '0';
        actvtsft    <= '0';
        actvtcap    <= '0';
        overflowo   <= '0';
        resettra    <= '1';
        resetall    <= '1';
        IF initreqr = '1' THEN
          NEXT_STATE <= resetste;
        ELSE
          NEXT_STATE <= waitoact;
        END IF;
-------------------------------------------------------------------------------        
-- Vor dem Versenden noch was empfangen: Succsessfull trans und received im
-- Genreg register setzen
      WHEN trasetvalh =>
        activtreg   <= '1';
        activrreg_i <= '0';
        activgreg   <= '1';
        sucftrano   <= '1';
        sucfrecvo   <= '1';
        trans       <= '0';
        load        <= '0';
        actvtsft    <= '0';
        actvtcap    <= '0';
        overflowo   <= '0';
        --recindico   <= '0';
        resettra    <= '1';
        resetall    <= '1';
        IF initreqr = '1' THEN
          NEXT_STATE <= resetste;
        ELSE
          NEXT_STATE <= waitoact;
        END IF;
-------------------------------------------------------------------------------
-- Nur empfangen: Sucrec. Bit setzen
      WHEN recwrtmesll =>
        activtreg   <= '0';
        activrreg_i <= '1';
        activgreg   <= '1';
        sucftrano   <= '0';
        sucfrecvo   <= '1';
        trans       <= '0';
        load        <= '0';
        actvtsft    <= '0';
        actvtcap    <= '0';
        resettra    <= '1';
        overflowo   <= '0';
        resetall    <= '1';
        IF initreqr = '1' THEN
          NEXT_STATE <= resetste;
        ELSIF sucfrecvc = '0' THEN
          NEXT_STATE <= waitoact;
        ELSE
          NEXT_STATE <= recwrtmesll;
        END IF;
-------------------------------------------------------------------------------        
-- Zum 2. Mal empfangen: Sucrec. Bit und Overflow BIt setzen
      WHEN recwrtmeslh =>
        activtreg   <= '0';
        activrreg_i <= '1';
        activgreg   <= '1';
        sucftrano   <= '0';
        sucfrecvo   <= '1';
        trans       <= '0';
        load        <= '0';
        actvtsft    <= '0';
        actvtcap    <= '0';
        resettra    <= '1';
        overflowo   <= '1';
        resetall    <= '1';
        IF initreqr = '1' THEN
          NEXT_STATE <= resetste;
        ELSIF sucfrecvc = '0' THEN
          NEXT_STATE <= waitoact;
        ELSE
          NEXT_STATE <= recwrtmeslh;
        END IF;
-------------------------------------------------------------------------------        
-- Erfolgreich Empfangen und versendet, Bits setzen
      WHEN recwrtmeshl =>
        activtreg   <= '0';
        activrreg_i <= '1';
        activgreg   <= '1';
        sucftrano   <= '1';
        sucfrecvo   <= '1';
        trans       <= '0';
        load        <= '0';
        actvtsft    <= '0';
        actvtcap    <= '0';
        resettra    <= '1';
        overflowo   <= '0';
        resetall    <= '1';
        IF initreqr = '1' THEN
          NEXT_STATE <= resetste;
        ELSIF sucfrecvc = '0' THEN
          NEXT_STATE <= waitoact;
        ELSE
          NEXT_STATE <= recwrtmeshl;
        END IF;
-------------------------------------------------------------------------------
-- Empfangen zum 2. Mal und versendet: overflow, sucsent, sucrecv Bits setzen
      WHEN recwrtmeshh =>
        activtreg   <= '0';
        activrreg_i <= '1';
        activgreg   <= '1';
        sucftrano   <= '1';
        sucfrecvo   <= '1';
        trans       <= '0';
        load        <= '0';
        actvtsft    <= '0';
        actvtcap    <= '0';
        resettra    <= '1';
        overflowo   <= '1';
        resetall    <= '1';
        IF initreqr = '1' THEN
          NEXT_STATE <= resetste;
        ELSIF sucfrecvc = '0' THEN
          NEXT_STATE <= waitoact;
        ELSE
          NEXT_STATE <= recwrtmeshh;
        END IF;
 --     WHEN OTHERS =>
 --       next_state <= waitoact;
    END CASE;
  END PROCESS;
-------------------------------------------------------------------------------
-- Sequentielles:
-------------------------------------------------------------------------------
  SYNCH : PROCESS(CLOCK)
  BEGIN
    IF (CLOCK'event AND CLOCK = '1') THEN
      IF (RESET = '0') THEN             -- define an synchronous reset
        CURRENT_STATE <= waitoact;      -- define the reset state
      ELSE
        CURRENT_STATE <= NEXT_STATE;
      END IF;
    END IF;
  END PROCESS;
END behv;
