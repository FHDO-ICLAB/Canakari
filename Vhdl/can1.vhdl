

----------------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell
--                                     Diplomarbeit 
-------------------------------------------------------------------------------
--                            Datei: can.vhd
--                     Beschreibung: oberste Hierarchiestufe
-------------------------------------------------------------------------------
-- fast nur Struktur, ein AND für resetsignal
-- prescaler: prescale: Entity, Vorteiler Systemtakt
-- IOControl: iocpu: Configuration, CPU I/O Logik, Mux, Demux
-- FaultConfinement: fce: Configuration, Fehler Zähler, FSM
-- TimeControl: bittiming: Configuration, sendpoint  und smplpoint erzeugen
-- LogicalLinkControl: llc: Configuration,MAC <-> IOCPU, Akzeptanzfilterung
-- MediumAccessControl: mac: Configuration
-- reset_generator: resetgen: Resetsig für synchrone Registerresets
-- DW 2005.06.21 Prescale Enable eingefügt

-- | Leduc | 12.02.2020 | Added Changes done in Verilog Triplication Files
  
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;
LIBRARY synopsys;
USE synopsys.attributes.ALL;
-------------------------------------------------------------------------------
ENTITY can1 IS
  GENERIC (
      system_id : bit_vector(15 DOWNTO 0) := (x"CA05") );    -- an ID to probe for existence
                                                                   -- of HW
  PORT(clock : IN bit;
       reset             : IN  bit;
       address           : IN  bit_vector(4 DOWNTO 0);
       readdata          : OUT std_logic_vector(15 DOWNTO 0);  -- Avalon lesedaten
       writedata         : IN  std_logic_vector (15 DOWNTO 0);
       cs                : IN  std_logic;  -- Avalon Chip Select
       read_n            : IN  std_logic;  -- Avalon read enable active low
       write_n           : IN  std_logic;  -- Avalon write enable active low
       irq               : OUT bit;
       irqstatus         : OUT bit;
       irqsuctra         : OUT bit;
       irqsucrec         : OUT bit;
       rx                : IN  bit;     -- CAN-BUS
       tx                : OUT bit;     -- CAN-BUS
       statedeb          : OUT std_logic_vector(7 DOWNTO 0);
       Prescale_EN_debug : OUT bit;     -- DW 2005.06.25 Debug Prescale
       bitst             : OUT std_logic_vector(6 DOWNTO 0) );
  END can1;
