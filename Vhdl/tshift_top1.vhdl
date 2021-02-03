-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                         
-------------------------------------------------------------------------------
-- TSHIFT: Sendeschieberegister (TOP-Level!). Zur Synthese Optimierung
-- Instanziierung von 103 Registern.
-- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.

ENTITY tshiftreg1 IS
  PORT (
    clock       : IN  bit;
    mesin       : IN  bit_vector(102 DOWNTO 0);
    activ       : IN  bit;              -- MACFSM: actvtsft, llc:actvtsftllc
    reset       : IN  bit;              -- MAC: reset or MACFSM: resetsft
    load        : IN  bit;              -- llc: load
    shift       : IN  bit;              -- MACFSM: tshift
    extended    : IN  bit;              -- IOCPU
    bitout      : OUT bit;              -- stuff, biterrordetect
    crc_out_bit : OUT bit);             -- tcrc
END tshiftreg1;

ARCHITECTURE behv OF tshiftreg1 IS
  COMPONENT tshift_cell1                 -- Eins der 103 Register
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
  SIGNAL reset_i  : bit;
  SIGNAL load_reg : bit;
  SIGNAL q_i      : bit_vector(102 DOWNTO 0);
  SIGNAL zero     : bit;
  SIGNAL bitout_i : bit;
  SIGNAL enable_i : bit;
  
BEGIN  -- behv
  load_reg    <= load;                  -- intern: laden Register
  zero        <= '0';                   -- 0- input
  -- bitout, je nachdem, basic: 82 extended: 102
  bitout      <= (bitout_i AND extended) OR (q_i(82) AND (NOT extended));
  -- ebenso beim crc: basic: 67, extended 87, crc wird mit bit, das erst 15
  -- Zeiten später kommt gefüttert, wg crc-änderung
  crc_out_bit <= (q_i(87) AND extended) OR (q_i(67) AND (NOT extended));
  reset_i <= reset;
-------------------------------------------------------------------------------  
  los : PROCESS (clock)
    VARIABLE edged : bit;
  BEGIN  -- PROCESS los
    IF clock'event AND clock = '0' THEN 
      IF reset = '0' THEN               -- synchroner reset                         
        edged   := '0';                 -- normalerweise active high
        enable_i <= '0'; 
      ELSE
        IF activ = '1' THEN
          IF edged = '0' THEN           -- Flanke?
            edged := '1';               -- jetzt war eine
            IF shift = '1' OR load = '1' THEN
              enable_i <= '1';           -- shift oder load sorgen für
            ELSE              -- aktivierung der register
              enable_i <= '0';
            END IF;
          ELSE
            enable_i <= '0'; 
            edged := '1';               -- immmer noch pos. Flanke
          END IF;
        ELSE
          enable_i <= '0';
          edged   := '0';               -- jetzt war activ runter
        END IF;
      END IF;
    END IF;
  END PROCESS los;
-------------------------------------------------------------------------------
-- oberstes Register (Ausgang bitout_i)
  topreg : tshift_cell1                  -- Nr 102
    PORT MAP (
      enable => enable_i,
      preload => mesin(102),
      clock   => clock,
      reset   => reset_i,
      load    => load_reg,
      input   => q_i(101),
      q       => bitout_i);
-- mittlere Register:
  directregs : FOR i IN 101 DOWNTO 1 GENERATE
    reg_i : tshift_cell1
      PORT MAP (
        enable => enable_i,
        preload => mesin(i),
        clock   => clock,
        reset   => reset_i,
        load    => load_reg,
        input   => q_i(i-1),
        q       => q_i(i));
  END GENERATE directregs;
-- unterstes Register, null als eingang
  bottom_reg : tshift_cell1              -- Nr. 0
    PORT MAP (
      enable => enable_i,
      preload => mesin(0),
      clock   => clock,
      reset   => reset_i,
      load    => load_reg,
      input   => zero,
      q       => q_i(0));
END behv;
