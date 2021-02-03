-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell  
--                                     Diplomarbeit 
-------------------------------------------------------------------------------
--                            Datei: faultfsm.vhd
--                     Beschreibung: Fehlerzustandsautomat
-------------------------------------------------------------------------------
-- Resets umgedreht auf active low
ENTITY faultfsm1 IS
  PORT (
    clock        : IN  bit;
    reset        : IN  bit;
    rec_lt96     : IN  bit;
    rec_ge96     : IN  bit;
    rec_ge128    : IN  bit;
    tec_lt96     : IN  bit;
    tec_ge96     : IN  bit;
    tec_ge128    : IN  bit;
    tec_ge256    : IN  bit;
    erb_eq128    : IN  bit;
    resetcount   : OUT bit;
    erroractive  : OUT bit;
    errorpassive : OUT bit;
    busoff       : OUT bit;
    warnsig      : OUT bit;
    irqsig       : OUT bit);
END faultfsm1;

ARCHITECTURE behv OF faultfsm1 IS
  TYPE STATE_TYPE IS (erroractiv, errorpassiv, busof, resetstate, warning);
  SIGNAL CURRENT_STATE, NEXT_STATE : STATE_TYPE;
  ATTRIBUTE STATE_VECTOR           : string;
  ATTRIBUTE STATE_VECTOR OF behv   : ARCHITECTURE IS "CURRENT_STATE";
BEGIN
  
  
  irqsig <= '0' when CURRENT_STATE = NEXT_STATE else '1';

  
  COMBIN: PROCESS (Current_State, rec_lt96, rec_ge96, rec_ge128, tec_lt96,
                   tec_ge96, tec_ge128, tec_ge256, erb_eq128)
-------------------------------------------------------------------------------
-- Erroractive (<96)
  BEGIN
    CASE Current_State IS
      WHEN erroractiv  =>
        erroractive  <= '1'; 
        errorpassive <= '0';
        busoff       <= '0';
        warnsig      <= '0';
        resetcount   <= '1';
        IF (rec_ge96='1' OR tec_ge96='1') THEN
          NEXT_STATE <= warning;
        ELSE
          NEXT_STATE <= erroractiv;
        END IF;
-------------------------------------------------------------------------------
-- Warning (96 < C < 128)
      WHEN warning     =>
        erroractive  <= '1';
        errorpassive <= '0';
        busoff       <= '0';
        warnsig      <= '1';
        resetcount   <= '1';
        IF (rec_ge128='1' OR tec_ge128='1') THEN  
          NEXT_STATE <= errorpassiv;
        ELSIF (rec_lt96='1' AND tec_lt96='1') THEN  
          NEXT_STATE <= erroractiv;
        ELSE
          NEXT_STATE <= warning;
        END IF;
-------------------------------------------------------------------------------
-- Errorpassive (>128)
      WHEN errorpassiv =>
        erroractive  <= '0';
        errorpassive <= '1';
        busoff       <= '0';
        warnsig      <= '0';
        resetcount   <= '1';
        IF (tec_ge256='1') THEN  
          NEXT_STATE <= busof;
        ELSIF (tec_ge128='0' AND rec_ge128='0') THEN  
          NEXT_STATE <= erroractiv;
        ELSE
          NEXT_STATE <= errorpassiv;
        END IF;
-------------------------------------------------------------------------------
-- Busoff =256
      WHEN busof       =>
        erroractive  <= '0';
        errorpassive <= '0';
        busoff       <= '1';
        warnsig      <= '0';
        resetcount   <= '1';
        IF (erb_eq128 = '1') THEN  
          NEXT_STATE <= resetstate;
        ELSE
          NEXT_STATE <= busof;
        END IF;
-------------------------------------------------------------------------------
-- RESET, alles von vorne
      WHEN resetstate  =>
        erroractive  <= '1';
        errorpassive <= '0';
        busoff       <= '0';
        warnsig      <= '0';
        resetcount   <= '0';
        NEXT_STATE   <= erroractiv;
    END CASE;
  END PROCESS;
-------------------------------------------------------------------------------
  SYNCH : PROCESS(CLOCK, RESET)
  BEGIN
    IF (CLOCK'event AND CLOCK = '1') THEN
      IF (RESET = '0') THEN               -- define an asynchronous reset
        CURRENT_STATE <= erroractiv;      -- define the reset state
      ELSE
        CURRENT_STATE <= NEXT_STATE;
      END if;              
    END IF;
  END PROCESS;
END;