-------------------------------------------------------------------------------
ARCHITECTURE behv OF can1 IS
  COMPONENT resetgen1                                      -- reset für synchrone
    PORT(reset      : IN  bit;
         sync_reset : OUT bit;
         clock      : IN  bit);
  END COMPONENT;
  
  COMPONENT mac1
    PORT(clock       : IN  bit;         -- aussen
         Prescale_EN : IN  bit;         -- DW 2005.06.21 Prescale Enable eingefügt                  
         reset       : IN  bit;         -- resetgen
         sendpoint   : IN  bit;         -- bittiming
         smplpoint   : IN  bit;         --  "
         inbit       : IN  bit;         --  "
         trans       : IN  bit;         -- LLC
         erroractiv  : IN  bit;         -- FCE 
         errorpassiv : IN  bit;         -- FCE
         busof       : IN  bit;         -- FCE
         load        : IN  bit;         -- LLC
         actvtsftllc : IN  bit;         -- LLC
         actvtcap    : IN  bit;         -- LLC
         resettra    : IN  bit;         -- LLC
         identifierr : IN  bit_vector( 28 DOWNTO 0); -- IOCPU tarbit1,2
         data1r      : IN  bit_vector( 7 DOWNTO 0);  -- IOCPU tdata12
         data2r      : IN  bit_vector( 7 DOWNTO 0);  --  ...
         data3r      : IN  bit_vector( 7 DOWNTO 0);  --  ...
         data4r      : IN  bit_vector( 7 DOWNTO 0);
         data5r      : IN  bit_vector( 7 DOWNTO 0);
         data6r      : IN  bit_vector( 7 DOWNTO 0);
         data7r      : IN  bit_vector( 7 DOWNTO 0);
         data8r      : IN  bit_vector( 7 DOWNTO 0);  -- IOCPU tdata78
         extendedr   : IN  bit;                      -- IOCPU transmesconreg.
         remoter     : IN  bit;                      -- IOCPU "
         datalenr    : IN  bit_vector( 3 DOWNTO 0);  --   "   "
         identifierw : OUT bit_vector( 28 DOWNTO 0); -- LLC equal_id, IOCPU rarbitx
         data1w      : OUT bit_vector( 7 DOWNTO 0);  -- IOCPU rdataxx
         data2w      : OUT bit_vector( 7 DOWNTO 0);  --   "     "
         data3w      : OUT bit_vector( 7 DOWNTO 0);  --   "     "
         data4w      : OUT bit_vector( 7 DOWNTO 0);  --   "     "
         data5w      : OUT bit_vector( 7 DOWNTO 0);  --   "     "
         data6w      : OUT bit_vector( 7 DOWNTO 0);  --   "     "
         data7w      : OUT bit_vector( 7 DOWNTO 0);  --   "     "
         data8w      : OUT bit_vector( 7 DOWNTO 0);  --   "     "
         remotew     : OUT bit;                      -- IOCPU mcontrol (recmescontrolreg)
         datalenw    : OUT bit_vector( 3 DOWNTO 0);  --   "        "          "
         inconerec   : OUT bit;         -- FCE rec
         incegtrec   : OUT bit;         -- FCE rec
         incegttra   : OUT bit;         -- FCE tec
         decrec      : OUT bit;         -- FCE rec
         dectra      : OUT bit;         -- FCE tec
         elevrecb    : OUT bit;         -- FCE erbcount
         hardsync    : OUT bit;         -- bittiming fsm
         outbit      : OUT bit;
         statedeb    : OUT std_logic_vector(7 DOWNTO 0));

  END COMPONENT;

  COMPONENT llc1
    PORT(clock      : IN  bit;
         reset      : IN  bit;
         initreqr   : IN  bit;  -- CPU signalises the reset / initialisation of the CAN Controller
         traregbit  : IN  bit;  -- bit indicating data for transmission (tramesconreg)
         sucfrecvc  : IN  bit;  -- mac unit indicates the succesful reception of a message
         sucftranc  : IN  bit;  -- mac unit indicates the succesful transmission of a message
         sucfrecvr  : IN  bit;          -- general register bit
         sucftranr  : IN  bit;          -- general register bit
         extended   : IN  bit;
         accmaskreg : IN  bit_vector (28 DOWNTO 0); 
         idreg      : IN  bit_vector (28 DOWNTO 0);  -- id Register - equal_id
         idrec      : IN  bit_vector (28 DOWNTO 0);  -- id received - equal_id
--         promiscous : IN  bit;          -- Promiscous MOde (aus rec-ctrl. reg.)
         activtreg  : OUT bit;  -- enables writing to the transmission register
         activrreg  : OUT bit;  -- enables writing to the reception register
         activgreg  : OUT bit;  -- enables writing to the general register
         ldrecid    : OUT bit;          -- rec_id ins rec_arbitreg laden
         sucftrano  : OUT bit;  -- sets the suctran bit in the general register
         sucfrecvo  : OUT bit;  -- sets the sucrecv bit in the general register
         overflowo  : OUT bit;  -- sets the overflow bit in the reception register
         trans      : OUT bit;  -- signalises the wish of the CPU to send a message
         load       : OUT bit;  -- enables loading of the shift register
         actvtsft   : OUT bit;          -- activates the shift register
         actvtcap   : OUT bit;          -- activates the encapsulation entity 
         resettra   : OUT bit;          -- resets the transmission entities
         resetall   : OUT bit);         -- full can reset
  END COMPONENT;

  COMPONENT bittiming1
    PORT (
      clock       : IN  bit;
      Prescale_EN : IN  bit;                            -- DW 2005.06.21
      reset       : IN  bit;
      hardsync    : IN  bit;
      rx          : IN  bit;
      tseg1       : IN  integer RANGE 0 TO 7;
      tseg2       : IN  integer RANGE 0 TO 7;
      sjw         : IN  integer RANGE 0 TO 7;
      sendpoint   : OUT bit;
      smplpoint   : OUT bit;
      smpledbit   : OUT bit;
      bitst       : OUT std_logic_vector(6 DOWNTO 0));
  END COMPONENT;


  COMPONENT fce1
    PORT(clock        : IN  bit;        -- aussen
         reset        : IN  bit;        -- resetgen
         inconerec    : IN  bit;        -- MACFSM
         incegtrec    : IN  bit;        -- MACFSM
         incegttra    : IN  bit;        -- MACFSM
         decrec       : IN  bit;        -- MACFSM
         dectra       : IN  bit;        -- MACFSM
         elevrecb     : IN  bit;        -- MACFSM
         erroractive  : OUT bit;        -- MACFSM, generalregister 
         errorpassive : OUT bit;        -- MACFSM, generalregister 
         busoff       : OUT bit;        -- MACFSM, generalregister 
         warnsig      : OUT bit;       -- generalregister
         irqsig       : OUT bit;
         tecfce       : out    bit_vector(7 DOWNTO 0);
         recfce       : out    bit_vector(7 DOWNTO 0));
  END COMPONENT;

  COMPONENT iocpu1
    GENERIC (
      system_id : bit_vector(15 DOWNTO 0) );    -- HW-ID
    PORT(clock        : IN    bit;
         reset        : IN    bit;
         address      : IN    bit_vector(4 DOWNTO 0);        -- aussen
         readdata     : OUT   std_logic_vector(15 DOWNTO 0); -- aussen
         writedata    : IN    std_logic_vector(15 DOWNTO 0); -- aussen
         read_n       : IN    std_logic;                     -- aussen
         write_n      : IN    std_logic;                     -- aussen
         cs           : IN    std_logic;                     -- aussen
         activgreg    : IN    bit;                           -- llc activates general register
         activtreg    : IN    bit;                           -- llc activates transmission register
         activrreg    : IN    bit;                           -- llc activates reception register
         activintreg  : IN    bit;                           -- llc activates interrupt register
         ldrecid      : IN    bit;                           -- llc activates receive id
         sucftrani    : IN    bit;                           -- llc sets the suctran bit in the gen. and tcon.  register
         sucfrecvi    : IN    bit;                           -- llc sets the sucrecv bit in the general register
         overflowo    : IN    bit;                           -- llc sets the overflow bit in the reception register
         erroractive  : IN    bit;                           -- fce
         errorpassive : IN    bit;                           -- fce
         busoff       : IN    bit;                           -- fce
         warning      : IN    bit;                           -- fce
         irqstatus    : IN    bit;                           -- irqstatusc von IU an iocpu
         irqsuctra    : IN    bit;                           -- irqsuctrac von IU an iocpu
         irqsucrec    : IN    bit;                           -- irqsuctrac von IU an iocpu
         rec_id       : IN    bit_vector(28 DOWNTO 0);       -- MAC, received id, for promiscous mode(i.e. ACC.MASK="000...000")
         rremote      : IN    bit;                           -- MAC    
         rdlc         : IN    bit_vector(3 DOWNTO 0);        -- MAC
         data1r       : IN    bit_vector(7 DOWNTO 0);        -- MAC
         data2r       : IN    bit_vector(7 DOWNTO 0);        -- MAC
         data3r       : IN    bit_vector(7 DOWNTO 0);        -- MAC
         data4r       : IN    bit_vector(7 DOWNTO 0);        -- MAC
         data5r       : IN    bit_vector(7 DOWNTO 0);        -- MAC
         data6r       : IN    bit_vector(7 DOWNTO 0);        -- MAC
         data7r       : IN    bit_vector(7 DOWNTO 0);        -- MAC
         data8r       : IN    bit_vector(7 DOWNTO 0);        -- MAC
         teccan       : IN    bit_vector(7 DOWNTO 0);
         reccan       : IN    bit_vector(7 DOWNTO 0);
         sjw          : OUT   integer RANGE 0 TO 7;          -- generalregister
         tseg1        : OUT   integer RANGE 0 TO 7;          -- generalregister
         tseg2        : OUT   integer RANGE 0 TO 7;          -- generalregister
         sucfrecvo    : OUT   bit;                           -- genregr informs llc sucessfull reception bit
         sucftrano    : OUT   bit; 							     -- genregr informs llc succesfull transmission bit
         initreqr     : OUT   bit;  							     -- genregr informs llc reset/init bit;
         traregbit    : OUT   bit;                           -- genregr informs llc transmission indic bit
         accmask      : OUT   bit_vector(28 DOWNTO 0);       -- Acception Mask Register
         ridentifier  : OUT   bit_vector(28 DOWNTO 0);       -- llc, equal_id
         rextended    : OUT   bit;                           -- llc, equal_id
         ienable      : OUT   bit_vector(2 DOWNTO 0);        -- Interruptenablevector for IU
         irqstd       : OUT   bit_vector(2 DOWNTO 0);        -- Interruptstdvector for IU
         tidentifier  : OUT   bit_vector(28 DOWNTO 0);       -- MAC, encapsulation 
         data1t       : OUT   bit_vector( 7 DOWNTO 0);       -- MAC, transshift
         data2t       : OUT   bit_vector( 7 DOWNTO 0);       -- MAC, transshift
         data3t       : OUT   bit_vector( 7 DOWNTO 0);       -- MAC, transshift
         data4t       : OUT   bit_vector( 7 DOWNTO 0);       -- MAC, transshift
         data5t       : OUT   bit_vector( 7 DOWNTO 0);       -- MAC, transshift
         data6t       : OUT   bit_vector( 7 DOWNTO 0);       -- MAC, transshift
         data7t       : OUT   bit_vector( 7 DOWNTO 0);       -- MAC, transshift
         data8t       : OUT   bit_vector( 7 DOWNTO 0);       -- MAC, transshift
         textended    : OUT   bit;                           -- MAC, encapsulation
         tremote      : OUT   bit;                           -- MAC, encapsulation
         tdlc         : OUT   bit_vector(3 DOWNTO 0);        -- MAC, encapsulation
         prescale_out : OUT   bit_vector(7 DOWNTO 0);		 -- prescaler
         onoffn       : out   bit);   						 -- physical layer enable   
  END COMPONENT;
  
  COMPONENT prescale1
    PORT (
      clock       : IN  bit;
      reset       : IN  bit;
      high        : IN  bit_vector(3 DOWNTO 0);
      low         : IN  bit_vector(3 DOWNTO 0);
      Prescale_EN : OUT bit);                                 -- DW 2005.06.21
  END COMPONENT;

 
  COMPONENT interruptunit1 
    PORT(clock       : IN  bit;
         reset       : IN  bit;
         ienable     : IN  bit_vector(2 DOWNTO 0);    -- Interrupt Enable von iocpu
         irqstd      : IN  bit_vector(2 DOWNTO 0);    -- Interruptzustand im interruptregister von iocpu
         irqsig      : IN  bit;
         sucfrec     : IN  bit;                       -- successful reception controller
         sucftra     : IN  bit;                       -- successful transmission controller    
         activintreg : OUT bit;
         irqstatus   : OUT bit;
         irqsuctra   : OUT bit;
         irqsucrec   : OUT bit;
         irq         : OUT bit); 
  END COMPONENT;




