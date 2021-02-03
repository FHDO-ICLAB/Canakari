-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                           
-------------------------------------------------------------------------------
--                            Datei: iocpuavalon.vhd
--                     Beschreibung: CPU Interface Control
-------------------------------------------------------------------------------
-- Alle Registereingänge für CPU über regbus zusammengeschaltet, write_demux 
-- erzeugt aus adresse das entsprechende schreibsignal (activate). Zum Auslesen
-- Multiplexer schaltet direkt auf Datenbus.
-- Änderungen Avalon Busprotokoll, FSM weg.
-- Struktur:
-- rdata78: recregister: Empfangene Datenbytes 7,8
-- rdata56: recregister: Empfangene Datenbytes 5,6
-- rdata34: recregister: Empfangene Datenbytes 3,4
-- rdata12: recregister: Empfangene Datenbytes 1,2
-- rarbit2: recarbitreg: Akzeptanzfilterung ID 28..13
-- rarbit1: recarbitreg: Akzeptanzfilterung ID 12..0
-- mcontrol: recmescontrolreg: receiv message control register
-- tdata78: transmitreg: Zu sendende Datenbytes 7,8
-- tdata56: transmitreg: Zu sendende Datenbytes 5,6
-- tdata34: transmitreg: Zu sendende Datenbytes 3,4
-- tdata12: transmitreg: Zu sendende Datenbytes 1,2
-- tarbit2: transmitreg: Sende ID 28..13
-- tarbit1: transmitreg: Sende ID 12..0
-- tcontrol: transmesconreg: transmit message control register
-- general: generalregister
-- komplexe: multiplexer: CONFIGURATION multiplexer (multiplexer_top.vhdl)
-- prescaleregister: prescalereg: High und Low Werte für Vorteiler
-------------------------------------------------------------------------------
-- Changes:
--  020719_Beer, removed fehlregr process and fehlercount module
--
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;
LIBRARY synopsys;
USE synopsys.attributes.ALL;

ENTITY iocpu1 IS
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
       sucftrano    : OUT   bit; 							   -- genregr informs llc succesfull transmission bit
       initreqr     : OUT   bit;  							   -- genregr informs llc reset/init bit;
       traregbit    : OUT   bit;                           -- genregr informs llc transmission indic bit
       accmask      : OUT   bit_vector(28 DOWNTO 0);       -- Acceptance Mask Register
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
       prescale_out : OUT   bit_vector(7 DOWNTO 0);       -- prescaler
       onoffn       : out   bit);
