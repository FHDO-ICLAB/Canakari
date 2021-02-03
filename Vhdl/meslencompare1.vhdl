-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                           
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- startrcrc: FSM, rcrc: Daten empfang vorbei, CRC Empfangen
-- starttcrc: FSM, wenn CRC gesendet werden muss.
-- zerointcrc: Nullen in Tranmit CRC schieben (letzte 15 Takte)
-- en_zerointcrc: von FSM, erst ab SOF erlaubt (enable)
-- rmzero: realer DLC ist 0, direkter Übergang von Arbit in CRC Empfang
-------------------------------------------------------------------------------
-- Vergleichsprinzip: Bspl.: tmlen+39 = count
-- tmlen=0: 39 = 100 111 ; 100-100=  0 (0)
-- tmlen=1: 47 = 101 111 ; 101-100=  1 (1)
-- tmlen=2: 55 = 110 111 ; 110-100= 10 (2)
-- untere Bits müssen 111 sein, obere sind tmlen (in Byte)-4
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;

ENTITY meslencompare1 IS
  PORT (
    count         : IN  integer RANGE 0 TO 127;  -- counter
    rmlen         : IN  bit_vector(3 DOWNTO 0);  -- recmeslen: rmlb
    tmlen         : IN  bit_vector(3 DOWNTO 0);  -- encapsulation
    ext_r         : IN  bit;            -- fsm_regs: rext
    ext_t         : IN  bit;            -- IOCPU, transmesconreg
    en_zerointcrc : IN  bit;            -- MACFSM
    startrcrc     : OUT bit;            -- MACFSM
    rmzero        : OUT bit;            -- MACFSM
    starttcrc     : OUT bit;            -- MACFSM
    zerointcrc    : OUT bit);           -- tcrc, Nullen nachschieben (15)
END meslencompare1;

ARCHITECTURE behv OF meslencompare1 IS
  SIGNAL count_s        : unsigned(6 DOWNTO 0);
  SIGNAL count_top_us   : unsigned(3 DOWNTO 0);
  SIGNAL count_bot_us   : unsigned(2 DOWNTO 0);
  SIGNAL tmlb19_us      : unsigned(3 DOWNTO 0);
  SIGNAL tmlb39_us      : unsigned(3 DOWNTO 0);
  SIGNAL rmlb19_us      : unsigned(3 DOWNTO 0);
  SIGNAL rmlb39_us      : unsigned(3 DOWNTO 0);
  SIGNAL tmlen_bit_us4  : unsigned(6 DOWNTO 0);
  SIGNAL tmlen_bit_us24 : unsigned(6 DOWNTO 0);
  SIGNAL zerointcrc_i   : bit;

BEGIN  -- behv
-------------------------------------------------------------------------------
-- vorbereiten für Vergleich,- Bitoptimiert
  count_s      <= conv_unsigned(count, 7);  -- von integer nach unsigned
  count_top_us <= count_s(6 DOWNTO 3);  -- aufteilen: top 4 Bit
  count_bot_us <= count_s(2 DOWNTO 0);  --     "   bottom 3 Bit
  -- 'eleganter' von bitvector to unsigned (Achtung Addition!!)
  -- für Vergleich, ob count=tmlen+dlc, count_top ist dann gleich tmlen
  tmlb19_us    <= conv_unsigned(unsigned(to_stdLogicVector(tmlen)), 4)+2;  
  tmlb39_us    <= conv_unsigned(unsigned(to_stdLogicVector(tmlen)), 4)+4;
  rmlb19_us    <= conv_unsigned(unsigned(to_stdLogicVector(rmlen)), 4)+2;
  rmlb39_us    <= conv_unsigned(unsigned(to_stdLogicVector(rmlen)), 4)+4;

  tmlen_bit_us4(6 DOWNTO 3) <= conv_unsigned(unsigned(to_stdLogicVector(tmlen)), 4);
  tmlen_bit_us4(2 DOWNTO 0) <= "011";   --100

  tmlen_bit_us24(6 DOWNTO 3) <= conv_unsigned(unsigned(to_stdLogicVector(tmlen)), 4)+2;
  tmlen_bit_us24(2 DOWNTO 0) <= "111";

  zerointcrc <= zerointcrc_i OR NOT en_zerointcrc;
-------------------------------------------------------------------------------
  set_out : PROCESS (count_top_us, count_bot_us, tmlb19_us, tmlb39_us,
                     rmlb19_us, rmlb39_us,  ext_r, ext_t, rmlen, count_s,
                     tmlen_bit_us24, tmlen_bit_us4)
  BEGIN  -- PROCESS set_out
    -- transmit crc startet bei basic an Posi: 19+tmlen
    -- bei extended 39+tmlen
    IF ((count_top_us = tmlb19_us) AND (count_bot_us = 3) AND ext_t = '0') OR
      ((count_top_us = tmlb39_us) AND (count_bot_us = 7) AND ext_t = '1') THEN
      starttcrc <= '1';
    ELSE
      starttcrc <= '0';
    END IF;
    -- receive crc startet bei gleichen Positionen (rmlen)
    IF ((count_top_us = rmlb19_us) AND (count_bot_us = 3) AND ext_r = '0') OR
      ((count_top_us = rmlb39_us) AND (count_bot_us = 7) AND ext_r = '1') THEN
      startrcrc <= '1';
    ELSE
      startrcrc <= '0';
    END IF;

    -- basic: crc startet bei 19+rmlen, Nullen also 15 vorher (4+rmlen) starten
    -- extended: crc startet 39+rmlen, Nullen also 24 vorher reinschieben (-15)
    IF (count_s > tmlen_bit_us4 AND ext_t = '0') OR
      (count_s > tmlen_bit_us24 AND ext_t = '1') THEN
      zerointcrc_i <= '0';              -- Nullen ins tcrc schieben
    ELSE
      zerointcrc_i <= '1';              -- Outbit ins tcrc schieben
    END IF;

    -- Signal für Datenversenden überspringen (reale Datenlänge ist 0)
    IF rmlen = "0000" THEN
      rmzero <= '1';
    ELSE
      rmzero <= '0';
    END IF;
  END PROCESS set_out;
END behv;