-------------------------------------------------------------------------------
-- mac signals
  SIGNAL sendpoint   : bit;
  SIGNAL smplpoint   : bit;
  SIGNAL trans       : bit;
  SIGNAL erroractiv  : bit;
  SIGNAL errorpassiv : bit;
  SIGNAL busof       : bit;
  SIGNAL load        : bit;
  SIGNAL actvtsftllc : bit;
  SIGNAL actvtcap    : bit;
  SIGNAL resettra    : bit;
  SIGNAL accmaskreg_i :  bit_vector (28 DOWNTO 0);
  SIGNAL identifierr : bit_vector( 28 DOWNTO 0);
  SIGNAL data1r      : bit_vector( 7 DOWNTO 0);
  SIGNAL data2r      : bit_vector( 7 DOWNTO 0);
  SIGNAL data3r      : bit_vector( 7 DOWNTO 0);
  SIGNAL data4r      : bit_vector( 7 DOWNTO 0);
  SIGNAL data5r      : bit_vector( 7 DOWNTO 0);
  SIGNAL data6r      : bit_vector( 7 DOWNTO 0);
  SIGNAL data7r      : bit_vector( 7 DOWNTO 0);
  SIGNAL data8r      : bit_vector( 7 DOWNTO 0);
  SIGNAL extendedr   : bit;
  SIGNAL remoter     : bit;
  SIGNAL datalenr    : bit_vector( 3 DOWNTO 0);
  SIGNAL identifierw : bit_vector( 28 DOWNTO 0);
  SIGNAL data1w      : bit_vector( 7 DOWNTO 0);
  SIGNAL data2w      : bit_vector( 7 DOWNTO 0);
  SIGNAL data3w      : bit_vector( 7 DOWNTO 0);
  SIGNAL data4w      : bit_vector( 7 DOWNTO 0);
  SIGNAL data5w      : bit_vector( 7 DOWNTO 0);
  SIGNAL data6w      : bit_vector( 7 DOWNTO 0);
  SIGNAL data7w      : bit_vector( 7 DOWNTO 0);
  SIGNAL data8w      : bit_vector( 7 DOWNTO 0);
  SIGNAL remotew     : bit;
  SIGNAL datalenw    : bit_vector( 3 DOWNTO 0);
  SIGNAL inconerec   : bit;
  SIGNAL incegtrec   : bit;
  SIGNAL incegttra   : bit;
  SIGNAL decrec      : bit;
  SIGNAL dectra      : bit;
  SIGNAL elevrecb    : bit;
  SIGNAL hardsync    : bit;

