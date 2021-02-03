-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell
--                                     Diplomarbeit
-------------------------------------------------------------------------------
-- TCRC: Transmit CRC, neu geschrieben zur Synthese optimierung: Instanziierung
-- der Register mit Generate, XOR Verknüpfung per Hand. Verschiedene Preload
-- Eingänge: crc_pre_load_ext: für IDE=1, kommt von mesin ganz oben,
-- crc_pre_load_rem (falscher Name) für Basic, kommt von weiter unten aus mesin
-- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  
ENTITY tcrc1 IS
  PORT (
    clock        : IN  bit;
    bitin        : in  bit;
    activ        : in  bit;
    reset        : in  bit;
    crc_pre_load_ext : IN  bit_vector(14 DOWNTO 0);
    crc_pre_load_rem : IN  bit_vector(14 DOWNTO 0);
    extended     : IN bit;
    load         : IN  bit;
    load_activ   : IN  bit;
    crc_shft_out : IN  bit;
    zerointcrc: IN bit;
    crc_tosend   : OUT bit);

END tcrc1;
-------------------------------------------------------------------------------
ARCHITECTURE behv OF tcrc1 IS
  COMPONENT tcrc_cell1                   -- Ein Bit des Registers
    PORT (
      enable  : IN  bit;
      preload : IN  bit;
      clock   : IN  bit;
      reset   : IN  bit;
      load    : IN  bit;
      input   : IN  bit;
      q       : OUT bit);
  END COMPONENT;
-------------------------------------------------------------------------------
  SIGNAL enable_i   : bit;
  SIGNAL reset_i   : bit;
  SIGNAL load_i    : bit;
  SIGNAL bitin_i : bit;
  SIGNAL feedback : bit;
  SIGNAL q_out : bit_vector(14 DOWNTO 0);  -- Ausgänge Register
  SIGNAL inp : bit_vector(14 DOWNTO 0);  -- Eingänge Register
  SIGNAL crc_pre_load_i : bit_vector(14 DOWNTO 0);  -- Ausgang MUX bas/ext
  SIGNAL activ_i : bit;
--  SIGNAL zeros_in : bit;
-------------------------------------------------------------------------------  
BEGIN  -- behv
  reset_i <= reset;
  
-- Multiplexer: abhängig von IDE crcreg mit unten oder oben vorladen
mux: PROCESS (extended, crc_pre_load_ext, crc_pre_load_rem)
BEGIN  -- PROCESS mux
  IF extended='1' THEN
    crc_pre_load_i <= crc_pre_load_ext;  -- extended
  ELSE
    crc_pre_load_i <= crc_pre_load_rem;  -- basic
  END IF;
END PROCESS mux;
  
-------------------------------------------------------------------------------
los: PROCESS (clock)
  VARIABLE edged : bit;                 -- Flankenmerker
BEGIN  -- PROCESS los
    IF clock'event AND clock='0' THEN   -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
      IF reset='0' THEN                 -- synchroner reset
        enable_i <= '1';
        edged:='0';
      ELSE
      IF activ_i='1' THEN
        IF edged='0' THEN               -- war schon flanke?
          edged:='1';                   -- dann aber jetzt
          enable_i <= '1';               -- Schiebesignal
        ELSE
          edged:='1';                   -- war schon!
          enable_i <= '0';               -- Signal kurz
        END IF;
      ELSE
        edged:='0';                     -- kein activ, flanke neg.
        IF load='1' AND load_activ='1' THEN
          enable_i <= '1';               -- Vorladen
        ELSE
          enable_i <= '0';
        END IF;
      END IF;
    END IF;
  END IF;
END PROCESS los;

-- crc_shft_out=1 : Register ist jetzt Sendeschieberegister, deshalb feedback 
-- auf 0 stellen. Sonst normale XOR-Rückkopplung
activ_i <= (activ AND (NOT crc_shft_out)) OR (load_activ AND crc_shft_out);
feedback <= (NOT crc_shft_out) AND q_out(14);  -- Rückführung
load_i <= load AND load_activ;
bitin_i <= (bitin OR crc_shft_out) AND zerointcrc; 
-- Nullen reinschieben (die fehlenden 15 Takte vor versendung)
-- Rückkopplung wie CRC-Generatorpolynom:
inp( 0) <= bitin_i     XOR feedback;
inp( 1) <= q_out( 0);
inp( 2) <= q_out( 1);
inp( 3) <= q_out( 2) XOR feedback;
inp( 4) <= q_out( 3) XOR feedback;
inp( 5) <= q_out( 4);
inp( 6) <= q_out( 5);
inp( 7) <= q_out( 6) XOR feedback;
inp( 8) <= q_out( 7) XOR feedback;
inp( 9) <= q_out( 8);
inp(10) <= q_out( 9) XOR feedback;
inp(11) <= q_out(10);
inp(12) <= q_out(11);
inp(13) <= q_out(12);
inp(14) <= q_out(13) XOR feedback;

crc_tosend <= q_out(14);
-- Register instanziieren:
regs:FOR i IN 14 DOWNTO 0 GENERATE
    reg_i: tcrc_cell1
      PORT MAP (
        enable  => enable_i,
        preload => crc_pre_load_i(i),
        clock   => clock,
        reset   => reset_i,
        load    => load_i,
        input   => inp(i),
        q       => q_out(i));
  END GENERATE regs;
END behv;
