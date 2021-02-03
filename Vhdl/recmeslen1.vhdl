-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell
--                                     Diplomarbeit
-------------------------------------------------------------------------------
--                            Datei: recmeslen.vhd
--                     Beschreibung: reception data length register
-------------------------------------------------------------------------------
-- Ermittelt tatsächliche Empfangs-Datenlänge in Byte (rmlb), d.h. bei RTR
-- Rahmen ist rmlb immer 0 unabhängig vom DLC-Feld
-- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;
-- reset von mac.vhdl:
-- resrmlensig<=reset(extern) or resrmlen(MACFSM);
--> auf neg. clock flanke

ENTITY recmeslen1 IS
  PORT(clock    : IN  bit;                      -- voll
       activ    : IN  bit;                      -- macfsm: actvrmlen
       reset    : IN  bit;                      -- macfsm: resrmlen; reset_mac
       setrmlen : IN  integer RANGE 0 TO 7;     -- macfsm, setrmleno
       rmlb     : OUT bit_vector(3 DOWNTO 0));  -- rmlen in Byte (neu)

END recmeslen1;

ARCHITECTURE behv OF recmeslen1 IS
  SIGNAL setrmlen_reg : integer RANGE 0 TO 7;
  SIGNAL rmlb_reg     : bit_vector(3 DOWNTO 0);
BEGIN
  PROCESS(clock)
    VARIABLE edged : bit;                  -- Flankenmerker, deglitch
  BEGIN
    IF (clock'event AND clock = '1') THEN  -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
      IF (reset = '0' ) THEN               -- synchroner Reset
        --setrmlen_reg <= 0;                 --
        rmlb_reg     <= "0000";
        edged        := '0';
      ELSE
      IF activ = '1' THEN
        IF edged = '0' THEN
          edged := '1';                    -- Flanke merken
          IF (setrmlen_reg = 1) THEN       -- Bit#0 setzen
            rmlb_reg(0) <= '1';
          ELSIF(setrmlen_reg = 2) THEN     -- Bit#1 setzen
            rmlb_reg(1) <= '1';
          ELSIF(setrmlen_reg = 3) THEN     -- Bit#2 setzen
            rmlb_reg(2) <= '1';
          ELSIF(setrmlen_reg = 4) THEN     -- Bit#3 setzen
            rmlb_reg(3) <= '1';
          END IF;
        ELSE
          edged := '1';                    -- Flanke nicht gewechselt
        END IF;
      ELSE
        edged := '0';                      -- activ=0, Flankenmerker 0
      END IF;
    END IF;
  END IF;
    --rmlb         <= rmlb_reg;              -- raus damit, 
    --setrmlen_reg <= setrmlen;              -- Beer: Zuweisung außerhalb des if-Blocks eines getakteten Prozesses 
                                             --       wurden außerhalb des Prozesses platziert.
  END PROCESS;
  
  rmlb         <= rmlb_reg;              -- Beer
  setrmlen_reg <= setrmlen;
END behv;