-- llc signals
  SIGNAL initreqr  : bit;
  SIGNAL traregbit : bit;
  SIGNAL sucfrecvr : bit;
  SIGNAL sucftranr : bit;
-- signal       recindicr       : bit;
  SIGNAL activtreg : bit;
  SIGNAL activrreg : bit;
  SIGNAL activgreg : bit;
  SIGNAL sucftrano : bit;
  SIGNAL sucfrecvo : bit;
-- signal       initreqo        : bit;
-- signal       recindico       : bit;
  SIGNAL overflowo : bit;
  SIGNAL resetall  : bit;
  SIGNAL ldrecid   : bit;

-- bittiming signals
  SIGNAL tseg1     : integer RANGE 0 TO 7;  -- 5(6)
  SIGNAL tseg2     : integer RANGE 0 TO 7;  -- 4(5)
  SIGNAL sjw       : integer RANGE 0 TO 7;
  SIGNAL smpledbit : bit;

-- fce signals
  SIGNAL warnsig : bit;
  SIGNAL irqsig  : bit;
-- iocpu signals
  SIGNAL ridentifier : bit_vector(28 DOWNTO 0);
  SIGNAL rextended   : bit;
--  SIGNAL promiscous  : bit;             -- Promiscous (von iocpu zu llc)


