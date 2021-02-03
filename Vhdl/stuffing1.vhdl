-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell
--                                     Diplomarbeit
-------------------------------------------------------------------------------
--                            Datei: stuff.vhd
--                     Beschreibung: Stuffing Unit
-------------------------------------------------------------------------------
-- Sendestuffing
-- reset:
-- mac.vhdl: resetstfsig<=reset(extern) or resettra (llc) or resetstf;(MACFSM)
--> auf neg. clock flanke
-- direct: Stuffing abschalten (Error Flag etc.)
-- setdom, setrec: dominantes, rezessives Bit unabhängig von bitin
-- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;

ENTITY stuffing1 IS
  PORT( clock  : IN  bit;
        bitin  : IN  bit;               --*
        activ  : IN  bit;               -- MACFSM: actvtstf
        reset  : IN  bit;               -- resetstfsig, s.o
        direct : IN  bit;               -- MACFSM: actvtdct
        setdom : IN  bit;               -- MACFSM: setbdom
        setrec : IN  bit;               -- MACFSM: setbrec
        bitout : OUT bit;               -- bitout, aussen
        stuff  : OUT bit);              -- MACFSM, stufft
END stuffing1;
-- *bitin: mal aus tshift (wenn crc_shft_out(MACFSM)0), oder aus rcrc-register
-- (wenn crc_shft_out 1), neu: tcrc wird sendeschieberegister.
ARCHITECTURE behv OF stuffing1 IS
-------------------------------------------------------------------------------
BEGIN
  PROCESS(reset, clock)
    VARIABLE count : integer RANGE 0 TO 7;  -- Zähler
    VARIABLE buf   : bit;               -- aktuelles Bit
    VARIABLE edged : bit;               -- Flankenmerker
  BEGIN
    IF clock'event AND clock = '1' THEN  -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
     IF reset = '0' THEN               
           count  := 0;
           buf    := '0';
           bitout <= '1';
           stuff  <= '0';
           edged  := '0';
     ELSE  
          IF activ = '1' THEN
            IF edged = '0' THEN             -- war schon ?
              edged := '1';                 -- es war eine pos. active flanke
              IF direct = '1' THEN          -- nicht zählen
                bitout <= bitin;
                stuff  <= '0';              -- kein stuffing
              ELSIF setdom = '1' THEN       -- Dominantes Bit senden
                bitout <= '0';
                stuff  <= '0';              -- kein error
              ELSIF setrec = '1' THEN       -- rezessives Bit senden
                bitout <= '1';
                stuff  <= '0';              -- kein stuffing
              ELSIF count = 0 OR (bitin /= buf AND count /= 5) THEN
                buf    := bitin;            -- erstes Bit merken, count=0
                count  := 1;                -- erstes Bit, deshalb 1
                bitout <= bitin;            -- durchschalten
                stuff  <= '0';              -- kein stuffing
              ELSIF bitin = buf AND count /= 5 THEN
                count  := count+1;          -- gleiches Bit, count hoch
                bitout <= bitin;            -- durchschalten
                stuff  <= '0';              -- kein stuffing
              ELSIF count = 5 THEN          -- stufffall
                count  := 1;                -- zähler auf 1, stuffbit ist 1.
                buf    := NOT buf;          -- jetzt umgekehrte zählen
                bitout <= buf;              -- stuffbit senden
                stuff  <= '1';              -- Stufffall anzeigen
              END IF;
            ELSE
              edged := '1';                 -- noch keine neg. flanke gewesen
            END IF;
          ELSE
            edged := '0';                   -- das war die neg. flanke
          END IF;
        END IF;
     END IF;
  END PROCESS;
END;