END iocpu1;
-------------------------------------------------------------------------------
ARCHITECTURE behv OF iocpu1 IS
  COMPONENT multiplexer1
    GENERIC (
      system_id : bit_vector(15 DOWNTO 0) );    -- HW-ID

    PORT(readdata   : OUT std_logic_vector(15 DOWNTO 0);
--         clock      : IN    bit;
         writedata  : IN  std_logic_vector(15 DOWNTO 0);
         address : IN    bit_vector(4 DOWNTO 0);
         cs      : IN  std_logic;
         read_n  : IN  std_logic;
         write_n : IN  std_logic;
         preregr : IN    bit_vector(15 DOWNTO 0);  --prescale register
         genregr : IN    bit_vector(15 DOWNTO 0);  --general register
         intregr : IN    bit_vector(15 DOWNTO 0);  --general register
         traconr : IN    bit_vector(15 DOWNTO 0);  --transmit message control register
         traar1r : IN    bit_vector(15 DOWNTO 0);  --arbitration Bits 28 - 13
         traar2r : IN    bit_vector(15 DOWNTO 0);  --arbitration Bits 12 - 0 
         trad01r : IN    bit_vector(15 DOWNTO 0);  --data0 + data1
         trad23r : IN    bit_vector(15 DOWNTO 0);  --data2 + data3
         trad45r : IN    bit_vector(15 DOWNTO 0);  --data4 + data5
         trad67r : IN    bit_vector(15 DOWNTO 0);  --data6 + data7
         recconr : IN    bit_vector(15 DOWNTO 0);  --receive message control register
         accmask1r : IN    bit_vector(15 DOWNTO 0);  -- acceptance mask register
         accmask2r : IN    bit_vector(15 DOWNTO 0);  -- acceptance mask register
         recar1r : IN    bit_vector(15 DOWNTO 0);  --arbitration Bits 28 - 13
         recar2r : IN    bit_vector(15 DOWNTO 0);  --arbitration Bits 12 - 0 
         recd01r : IN    bit_vector(15 DOWNTO 0);  --data0 + data1
         recd23r : IN    bit_vector(15 DOWNTO 0);  --data2 + data3
         recd45r : IN    bit_vector(15 DOWNTO 0);  --data4 + data5
         recd67r : IN    bit_vector(15 DOWNTO 0);  --data6 + data7
         fehlregr: IN    bit_vector(15 DOWNTO 0);
         regbus  : OUT bit_vector(15 DOWNTO 0);
         presca  : OUT bit;
         genrega : OUT bit;  -- activate general register
         intrega : OUT bit;
         tracona : OUT bit;  -- activate transmit message control register
         traar1a : OUT bit;  -- activate arbitration Bits 28 - 13
         traar2a : OUT bit;  -- activate arbitration Bits 12 - 0 + 3 Bits reserved
         trad01a : OUT bit;  -- activate data0 + data1
         trad23a : OUT bit;  -- activate data2 + data3
         trad45a : OUT bit;  -- activate data4 + data5
         trad67a : OUT bit;  -- activate data6 + data7
         reccona : OUT bit;  -- activate receive message control register
         recar1a : OUT bit;  -- activate arbitration Bits 28 - 13w
         recar2a : OUT bit; -- activate arbitration Bits 12 - 0 + 3 Bits reserved
         accmask1a : OUT bit;
         accmask2a : OUT bit);
  END COMPONENT;

  COMPONENT generalregister1
    PORT(clk   : IN  bit;
         rst   : IN  bit;
         cpu   : IN  bit;               -- CPU wuenscht Zugriff
         can   : IN  bit;               -- controller wuenscht Zugriff
         bof   : IN  bit;               -- bus off
         era   : IN  bit;               -- error activ
         erp   : IN  bit;               -- error passive
         war   : IN  bit;               -- warning error count level
         sjw   : IN  bit_vector(2 DOWNTO 0);
         tseg1 : IN  bit_vector(2 DOWNTO 0);
         tseg2 : IN  bit_vector(2 DOWNTO 0);
         ssp   : IN  bit;               -- succesfull send processor
         srp   : IN  bit;               -- succesfull received processor
         ssc   : IN  bit;               -- succesfull send can
         src   : IN  bit;               -- succesfull received can
         rsp   : IN  bit;               -- reset/initialization processor
         reg   : OUT bit_vector(15 DOWNTO 0));  -- generalregister
  END COMPONENT;

  COMPONENT recmescontrolreg1
    PORT( clk  : IN  bit;
          rst  : IN  bit;
          cpu  : IN  bit;               -- CPU wuenscht Zugriff
          can  : IN  bit;               -- controller wuenscht Zugriff
          ofp  : IN  bit;               -- overflow indication processor
          ofc  : IN  bit;               -- overflow indication can
          rip  : IN  bit;               -- receive indication processor
          ric  : IN  bit;               -- receive indication can
          ien  : IN  bit;               -- interrupt enable
          rtr  : IN  bit;               -- remote flag
          ext  : IN  bit;               -- extended flag
          dlc  : IN  bit_vector(3 DOWNTO 0);    -- data length code
          reg  : OUT bit_vector(15 DOWNTO 0));  -- generalregister
  END COMPONENT;

  COMPONENT recarbitreg1
    PORT(clk     : IN  bit;
         rst     : IN  bit;
         cpu     : IN  bit;             -- CPU wuenscht Zugriff
         can     : IN  bit;             -- controller will zugreifen (im promiscous mode um ID zu schreiben)        
         reginp  : IN  bit_vector(15 DOWNTO 0);  --
         recidin : IN  bit_vector(15 DOWNTO 0);  -- controller schreibt id
         regout  : OUT bit_vector(15 DOWNTO 0));
  END COMPONENT;

  COMPONENT recregister1
    PORT(clk    : IN  bit;
         rst    : IN  bit;
         can    : IN  bit;                       -- LLC wuenscht Zugriff
         regin1 : IN  bit_vector(7 DOWNTO 0);    --
         regin2 : IN  bit_vector(7 DOWNTO 0);    --
         regout : OUT bit_vector(15 DOWNTO 0));  -- 
  END COMPONENT;

  COMPONENT transmesconreg1
    PORT(clk    : IN  bit;
         rst    : IN  bit;
         cpu    : IN  bit;              -- CPU wuenscht Zugriff
         can    : IN  bit;              -- controller wuenscht Zugriff
         tsucf  : IN  bit;              -- transmission request set back by can
         reginp : IN  bit_vector(15 DOWNTO 0);   -- 
         regout : OUT bit_vector(15 DOWNTO 0));  -- generalregister
  END COMPONENT;

  COMPONENT transmitreg1 
    PORT(clk    : IN  bit;
         rst    : IN  bit;
         cpu    : IN  bit;                       -- CPU wuenscht Zugriff
         reginp : IN  bit_vector(15 DOWNTO 0);   -- 
         regout : OUT bit_vector(15 DOWNTO 0));  -- generalregister
  END COMPONENT;
  
  COMPONENT prescalereg1
    PORT(clk    : IN  bit;
         rst    : IN  bit;
         cpu    : IN  bit;
         reginp : IN  bit_vector(15 DOWNTO 0);
         regout : OUT bit_vector(15 DOWNTO 0)); --Beer 2018_06_18: von 8 auf 16bit
  END COMPONENT;

  COMPONENT accmaskreg1
    PORT(clk    : IN  bit;
         rst    : IN  bit;
         cpu    : IN  bit;                       -- CPU wuenscht Zugriff
         reginp : IN  bit_vector(15 DOWNTO 0);   -- Registerbus
         regout : OUT bit_vector(15 DOWNTO 0));  -- Acceptance Mask Register
  END COMPONENT;

  COMPONENT interrupregister1
    PORT(clk        : IN  bit;
         rst        : IN  bit;
         cpu        : IN  bit;                -- CPU wuenscht Zugriff
         can        : IN  bit;                -- controller wuenscht Zugriff
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
         reg   : OUT bit_vector(15 DOWNTO 0));  
    END COMPONENT ;