-- common signals
  SIGNAL resetsig : bit;

-- prescaler
  SIGNAL high_i       : bit_vector(3 DOWNTO 0);
  SIGNAL low_i        : bit_vector(3 DOWNTO 0);

  SIGNAL prescale_out : bit_vector(7 DOWNTO 0);
  SIGNAL sync_reset_i : bit;
  SIGNAL Prescale_EN  : bit;                    -- DW 2005.06.21
  -- Interruptunit  
  SIGNAL activintreg : bit;
  --SIGNAL irqstatus : bit;
  --SIGNAL irqsuctra : bit;
  --SIGNAL irqsucrec : bit;
  SIGNAL ienable   : bit_vector(2 DOWNTO 0);
  SIGNAL irqstd    : bit_vector(2 DOWNTO 0);
  SIGNAL tec_i     : bit_vector(7 DOWNTO 0);
  SIGNAL rec_i     : bit_vector(7 DOWNTO 0);
-- onoff (Bit 15 in Interruptregister)
  signal switched_rx : bit;
  signal tx_i : bit;
  signal onoffn_i : bit;
  
  SIGNAL irqstatus_internal : bit;
  SIGNAL irqsucrec_internal : bit;
  SIGNAL irqsuctra_internal : bit;
  
-------------------------------------------------------------------------------
BEGIN
  -- off = 0 ,  not off = 1 , X or 1 = 1= immer rezessiv
  switched_rx <= rx or (not onoffn_i);
  tx <= tx_i or (not onoffn_i);
  


   
  PROCESS(reset, resetall)              -- reset
  BEGIN
    resetsig <= reset AND resetall;     --or
  END PROCESS;
