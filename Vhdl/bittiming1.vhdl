-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell 
--                                     Diplomarbeit 
-------------------------------------------------------------------------------
--                            Datei: bittiming.vhd
--                     Beschreibung: Timing Control
-------------------------------------------------------------------------------
-- rein Struktur, Verbindungen der Komponenten
-- tseg_reg ist zwischen sum und Bittime-FSM, speichert, oder wird mit
-- tseg1pcount geladen, oder tseg1psjw.
-- edgepuffer: speichert einen takt lang das gesampelte bit (für flanken), das
-- zeitverzögerte (signal puffer) in FSM und smpldbit_reg (neu), dort
-- übernahme, und ausgabe auf port smpldbit zum MAC
-- Struktur: (Instanz, Komponente)
-- tseg_reg_i : tseg_reg : Latch für verändertes tseg (aus FSM raus)
-- smpldbit_reg_i: smpldbit_reg: Latch für smpldbit, kann mit puffer geladen wrd
-- flipflop: edgepuffer: Zeitverzögertes smpldbit
-- counter: timecount: Grundeinheitenzähler
-- arithmetic: sum: Addi.- Subs. von Zählerstand, sjw- Berechnung
-- bittiming: bittime: Zustandsmaschine
-- DW 2005.06.21 Prescale Enable eingefügt

-- | Leduc | 12.02.2020 | Added Changes done in Verilog Triplication Files
  
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
  
ENTITY bittiming1 IS
  PORT(clock : IN bit;                  -- 10 MHz
       Prescale_EN : IN  bit;           -- DW 2005.06.21 Prescale Enable
       reset       : IN  bit;
       hardsync    : IN  bit;           -- von MACFSM
       rx          : IN  bit;           -- von aussen
       tseg1       : IN  integer RANGE 0 TO 7;  -- 5(6) Generalregister
       tseg2       : IN  integer RANGE 0 TO 7;  -- 4(5)        "
       sjw         : IN  integer RANGE 0 TO 7;  --             "
       sendpoint   : OUT bit;           -- zu MACFSM
       smplpoint   : OUT bit;           --     "
       smpledbit   : OUT bit;           -- zu MAC- destuffing, biterrordetect
       bitst       : OUT std_logic_vector(6 DOWNTO 0));  -- DW: zum debuggen
END bittiming1;

ARCHITECTURE behv OF bittiming1 IS
  COMPONENT bittime1
    PORT (
      clock              : IN  bit;
      Prescale_EN : IN  bit;           -- DW 2005.06.21 Prescale Enable
      reset              : IN  bit;
      hardsync           : IN  bit;
      notnull            : IN  bit;
      gtsjwp1            : IN  bit;
      gttseg1p1          : IN  bit;
      cpsgetseg1ptseg2p2 : IN  bit;
      cetseg1ptseg2p1    : IN  bit;
      countesmpltime     : IN  bit;
      puffer             : IN  bit;
      rx                 : IN  bit;
      increment          : OUT bit;
      setctzero          : OUT bit;
      setctotwo          : OUT bit;
      sendpoint          : OUT bit;
      smplpoint          : OUT bit;
      smpldbit_reg_ctrl  : OUT bit_vector(1 DOWNTO 0);
      tseg_reg_ctrl      : OUT bit_vector(1 DOWNTO 0);
      bitst              : OUT std_logic_vector(3 downto 0));
  END COMPONENT;

  COMPONENT sum1
    PORT(count              : IN  integer RANGE 0 TO 15;
         tseg1org           : IN  integer RANGE 0 TO 7;   -- 5(6)
         tseg1mpl           : IN  integer RANGE 0 TO 31;  -- 5(6)
         tseg2              : IN  integer RANGE 0 TO 7;   -- 4(5)
         sjw                : IN  integer RANGE 0 TO 7;
         notnull            : OUT bit;
         gtsjwp1            : OUT bit;
         gttseg1p1          : OUT bit;
         cpsgetseg1ptseg2p2 : OUT bit;
         cetseg1ptseg2p1    : OUT bit;
         countesmpltime     : OUT bit;
         tseg1p1psjw        : OUT integer RANGE 0 TO 31;
         tseg1pcount        : OUT integer RANGE 0 TO 31);
  END COMPONENT;

  COMPONENT timecount1
    PORT(clock     : IN  bit;
         Prescale_EN : IN  bit;           -- DW 2005.06.21 Prescale Enable
         reset     : IN  bit;
         increment : IN  bit;
         setctzero : IN  bit;
         setctotwo : IN  bit;
         counto    : OUT integer RANGE 0 TO 15);
  END COMPONENT;

  COMPONENT edgepuffer1
    PORT(clock  : IN  bit;
         Prescale_EN : IN  bit;           -- DW 2005.06.21 Prescale Enable
         reset  : IN  bit;
         rx     : IN  bit;
         puffer : OUT bit);
  END COMPONENT;

  COMPONENT tseg_reg1
    -- latch ersatz für fsm
    PORT (
      clock       : in  bit;            --DW 2005.06.26 Clock
      reset       : in  bit;            --DW 2005.06.26 Reset aktiv low
      ctrl        : IN  bit_vector(1 DOWNTO 0);
      tseg1       : IN  integer RANGE 0 TO 7;
      tseg1pcount : IN  integer RANGE 0 TO 31;
      tseg1p1psjw : IN  integer RANGE 0 TO 31;
      tseg1mpl    : OUT integer RANGE 0 TO 31);
  END COMPONENT;

  COMPONENT smpldbit_reg1
    -- latch ersatz für fsm (smpledbit von hier direkt in MAC!)
    PORT (
      clock    : IN  bit;
      reset    : IN  bit;
      ctrl     : IN  bit_vector(1 DOWNTO 0);
      smpldbit : OUT bit;
      puffer   : IN  bit);
  END COMPONENT;
