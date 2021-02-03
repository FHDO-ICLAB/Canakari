-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell 
--                                     Diplomarbeit 
-------------------------------------------------------------------------------
--                            Datei: edge.vhd
--                     Beschreibung: Flip Flop
-------------------------------------------------------------------------------
-- �nderung: buf neu, um tats�chlich eine ganze Bitzeit und nicht nur eine
-- Taktflanke zu verz�gern.- Ist vor Einbau des Prescalers nicht aufgefallen
-- synchroner Reset
-- DW 2005.06.21 Prescale Enable eingef�gt

-- | Leduc | 12.02.2020 | Added Changes done in Verilog Triplication Files
  
ENTITY edgepuffer1 IS
  PORT(clock  : IN  bit;
       Prescale_EN : IN  bit;           -- DW 2005.06.21 Prescale Enable
       reset  : IN  bit;
       rx     : IN  bit;                -- aussen
       puffer : OUT bit);               -- smpldbit_reg
END edgepuffer1;

ARCHITECTURE behv OF edgepuffer1 IS

SIGNAL buf : bit;
  
BEGIN

puffer <= buf;  
  
  PROCESS(clock, reset)
  BEGIN
    IF(reset = '0') THEN
      buf    <= '0';
    ELSIF(clock'event AND clock = '1') THEN
      IF Prescale_EN = '1' THEN           -- DW 2005.06.21 Prescale Enable eingef�gt
        buf    <= rx;                     -- speichern f�r n�chstes
      END IF;
    END IF;
  END PROCESS;
END behv;