-------------------------------------------------------------------------------
  reset_generator : resetgen1
    PORT MAP (
      reset      => resetsig,
      sync_reset => sync_reset_i,
      clock      => clock);

  MediumAccessControl : mac1 PORT MAP
    (clock,
     Prescale_EN,                      -- DW 2005.06.21 Prescale Enable eingefügt
     sync_reset_i,
     sendpoint,
     smplpoint,
     smpledbit,
     trans,
     erroractiv,
     errorpassiv,
     busof,
     load,
     actvtsftllc,
     actvtcap,
     resettra,
     identifierr,
     data1r,
     data2r,
     data3r,
     data4r,
     data5r,
     data6r,
     data7r,
     data8r,
     extendedr,
     remoter,
     datalenr,
     identifierw,
     data1w,
     data2w,
     data3w,
     data4w,
     data5w,
     data6w,
     data7w,
     data8w,
     remotew,
     datalenw,
     inconerec,
     incegtrec,
     incegttra,
     decrec,
     dectra,
     elevrecb,
     hardsync,
     tx_i,
     statedeb);


  LogicalLinkControl : llc1 PORT MAP
    (clock,
     sync_reset_i,
     initreqr,
     traregbit,
     decrec,
     dectra,
     sucfrecvr,
     sucftranr,
     rextended,
     accmaskreg_i,
     ridentifier,
     identifierw,
     activtreg,
     activrreg,
     activgreg,
     ldrecid,
     sucftrano,
     sucfrecvo,
     overflowo,
     trans,
     load,
     actvtsftllc,
     actvtcap,
     resettra,
     resetall);

  TimeControl : bittiming1 PORT MAP
    (clock,
     Prescale_EN,                       -- DW 2005.06.21
     resetsig,
     hardsync,
     switched_rx,
     tseg1,
     tseg2,
     sjw,
     sendpoint,
     smplpoint,
     smpledbit,
     bitst);

  FaultConfinement : fce1 PORT MAP
    (clock,
     sync_reset_i,
     inconerec,
     incegtrec,
     incegttra,
     decrec,
     dectra,
     elevrecb,
     erroractiv,
     errorpassiv,
     busof,
     warnsig,
     irqsig,
     tec_i,        
     rec_i);

   irqunit : interruptunit1
      PORT MAP (
         clock       => clock,
         reset       => sync_reset_i,
         ienable     => ienable,
         irqstd      => irqstd,
         irqsig      => irqsig,
         sucfrec     => sucfrecvo,
         sucftra     => sucftrano,
         activintreg => activintreg,
         irqstatus   => irqstatus_internal,
         irqsuctra   => irqsuctra_internal,
         irqsucrec   => irqsucrec_internal,
         irq         => irq
      );
   IOControl : iocpu1
      GENERIC MAP (
         system_id => system_id
      )
      PORT MAP (
         clock        => clock,
         reset        => sync_reset_i,
         address      => address,
         readdata     => readdata,
         writedata    => writedata,
         read_n       => read_n,
         write_n      => write_n,
         cs           => cs,
         activgreg    => activgreg,
         activtreg    => activtreg,
         activrreg    => activrreg,
         activintreg  => activintreg,
         ldrecid      => ldrecid,
         sucftrani    => sucftrano,
         sucfrecvi    => sucfrecvo,
         overflowo    => overflowo,
         erroractive  => erroractiv,
         errorpassive => errorpassiv,
         busoff       => busof,
         warning      => warnsig,
         irqstatus    => irqstatus_internal,
         irqsuctra    => irqsuctra_internal,
         irqsucrec    => irqsucrec_internal,
         rec_id       => identifierw,
         rremote      => remotew,
         rdlc         => datalenw,
         data1r       => data1w,
         data2r       => data2w,
         data3r       => data3w,
         data4r       => data4w,
         data5r       => data5w,
         data6r       => data6w,
         data7r       => data7w,
         data8r       => data8w,
         teccan       => tec_i,
         reccan       => rec_i,
         sjw          => sjw,
         tseg1        => tseg1,
         tseg2        => tseg2,
         sucfrecvo    => sucfrecvr,
         sucftrano    => sucftranr,
         initreqr     => initreqr,
         traregbit    => traregbit,
         accmask      => accmaskreg_i,
         ridentifier  => ridentifier,
         rextended    => rextended,
         ienable      => ienable,
         irqstd       => irqstd,
         tidentifier  => identifierr,
         data1t       => data1r,
         data2t       => data2r,
         data3t       => data3r,
         data4t       => data4r,
         data5t       => data5r,
         data6t       => data6r,
         data7t       => data7r,
         data8t       => data8r,
         textended    => extendedr,
         tremote      => remoter,
         tdlc         => datalenr,
         prescale_out => prescale_out,
         onoffn       => onoffn_i
      );
  
  prescaler : prescale1 PORT MAP 
    (clock     => clock,
     reset     => reset,
     high      => high_i,
     low       => low_i,
     Prescale_EN => Prescale_EN         -- DW 2005.06.21        
  );
  
  

  
  high_i <= prescale_out(7 DOWNTO 4);
  low_i  <= prescale_out(3 DOWNTO 0);
  Prescale_EN_debug <= Prescale_EN;
  
    -- Implicit buffered output assignments
   irqstatus <= irqstatus_internal;
   irqsucrec <= irqsucrec_internal;
   irqsuctra <= irqsuctra_internal;
END behv;