--   COMPONENT fehlercountreg1
--    PORT( clk          : IN  bit;
--         rst          : IN  bit;
--         teccan       : IN bit_vector(7 DOWNTO 0);
--         reccan       : IN bit_vector(7 DOWNTO 0);
--         reg          : OUT bit_vector(15 DOWNTO 0));  -- Fehlerregister
--   END COMPONENT;
  
  SIGNAL preregr      : bit_vector(15 DOWNTO 0);  --prescale register
  SIGNAL genregr      : bit_vector(15 DOWNTO 0);  --general register
  SIGNAL intregr      : bit_vector(15 DOWNTO 0);  --interrupt register
  SIGNAL traconr      : bit_vector(15 DOWNTO 0);  --transmit message control register
  SIGNAL traar1r      : bit_vector(15 DOWNTO 0);  --arbitration Bits 28 - 13
  SIGNAL traar2r      : bit_vector(15 DOWNTO 0);  --arbitration Bits 12 - 0 
  SIGNAL trad01r      : bit_vector(15 DOWNTO 0);  --data0 + data1
  SIGNAL trad23r      : bit_vector(15 DOWNTO 0);  --data2 + data3
  SIGNAL trad45r      : bit_vector(15 DOWNTO 0);  --data4 + data5
  SIGNAL trad67r      : bit_vector(15 DOWNTO 0);  --data6 + data7
  SIGNAL recconr      : bit_vector(15 DOWNTO 0);  --receive message control register
  SIGNAL recar1r      : bit_vector(15 DOWNTO 0);  --arbitration Bits 28 - 13
  SIGNAL recar2r      : bit_vector(15 DOWNTO 0);  --arbitration Bits 12 - 0 
  SIGNAL accmask1r    : bit_vector(15 DOWNTO 0);  --Acceptance Bits 28 - 13 
  SIGNAL accmask2r    : bit_vector(15 DOWNTO 0);  --Acceptance Bits 12 - 0 
  SIGNAL recd01r      : bit_vector(15 DOWNTO 0);  --data0 + data1
  SIGNAL recd23r      : bit_vector(15 DOWNTO 0);  --data2 + data3
  SIGNAL recd45r      : bit_vector(15 DOWNTO 0);  --data4 + data5
  SIGNAL recd67r      : bit_vector(15 DOWNTO 0);  --data6 + data7
  SIGNAL fehlregout   : bit_vector(15 DOWNTO 0);
  SIGNAL fehlregr     : bit_vector(15 DOWNTO 0);
