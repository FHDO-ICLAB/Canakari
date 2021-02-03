-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell
--                                     Diplomarbeit
-------------------------------------------------------------------------------
-- RCRC: Receive CRC, neu geschrieben zur Synthese optimierung: Instanzieerung
-- der REgister mit Generate, XOR Verknüpfung per Hand
-- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
  
ENTITY rcrc1 IS

  PORT (
    clock  : IN  bit;
    bitin  : IN  bit;                   -- destuff, bitout
    activ  : IN  bit;                   -- MACFSM, actvrcrc
    reset  : IN  bit;
    crc_ok : OUT bit);                  -- wenn Register alle 0

END rcrc1;

ARCHITECTURE behv OF rcrc1 IS
-------------------------------------------------------------------------------  
  COMPONENT rcrc_cell1
    PORT (
      enable: IN bit;
      clock : IN  bit;
      reset : IN  bit;
      input : IN  bit;
      q     : OUT bit);
  END COMPONENT;
-------------------------------------------------------------------------------  

  SIGNAL enable_i : bit;                 -- takt für das CRC-Register
  SIGNAL reset_i : bit;                 -- reset          "
  SIGNAL q_out   : bit_vector(14 DOWNTO 0);  -- Verbindungen zwischen Registern/XOR
  SIGNAL inp     : bit_vector(14 DOWNTO 0);  -- Verbindung zwischen XOR/Registern

  
BEGIN  -- behv
  reset_i <= reset;                      -- reset Register
  Flanken : PROCESS (clock)
    VARIABLE edged : bit;                -- Flankenmerkerm deglitch
  BEGIN  -- PROCESS Flanken
    IF clock'event AND clock = '0' THEN  -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
      IF reset = '0' THEN                -- synchroner Reset
        enable_i <= '1';
      ELSE
        IF activ = '1' THEN              -- Flanke merken
          IF edged = '0' THEN            --      "
            edged   := '1';
            enable_i <= '1';              -- Taktimpuls für Register
          ELSE
            edged := '1';
          END IF;
        ELSE
          edged   := '0';                -- activ=0, flankenmerker reset
          enable_i <= '0';                -- für Register
        END IF;
      END IF;
    END IF;
  END PROCESS Flanken;
-------------------------------------------------------------------------------
  is_null : PROCESS (q_out)
  BEGIN  -- PROCESS is_null, CRC Register ist null-> CRC war ok
    IF q_out(14 DOWNTO 0) = "000000000000000" THEN
      crc_ok <= '1';
    ELSE
      crc_ok <= '0';
    END IF;
  END PROCESS is_null;
-------------------------------------------------------------------------------
-- XOR Rückkopplung (q_out(14)) nach CAN-Generatorpolynom:
  inp( 0) <= bitin XOR q_out(14);
  inp( 1) <= q_out( 0);
  inp( 2) <= q_out( 1);
  inp( 3) <= q_out( 2) XOR q_out(14);
  inp( 4) <= q_out( 3) XOR q_out(14);
  inp( 5) <= q_out( 4);
  inp( 6) <= q_out( 5);
  inp( 7) <= q_out( 6) XOR q_out(14);
  inp( 8) <= q_out( 7) XOR q_out(14);
  inp( 9) <= q_out( 8);
  inp(10) <= q_out( 9) XOR q_out(14);
  inp(11) <= q_out(10);
  inp(12) <= q_out(11);
  inp(13) <= q_out(12);
  inp(14) <= q_out(13) XOR q_out(14);
-------------------------------------------------------------------------------
-- 15 Register instanziieren:
  regs : FOR i IN 14 DOWNTO 0 GENERATE
    reg_i : rcrc_cell1
      PORT MAP (
        enable => enable_i,
        clock => clock,
        reset => reset_i,
        input => inp(i),
        q     => q_out(i));
  END GENERATE regs;
END behv;
