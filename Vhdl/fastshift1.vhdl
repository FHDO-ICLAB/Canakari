-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                           
-------------------------------------------------------------------------------
-- fastshift: schnelles Schieben (ungeteilter Takt) des receive shift register,
-- um Daten immer an selbe Position zu schieben. wenn DLC=8Byte 0 mal schieben,
-- wenn DLC=1Byte 56 mal schieben. Einsparung Multiplexer in decapuslation. Ein
-- Zähler wird von 128 heruntergezählt, bis die oberen 4 Bit gleich DLC sind
-- und die unteren Null (Multiplikation 16). Es sind dann doppelt soviele 
-- Zähltakte wie Schiebetakte, pro Zähltakt wird Schiebesignal invertiert.
--  = Division /2. 8Bit=1Byte , 16/2=8
-------------------------------------------------------------------------------
-- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;

ENTITY fastshift1 IS
  PORT (
    reset       : IN  bit;
    clock       : IN  bit;              -- aussen
    activate    : IN  bit;              -- MACFSM, activatefast
    rmlb        : IN  bit_vector(3 DOWNTO 0);  -- recmeslen, Real Message
                                               -- Length, Byte
    setzero     : OUT bit;              -- rshiftreg, Nullen nachschieben
    directshift : OUT bit);             -- rshiftreg, Schiebetakt
END fastshift1;

ARCHITECTURE behv OF fastshift1 IS
  SIGNAL reset_i        : bit;
--  SIGNAL activate_i     : bit;
--  SIGNAL rmlb_i         : bit_vector(3 DOWNTO 0);
  SIGNAL directshift_i  : bit;
--  SIGNAL logic0, logic1 : bit;
  SIGNAL working        : bit;
  SIGNAL count          : integer RANGE 0 TO 128;  -- Zähler Schiebetakte (läuft abwärts)
  SIGNAL upper4count, lower4count : unsigned(3 downto 0);
  SIGNAL rmlb_us : unsigned(3 downto 0);
  SIGNAL count_us: unsigned(7 downto 0);
  
BEGIN  -- behv
--  logic0  <= '0';
--  logic1  <= '1';
  reset_i <= reset;
  setzero <= NOT working;               -- wenn aktiv, eingang rshift auf 0
  directshift <= directshift_i;

  active : PROCESS (clock)
    --VARIABLE count_us    : unsigned(7 DOWNTO 0);  -- Zähler unsigned, für conversion
    --VARIABLE upper4count : unsigned(3 DOWNTO 0);  -- obere 4 Bit Zähler
    --VARIABLE lower4count : unsigned (3 DOWNTO 0);  -- untere 4 Bit Zähler
    --VARIABLE rmlb_us     : unsigned(3 DOWNTO 0);  -- Byte Anzahl als unsigned

  BEGIN  -- PROCESS active
    --count_us    := conv_unsigned(count, 8);  -- Konvertierung des integer count
    --upper4count := count_us(7 DOWNTO 4);     -- obere 4 Bit Zähler
    --lower4count := count_us(3 DOWNTO 0);     -- untere 4 Bit Zähler
    --rmlb_us     := conv_unsigned(unsigned(to_stdLogicVector(rmlb)), 4);

    IF clock'event AND clock = '1' THEN -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
      IF reset_i = '0' THEN             -- synchronous Reset, neg. clock edge
        working       <= '0';
        count         <= 128;           -- Zähler zählt runter! Reset=alles 1
        directshift_i <= '0';
      ELSIF activate = '1' THEN         -- kurzes Signal startet!
        working <= '1';                 -- 
      ELSIF working = '1' THEN          -- runterzählen bis obere 4 Bit=DLC und
                                        -- untere 4 Bit 0 (da DLC in Byte *8
                                        -- und *2 wg. Taktflanke directshift)
        IF NOT (rmlb_us = upper4count AND lower4count = 0) THEN  -- Abbruchbedingung
          directshift_i <= NOT directshift_i;  -- taktsignal zum Schieben
          count         <= count - 1;   -- Zähler dekrementieren
        ELSE
          working <= '0';       -- Abbruchbedingung erreicht, abschalten
        END IF;
      END IF;
    END IF;
  END PROCESS active;
  
  process(count,rmlb,count_us,rmlb_us) --Beer, 2018_06_22
    begin
      count_us <= conv_unsigned(count, 8);
      upper4count  <= count_us(7 DOWNTO 4);
      lower4count <= count_us(3 DOWNTO 0);
      rmlb_us     <= conv_unsigned(unsigned(to_stdLogicVector(rmlb)), 4);
end process;
END behv;