-- datenbus für alle register, die von der CPU beschrieben werden können
  SIGNAL register_bus : bit_vector(15 DOWNTO 0);
-- Aktivier Register, wenn cpu schreibt
  SIGNAL presca   : bit;
  SIGNAL genrega  : bit;  -- activate general register
  SIGNAL intrega  : bit;  -- activate interrupt register
  SIGNAL tracona  : bit;  -- activate transmit message control register
  SIGNAL traar1a  : bit;  -- activate arbitration Bits 28 - 13
  SIGNAL traar2a  : bit;  -- activate arbitration Bits 12 - 0 + 3 Bits reserved
  SIGNAL trad01a  : bit;  -- activate data0 + data1
  SIGNAL trad23a  : bit;  -- activate data2 + data3
  SIGNAL trad45a  : bit;  -- activate data4 + data5
  SIGNAL trad67a  : bit;  -- activate data6 + data7
  SIGNAL reccona  : bit;  -- activate receive message control register
  SIGNAL recar1a  : bit;  -- activate arbitration Bits 28 - 13w
  SIGNAL recar2a  : bit;  -- activate arbitration Bits 12 - 0 + 3 Bits reserved
  SIGNAL recidin1 : bit_vector(15 DOWNTO 0);
  SIGNAL recidin2 : bit_vector(15 DOWNTO 0);
  SIGNAL accmask1a :bit;  -- activate acceptance mask register
  SIGNAL accmask2a :bit;  -- activate acceptance mask register
BEGIN
      
-------------------------------------------------------------------------------  
  komplexe : multiplexer1
    generic map (
      system_id => system_id )
    PORT MAP
    (readdata,
--     clock,
     writedata,
     address,
     cs,
     read_n,
     write_n,
     preregr,
     genregr,
     intregr,
     traconr,
     traar1r,
     traar2r,
     trad01r,
     trad23r,
     trad45r,
     trad67r,
     recconr,
     accmask1r,
     accmask2r,
     recar1r,
     recar2r,
     recd01r,
     recd23r,
     recd45r,
     recd67r,
     fehlregout,
     register_bus,
     presca,
     genrega,
     intrega,
     tracona,
     traar1a,
     traar2a,
     trad01a,
     trad23a,
     trad45a,
     trad67a,
     reccona,
     recar1a,
     recar2a,
     accmask1a,
     accmask2a);
-------------------------------------------------------------------------------

prescaleregister : prescalereg1
    PORT MAP (
      clock,
      reset,
      presca,
      register_bus,           -- Input ist Bus
      preregr); --Beer, 2018_06_18
  
  PROCESS(preregr)
  BEGIN
    prescale_out <= preregr (7 DOWNTO 0);
  END PROCESS;    



  general : generalregister1 PORT MAP
    (clock,
     reset,
     genrega,                           -- CPU wuenscht Zugriff
     activgreg,                         -- controller wuenscht Zugriff
     busoff,
     erroractive,
     errorpassive,
     warning,
     register_bus(8 DOWNTO 6),          -- sjw
     register_bus(5 DOWNTO 3),          -- tseg1
     register_bus(2 DOWNTO 0),          -- tseg2
     register_bus(11),                  -- succesfull send processor
     register_bus(10),                  -- succesfull received processor
     sucftrani,                         -- succesfull send can
     sucfrecvi,                         -- succesfull received can
     register_bus(9),                   -- reset/initialization processor
     genregr);                          -- register out

  PROCESS(genregr)
  BEGIN                                 -- dieses Konstrukt konvertiert
                                        -- Bitvektor zu Integer
    sjw       <= conv_integer(unsigned(to_stdLogicVector(genregr(8 DOWNTO 6))));
    tseg1     <= conv_integer(unsigned(to_stdLogicVector(genregr(5 DOWNTO 3))));
    tseg2     <= conv_integer(unsigned(to_stdLogicVector(genregr(2 DOWNTO 0))));
    sucfrecvo <= genregr(10);
    sucftrano <= genregr(11);
    initreqr  <= genregr(9);
  END PROCESS;