-------------------------------------------------------------------------------
    SIGNAL tseg1pcount : integer RANGE 0 TO 31;
  SIGNAL tseg1p1psjw        : integer RANGE 0 TO 31;
  SIGNAL notnull            : bit;
  SIGNAL gtsjwp1            : bit;
  SIGNAL gttseg1p1          : bit;
  SIGNAL cpsgetseg1ptseg2p2 : bit;
  SIGNAL cetseg1ptseg2p1    : bit;
  SIGNAL countesmpltime     : bit;
  SIGNAL puffer             : bit;
  SIGNAL tseg1mpl           : integer RANGE 0 TO 31;  -- 5(6)
  SIGNAL increment          : bit;
  SIGNAL setctzero          : bit;
  SIGNAL setctotwo          : bit;
  SIGNAL count              : integer RANGE 0 TO 15;
  SIGNAL smpldbit_reg_ctrl  : bit_vector(1 DOWNTO 0);
  SIGNAL tseg_reg_ctrl      : bit_vector(1 DOWNTO 0);
  SIGNAL rxf                : bit;
--  SIGNAL Prescale_EN        : bit;      -- DW 2005.06.21 Prescale Enable
  SIGNAL deblatch           : std_logic_vector(2 DOWNTO 0);
-------------------------------------------------------------------------------
BEGIN

-- purpose: filter out setup time violation for FSM
-- type   : sequential
-- inputs : clock, reset, rx
-- outputs: rxf
cleanupRX: PROCESS (clock, reset)       -- Das hat Tobi eingefügt
BEGIN  -- PROCESS cleanupRX
  IF reset = '0' THEN                   -- asynchronous reset (active low)
    rxf <= '1';
  ELSIF clock'event AND clock = '1' THEN  -- rising clock edge
    rxf <= rx;
  END IF;
END PROCESS cleanupRX;

  -- deblatch(4 DOWNTO 0) <= conv_std_logic_vector(tseg1mpl, 5);
  deblatch(0) <= to_stduLogic (Prescale_EN);
  deblatch(2 DOWNTO 1) <= to_stdLogicVector(tseg_reg_ctrl);
--  deblatch(7) <= to_stduLogic (countesmpltime);
  bitst(6 DOWNTO 4) <= deblatch;
  
  bittiming : bittime1
    PORT MAP (
      clock              => clock,      -- DW 2005.06.21 Prescale Enable
      Prescale_EN        => Prescale_EN,  -- DW 2005.06.21 Prescale Enable
      reset              => reset,
      hardsync           => hardsync,
      notnull            => notnull,
      gtsjwp1            => gtsjwp1,
      gttseg1p1          => gttseg1p1,
      cpsgetseg1ptseg2p2 => cpsgetseg1ptseg2p2,
      cetseg1ptseg2p1    => cetseg1ptseg2p1,
      countesmpltime     => countesmpltime,
      puffer             => puffer,
      rx                 => rxf,
      increment          => increment,
      setctzero          => setctzero,
      setctotwo          => setctotwo,
      sendpoint          => sendpoint,
      smplpoint          => smplpoint,
      smpldbit_reg_ctrl  => smpldbit_reg_ctrl,
      tseg_reg_ctrl      => tseg_reg_ctrl,
      bitst              => bitst(3 DOWNTO 0));

-------------------------------------------------------------------------------
  aritmetic : sum1 PORT MAP
    (count,
     tseg1,
     tseg1mpl,
     tseg2,
     sjw,
     notnull,
     gtsjwp1,
     gttseg1p1,
     cpsgetseg1ptseg2p2,
     cetseg1ptseg2p1,
     countesmpltime,
     tseg1p1psjw,
     tseg1pcount);
-------------------------------------------------------------------------------
  counter : timecount1 PORT MAP
    (clock, -- DW 2005.06.21 Prescale Enable
     Prescale_EN,  -- DW 2005.06.21 Prescale Enable
     reset,
     increment,
     setctzero,
     setctotwo,
     count);
-------------------------------------------------------------------------------
  flipflop : edgepuffer1 PORT MAP
    (clock,                             -- DW 2005.06.21 Prescale Enable
     Prescale_EN,  -- DW 2005.06.21 Prescale Enable
     reset,
     rxf,
     puffer);
-------------------------------------------------------------------------------
  smpldbit_reg_i : smpldbit_reg1
    PORT MAP (
      clock    => clock,
      reset    => reset,
      ctrl     => smpldbit_reg_ctrl,
      smpldbit => smpledbit,
      puffer   => puffer);
-------------------------------------------------------------------------------
  tseg_reg_i : tseg_reg1
    PORT MAP (
      clock,
      reset,
      ctrl        => tseg_reg_ctrl,
      tseg1       => tseg1,
      tseg1pcount => tseg1pcount,
      tseg1p1psjw => tseg1p1psjw,
      tseg1mpl    => tseg1mpl);

END behv;

