-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                           
-------------------------------------------------------------------------------
-- LLC Logic Link Control
-- neu: Strukturunterteilung, id Vergleich in equal_id
-- neu Promiscuous Mode, FSM skippt Akzeptanzprüfung
-------------------------------------------------------------------------------
-- Struktur
-- equal_id_i: equal_id: Vergleicht ID empfangen mit ID aus REgister (IOCPU)
-- llc_fsm_1: llc_fsm: Zustandsmaschine Senden/Empfangen
ENTITY llc1 IS
  PORT(clock      : IN  bit;
       reset      : IN  bit;
       initreqr   : IN  bit;  -- CPU signalises the reset /
                              -- initialisation of the CAN Controller
       traregbit  : IN  bit;  -- bit indicating data for transmission 
       sucfrecvc  : IN  bit;  -- mac unit indicates the succesful
                              -- reception of a message
       sucftranc  : IN  bit;  -- mac unit indicates the succesful
                              -- transmission of a message
       sucfrecvr  : IN  bit;  -- general register bit
       sucftranr  : IN  bit;  -- general register bit
       extended   : IN  bit;  -- information of the decaps e
       accmaskreg : IN  bit_vector (28 DOWNTO 0);  -- IOCPU
       idreg      : IN  bit_vector (28 DOWNTO 0);  -- IOCPU
       idrec      : IN  bit_vector (28 DOWNTO 0);  -- MAC
 --      promiscous : IN  bit;  -- Promiscuous MOde (aus rec-ctrl. reg.)
       activtreg  : OUT bit;  -- enables writing to the transmission register
       activrreg  : OUT bit;  -- enables writing to the reception register
       activgreg  : OUT bit;  -- enables writing to the general register
       ldrecid    : OUT bit;  -- rec_id ins rec_arbitreg laden
       sucftrano  : OUT bit;  -- sets the suctran bit in the general register
       sucfrecvo  : OUT bit;  -- sets the sucrecv bit in the general register
       overflowo  : OUT bit;  -- sets the overflow bit in the reception register
       trans      : OUT bit;  -- signalises the wish of the CPU to send a message
       load       : OUT bit;  -- enables loading of the shift register
       actvtsft   : OUT bit;  -- activates the shift register
       actvtcap   : OUT bit;  -- activates the encapsulation entity 
       resettra   : OUT bit;  -- resets the transmission entities
       resetall   : OUT bit); -- full can reset
END llc1;

ARCHITECTURE behv OF llc1 IS

  COMPONENT llc_fsm1
    PORT (
      clock      : IN  bit;
      reset      : IN  bit;
      initreqr   : IN  bit;             -- IOCPU, reset in generalreg
      traregbit  : IN  bit;             -- IOCPU, transmesconreg: Transmission REquest
      sucfrecvc  : IN  bit;             -- MACFSM, decrec
      sucftranc  : IN  bit;             -- MACFSM, dectra
      sucfrecvr  : IN  bit;             -- IOCPU, generalregister
      sucftranr  : IN  bit;             -- IOCPU, generalregister
      equal      : IN  bit;             -- equal_id
 --     promiscous : IN  bit;             -- IOCPU, recmesconreg
      activtreg  : OUT bit;             -- IOCPU, transmesconreg, schreibaktiv
      activrreg  : OUT bit;             -- IOCPU, recmesconreg, schreibaktiv
      activgreg  : OUT bit;             -- IOCPU, generalregister, schreibaktiv
      ldrecid    : OUT bit;             -- IOCPU, rarbit, ID laden (Prom. Mode)
      sucftrano  : OUT bit;             -- IOCPU, generalreg, Bit 11
      sucfrecvo  : OUT bit;             -- IOCPU, generalreg, Bit 10
      overflowo  : OUT bit;             -- IOCPU, recmesctrlreg, Bit 15
      trans      : OUT bit;             -- MACFSM
      load       : OUT bit;             -- MAC, transshift
      actvtsft   : OUT bit;             -- MAC, transshift
      actvtcap   : OUT bit;             -- MAC, encapsulation
      resettra   : OUT bit;             -- MAC, reset transmit
      resetall   : OUT bit);            -- MAC reset
  END COMPONENT;

  COMPONENT equal_id1
    PORT (
      extended   : IN  bit;             -- Vergleich abhängig
      idregister : IN  bit_vector(28 DOWNTO 0);  -- aus Register
      idreceived : IN  bit_vector(28 DOWNTO 0);  -- grad empfangegn
      accmask    : IN  bit_vector(28 DOWNTO 0);  -- AcceptionmaskRegister
      equal      : OUT bit);            -- gleich = 1
  END COMPONENT;

  SIGNAL equal_i : bit;


  
BEGIN  -- behv
  llc_fsm_1: llc_fsm1
    PORT MAP (
      clock      => clock,
      reset      => reset,
      initreqr   => initreqr,
      traregbit  => traregbit,
      sucfrecvc  => sucfrecvc,
      sucftranc  => sucftranc,
      sucfrecvr  => sucfrecvr,
      sucftranr  => sucftranr,
      equal      => equal_i,
--      promiscous => promiscous,
      activtreg  => activtreg,
      activrreg  => activrreg,
      activgreg  => activgreg,
      ldrecid    => ldrecid,
      sucftrano  => sucftrano,
      sucfrecvo  => sucfrecvo,
      overflowo  => overflowo,
      trans      => trans,
      load       => load,
      actvtsft   => actvtsft,
      actvtcap   => actvtcap,
      resettra   => resettra,
      resetall   => resetall);

  equal_id_1: equal_id1
    PORT MAP (
      extended   => extended,
      idregister => idreg,
      idreceived => idrec,
      accmask    => accmaskreg,
      equal      => equal_i);

END behv;