-------------------------------------------------------------------------------
  tcontrol : transmesconreg1 PORT MAP
    (clock,
     reset,
     tracona,                           -- CPU wuenscht Zugriff
     activtreg,                         -- controller wuenscht Zugriff
     sucftrani,                         -- successful transmission
     register_bus,                      --traconw,
     traconr);

  PROCESS(traconr)
  BEGIN
    traregbit <= traconr(15);
    textended <= traconr(4);
    tremote   <= traconr(5);
    tdlc      <= traconr(3 DOWNTO 0);
  END PROCESS;
-------------------------------------------------------------------------------
  tarbit1 : transmitreg1 PORT MAP
    (clock,
     reset,
     traar1a,                           -- CPU wuenscht Zugriff
     register_bus,                      --traar1w,
     traar1r);
-------------------------------------------------------------------------------
  tarbit2 : transmitreg1 PORT MAP
    (clock,
     reset,
     traar2a,                           -- CPU wuenscht Zugriff
     register_bus,                      --traar2w
     traar2r);

  PROCESS(traar1r, traar2r)
  BEGIN
    tidentifier(28 DOWNTO 13) <= traar1r;  -- MAC
    tidentifier(12 DOWNTO 0)  <= traar2r(15 DOWNTO 3);
  END PROCESS;
-------------------------------------------------------------------------------
  tdata12 : transmitreg1 PORT MAP
    (clock,
     reset,
     trad01a,                           -- CPU wuenscht Zugriff
     register_bus,                      --trad01w,
     trad01r);

  PROCESS(trad01r)
  BEGIN
    data1t <= trad01r(15 DOWNTO 8);     -- MAC
    data2t <= trad01r( 7 DOWNTO 0);
  END PROCESS;
-------------------------------------------------------------------------------
  tdata34 : transmitreg1 PORT MAP
    (clock,
     reset,
     trad23a,                           -- CPU wuenscht Zugriff
     register_bus,                      --trad23w,
     trad23r);

  PROCESS(trad23r)
  BEGIN
    data3t <= trad23r(15 DOWNTO 8);     -- MAC
    data4t <= trad23r( 7 DOWNTO 0);
  END PROCESS;
-------------------------------------------------------------------------------
  tdata56 : transmitreg1 PORT MAP
    (clock,
     reset,
     trad45a,                           -- CPU wuenscht Zugriff
     register_bus,                      --trad45w,
     trad45r);

  PROCESS(trad45r)
  BEGIN
    data5t <= trad45r(15 DOWNTO 8);
    data6t <= trad45r( 7 DOWNTO 0);
  END PROCESS;
-------------------------------------------------------------------------------
  tdata78 : transmitreg1 PORT MAP
    (clock,
     reset,
     trad67a,                           -- CPU wuenscht Zugriff
     register_bus,                      --trad67w,
     trad67r);

  PROCESS(trad67r)
  BEGIN
    data7t <= trad67r(15 DOWNTO 8);
    data8t <= trad67r( 7 DOWNTO 0);
  END PROCESS;
-------------------------------------------------------------------------------
  mcontrol : recmescontrolreg1 PORT MAP
    (clock,
     reset,
     reccona,                           -- CPU wuenscht Zugriff
     activrreg,                         -- controller wuenscht Zugriff
     register_bus(15),                  -- overflow indication processor
     overflowo,                         -- overflow indication can
     register_bus(14),                  -- receive indication processor
     activrreg,  --recindico,             -- receive indication can
     register_bus(8),                   -- interrupt enable
     rremote,                           -- remote flag
     register_bus(4),                   -- extended flag
 --    register_bus(13),                  -- Promiscous Mode von cpu anschalten
     rdlc,                              -- data length code
     recconr);                          -- 

  PROCESS(recconr)
  BEGIN
    rextended  <= recconr(4);
 --   promiscous <= recconr(13);          -- outbit Promiscous Mode (zu llc)
  END PROCESS;
