-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell
--                                     Diplomarbeit                                                
-------------------------------------------------------------------------------
--                            Datei: fce.vhd
--                     Beschreibung: Fault Confinement Entity
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- FCE unterteilung in FSM, REC(Receive Error Counter), TEC (Transmit..)
-- Die Counter geben wichtige Zählerstände als Signal, kein Vergleich mehr in
-- FSM -> weniger Signale, FSM extrahierbar.
-- rein strukturorientiert, bis auf AND für reset
-- erb_count: erbcount: Zählt 11 rez. Bits um nach 128 Busoff zu verlassen
-- tec_count: tec: Transmit error Counter
-- rec:count: rec: receive Error Counter
-- fsm: faultfsm: FSM steuert Zustandsübergänge EA->EP->BO->EA->..
-------------------------------------------------------------------------------
ENTITY fce1 IS
  PORT(clock        : IN  bit;
       reset        : IN  bit;
       inconerec    : IN  bit;          -- MACFSM zu REC
       incegtrec    : IN  bit;          -- MACFSM zu REC
       incegttra    : IN  bit;          -- MACFSM zu TEC
       decrec       : IN  bit;          -- MACFSM zu REC
       dectra       : IN  bit;          -- MACFSM zu TEC
       elevrecb     : IN  bit;          -- MACFSM zu ERB
       erroractive  : OUT bit;          -- MACFSM, IOCPU
       errorpassive : OUT bit;          -- MACFSM, IOCPU
       busoff       : OUT bit;          -- MACFSM, IOCPU
       warnsig      : OUT bit;         -- IOCPU, generalregister
       irqsig       : OUT bit;
       tecfce       : out    bit_vector(7 DOWNTO 0);
       recfce       : out    bit_vector(7 DOWNTO 0));
END fce1;

ARCHITECTURE behv OF fce1 IS

  COMPONENT faultfsm1
    PORT (
      clock        : IN  bit;
      reset        : IN  bit;
      rec_lt96     : IN  bit;           -- REC, <96, ok
      rec_ge96     : IN  bit;           -- REC, >=96, warning
      rec_ge128    : IN  bit;           -- REC, >=128, errorpassive
      tec_lt96     : IN  bit;           -- TEC, <96, ok
      tec_ge96     : IN  bit;           -- TEC, >=96, warning
      tec_ge128    : IN  bit;           -- TEC, >=128, errorpassive
      tec_ge256    : IN  bit;           -- TEC, =256, busoff
      erb_eq128    : IN  bit;           -- ERB, Busoff beenden (128*11)
      resetcount   : OUT bit;           -- REC,TEC,ERB
      erroractive  : OUT bit;           -- s.o.
      errorpassive : OUT bit;           --  "
      busoff       : OUT bit;           --  "
      warnsig      : OUT bit;
      irqsig       : OUT bit);          --  "
  END COMPONENT;

  COMPONENT rec1 
    PORT (
      reset     : IN  bit;
      clock     : IN  bit;
      inconerec : IN  bit;
      incegtrec : IN  bit;
      decrec    : IN  bit;
      rec_lt96  : OUT bit;
      rec_ge96  : OUT bit;
      rec_ge128 : OUT bit;
      reccount  : out bit_vector(7 DOWNTO 0));
  END COMPONENT;

  COMPONENT tec1
    PORT (
      reset     : IN  bit;
      clock     : IN  bit;
      incegttra : IN  bit;
      dectra    : IN  bit;
      tec_lt96  : OUT bit;
      tec_ge96  : OUT bit;
      tec_ge128 : OUT bit;
      tec_ge256 : OUT bit;
      teccount  : out bit_vector(7 DOWNTO 0));
  END COMPONENT;

  COMPONENT erbcount1
    PORT (
      clock     : IN  bit;
      reset     : IN  bit;
      elevrecb  : IN  bit;
      erb_eq128 : OUT bit);
  END COMPONENT;

  SIGNAL rec_ge96_i   : bit;
  SIGNAL rec_ge128_i  : bit;
  SIGNAL rec_lt96_i   : bit; --rec als signal wegen fehler hinzugefügt
  SIGNAL tec_lt96_i   : bit; 
  SIGNAL tec_ge96_i   : bit;
  SIGNAL tec_ge128_i  : bit;
  SIGNAL tec_ge256_i  : bit;
  SIGNAL erb_eq128_i  : bit;
  SIGNAL resetcount_i : bit;

  SIGNAL resetsig : bit;


BEGIN  -- reset von aussen und intern
  PROCESS(reset, resetcount_i)
  BEGIN
    resetsig <= reset AND resetcount_i;  -- war vor 0->1 OR
  END PROCESS;

  fsm : faultfsm1
    PORT MAP (
      clock        => clock,
      reset        => reset,
      rec_lt96     => rec_lt96_i,
      rec_ge96     => rec_ge96_i,
      rec_ge128    => rec_ge128_i,
      tec_lt96     => tec_lt96_i,
      tec_ge96     => tec_ge96_i,
      tec_ge128    => tec_ge128_i,
      tec_ge256    => tec_ge256_i,
      erb_eq128    => erb_eq128_i,
      resetcount   => resetcount_i,
      erroractive  => erroractive,
      errorpassive => errorpassive,
      busoff       => busoff,
      warnsig      => warnsig,
      irqsig       => irqsig);

  rec_count : rec1
    PORT MAP (
      reset     => resetsig,
      clock     => clock,
      inconerec => inconerec,
      incegtrec => incegtrec,
      decrec    => decrec,
      rec_lt96  => rec_lt96_i,
      rec_ge96  => rec_ge96_i,
      rec_ge128 => rec_ge128_i,
      reccount  => recfce);
  tec_count : tec1
    PORT MAP (
      reset     => resetsig,
      clock     => clock,
      incegttra => incegttra,
      dectra    => dectra,
      tec_lt96  => tec_lt96_i,
      tec_ge96  => tec_ge96_i,
      tec_ge128 => tec_ge128_i,
      tec_ge256 => tec_ge256_i,
      teccount  => tecfce);
  erb_count : erbcount1
    PORT MAP (
      clock     => clock,
      reset     => resetsig,
      elevrecb  => elevrecb,
      erb_eq128 => erb_eq128_i);
END behv;
