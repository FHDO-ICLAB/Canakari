-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                           
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--                                    Interrupt Unit
-- Löst IRQ bei successful transmit, successful receive und bei Statuswechseln aus                                     
-- Zustandsautomat mit fuenf Zuständen.
-------------------------------------------------------------------------------
ENTITY interruptunit1 IS
  PORT(clock       : IN  bit;
       reset       : IN  bit;
       ienable     : IN  bit_vector(2 DOWNTO 0);    -- Interrupt Enable im interruptregister von iocpu
       irqstd      : IN  bit_vector(2 DOWNTO 0);    -- Interruptzustand im interruptregister von iocpu
       irqsig      : IN  bit;                       -- von fce-fsm Zustandswechsel (Currentstate=Nextstate)
       sucfrec     : IN  bit;                       -- successful reception controller von llc
       sucftra     : IN  bit;                       -- successful transmission controller von llc    
       activintreg : OUT bit;                       -- aktiviert Interruptregister 
       irqstatus   : OUT bit;                       -- Neue Irqwerte für Interruptregister
       irqsuctra   : OUT bit;
       irqsucrec   : OUT bit;
       irq         : OUT bit);                      -- Interrupt Request Leitung die nach aussen gefuehrt wird
END;


ARCHITECTURE behv OF interruptunit1 IS

  
  TYPE STATE_TYPE IS (waitoact, recind, traind, statind);
  SIGNAL CURRENT_STATE, NEXT_STATE : STATE_TYPE;

  ATTRIBUTE STATE_VECTOR           : string;
  ATTRIBUTE STATE_VECTOR OF behv   : ARCHITECTURE IS "CURRENT_STATE";

BEGIN

irq       <= irqstd(0) or irqstd(1) or irqstd (2);         -- Wenn eines der Bits im Interruptregister 1 ist dann IRQ      

 fsm : PROCESS(CURRENT_STATE, irqsig, sucfrec, sucftra, irqstd, ienable) 
   BEGIN

    CASE CURRENT_STATE IS
-------------------------------------------------------------------------------
      WHEN waitoact =>
        
        activintreg   <= '0';
        irqstatus     <= '0';
        irqsuctra     <= '0';
        irqsucrec     <= '0';
        IF    (sucfrec = '1' and irqstd(0) = '0' and ienable(0) = '1') THEN  -- Falls eine der Interupt-Indications 
          NEXT_STATE <= recind;       
        ELSIF (sucftra = '1' and irqstd(1) = '0' and ienable(1) = '1') THEN  -- von der llc oder fce vorliegt und noch 
          NEXT_STATE <= traind;       
        ELSIF (irqsig =  '1' and irqstd(2) = '0' and ienable(2) = '1') THEN  -- nicht im Interruptregister vermerkt ist         
          NEXT_STATE <= statind;                                           
        ELSE  
          NEXT_STATE <= waitoact;                                            -- ansonsten bleibe in waitoact
        END IF;
-------------------------------------------------------------------------------
      WHEN recind =>
        activintreg   <= '1';
        irqstatus     <= '0';
        irqsuctra     <= '0';
        irqsucrec     <= '1';
        IF (sucftra = '1' and irqstd(1) = '0' and ienable(1) = '1') THEN     -- Übergang nach Transmit Indication
          NEXT_STATE <= traind;       
        ELSIF (irqsig =  '1' and irqstd(2) = '0' and ienable(2) = '1') THEN  -- Übergang nach Status Indication         
          NEXT_STATE <= statind;                                             
        ELSE  
          NEXT_STATE <= waitoact;                                            -- ansonsten nach waitoact zurückkehren
        END IF;
   
      WHEN traind =>
        activintreg   <= '1';
        irqstatus     <= '0';
        irqsuctra     <= '1';
        irqsucrec     <= '0';
        IF (sucfrec = '1' and irqstd(0) = '0' and ienable(0) = '1') THEN      -- Übergang nach Receive Indication 
          NEXT_STATE <= recind;       
        ELSIF (irqsig =  '1' and irqstd(2) = '0' and ienable(2) = '1') THEN   -- Übergang nach Status Indication          
          NEXT_STATE <= statind;                                              
        ELSE  
          NEXT_STATE <= waitoact;                                             -- ansonsten nach waitoact zurückkehren
        END IF;
   
      WHEN statind =>
        activintreg   <= '1';
        irqstatus     <= '1';
        irqsuctra     <= '0';
        irqsucrec     <= '0';
        IF (sucfrec = '1' and irqstd(0) = '0' and ienable(0) = '1') THEN      -- Übergang nach Receive Indication 
          NEXT_STATE <= recind;       
        ELSIF (sucftra =  '1' and irqstd(1) = '0' and ienable(1) = '1') THEN  -- Übergang nach Transmit Indication          
          NEXT_STATE <= traind;                                              
        ELSE  
          NEXT_STATE <= waitoact;                                             -- ansonsten nach waitoact zurückkehren
        END IF;

-------------------------------------------------------------------------------        
    END CASE;
  END PROCESS;        
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Sequentielles:
-------------------------------------------------------------------------------
  SYNCH : PROCESS(CLOCK)
  BEGIN
    IF (CLOCK'event AND CLOCK = '1') THEN
      IF (RESET = '0') THEN                         
        CURRENT_STATE <= waitoact;      
      ELSE
        CURRENT_STATE <= NEXT_STATE;
      END IF;
    END IF;
  END PROCESS;
END behv;