-------------------------------------------------------------------------------
  rarbit1 : recarbitreg1 PORT MAP
    (clock,
     reset,
     recar1a,                           -- CPU wuenscht Zugriff
     ldrecid,
     register_bus,                      -- Ausgang
     recidin1,
     recar1r);
-------------------------------------------------------------------------------
  rarbit2 : recarbitreg1 PORT MAP
    (clock,
     reset,
     recar2a,                           -- CPU wuenscht Zugriff
     ldrecid,                           -- LLC  schreibt im Prom. Mode Id
     register_bus,                      -- Ausgang
     recidin2,
     recar2r);

  PROCESS (rec_id)
  BEGIN  -- PROCESS
    recidin1              <= rec_id(28 DOWNTO 13);  -- von MAC, schreiben
	recidin2 <= rec_id(12 DOWNTO 0) & "000"; -- von Mac, schreiben
  END PROCESS;

  PROCESS(recar1r, recar2r)
  BEGIN
    ridentifier(28 DOWNTO 13) <= recar1r;  -- zu llc
    ridentifier(12 DOWNTO 0)  <= recar2r(15 DOWNTO 3);  -- zu llc
  END PROCESS;
-------------------------------------------------------------------------------
  ---NEU
-------------------------------------------------------------------------------
accmask1 : accmaskreg1 PORT MAP
    (clock,
     reset,
     accmask1a,                           -- CPU wuenscht Zugriff
     register_bus,                      -- Ausgang
     accmask1r);
-------------------------------------------------------------------------------
  accmask2 : accmaskreg1 PORT MAP
    (clock,
     reset,
     accmask2a,                           -- CPU wuenscht Zugriff
     register_bus,                      -- Ausgang
     accmask2r);


  PROCESS(accmask1r, accmask2r)
  BEGIN
    accmask(28 DOWNTO 13) <= accmask1r;  -- zu llc
    accmask(12 DOWNTO 0)  <= accmask2r(15 DOWNTO 3);  -- zu llc
  END PROCESS;
-------------------------------------------------------------------------------
interruptreg : interrupregister1 PORT MAP
     (clock,
      reset,
      intrega,                             -- CPU wuenscht Zugriff
      activintreg,                         -- controller wuenscht Zugriff
      register_bus(15),                     -- iestatusp
      register_bus(6),                     -- iestatusp
      register_bus(5),                     -- iesuctrap
      register_bus(4),                     -- iesucrecp
      register_bus(2),                     -- irqstatusp
      register_bus(1),                     -- irqsuctrap
      register_bus(0),                     -- irqsucrecp
      irqstatus,                           -- irqstatusc
      irqsuctra,                           -- irqsuctrac
      irqsucrec,                           -- irqsucrecc
      intregr);                            -- reg 
      
  PROCESS(intregr)
  BEGIN
    onoffn       <= intregr(15);
    ienable      <= intregr(6 DOWNTO 4);
    irqstd       <= intregr(2 DOWNTO 0);
  END PROCESS;
-------------------------------------------------------------------------------
-- fehlercount: fehlercountreg1 port map 
--      ( clock,
--        reset,      
--        teccan,    
--        reccan,    
--        fehlregr);  
--  
--  PROCESS(fehlregr)
--  BEGIN
--    fehlregout     <= fehlregr(15 DOWNTO 0);
--  END PROCESS;
  
  rdata12 : recregister1 PORT MAP
    (clock,
     reset,
     activrreg,                         -- LLC wuenscht Zugriff
     data1r,
     data2r,
     recd01r);
-------------------------------------------------------------------------------
  rdata34 : recregister1 PORT MAP
    (clock,
     reset,
     activrreg,                         -- LLC wuenscht Zugriff
     data3r,
     data4r,
     recd23r);
-------------------------------------------------------------------------------
  rdata56 : recregister1 PORT MAP
    (clock,
     reset,
     activrreg,                         -- LLC wuenscht Zugriff
     data5r,
     data6r,
     recd45r);
-------------------------------------------------------------------------------
  rdata78 : recregister1 PORT MAP
    (clock,
     reset,
     activrreg,                         -- LLC wuenscht Zugriff
     data7r,
     data8r,
     recd67r);
     
    fehlregout     <= teccan & reccan;     -- Beer
     
END behv;
