-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                         
-------------------------------------------------------------------------------
-- RSHIFT: Empfangschieberegister (TOP-Level). Zur Synthese Optimierung
-- Instanziierung von 103 Registern. Für nachträglichen Fastshift zwei extra
-- EIngänge. 1. setzero: Bitin wird während fastshift auf null gehalten (0
-- rein) 2. directshift: Fastshift Schiebetakt (clock_extern/2)
-- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.

ENTITY rshiftreg1 IS
  PORT (
    clock       : IN  bit;
    bitin       : IN  bit;
    activ       : IN  bit;              -- MACFSM: actvrsft
    reset       : IN  bit;              -- reset (sync)
    lcrc        : IN  bit;              -- MACFSM: lcrc
    setzero     : IN  bit;              -- fastshift: setzero
    directshift : IN  bit;              -- fastshift: directshift
    mesout_a    : OUT bit_vector(67 DOWNTO 0);  -- llc; IOCPU: data+dlc
    mesout_b    : OUT bit_vector(17 DOWNTO 0);  -- decapsulation, ext. id
    mesout_c    : OUT bit_vector(10 DOWNTO 0));  -- dcapsulation, bas. id
END rshiftreg1;
-------------------------------------------------------------------------------
ARCHITECTURE behv OF rshiftreg1 IS
  COMPONENT rshift_cell1
    PORT (
	    enable : IN bit;
      clock : IN  bit;
      reset : IN  bit;
      input : IN  bit;
      q     : OUT bit);
  END COMPONENT;
-------------------------------------------------------------------------------  
  SIGNAL activ_i : bit;
  SIGNAL bitin_i : bit;
  SIGNAL enable_i : bit;
  SIGNAL reset_i : bit;
  SIGNAL q_i     : bit_vector(102 DOWNTO 0);
-------------------------------------------------------------------------------
BEGIN  -- behv
  mesout_a <= q_i(67 DOWNTO 0);         -- Data+DLC
  mesout_b <= q_i(88 DOWNTO 71);        -- ext. id
  mesout_c <= q_i(101 DOWNTO 91);       -- bas. id
  activ_i  <= (activ AND NOT lcrc) OR directshift;  -- internes Schiebe-enable
  bitin_i  <= bitin AND setzero;        -- setzero von fastshift (schiebt 0 rein)
  reset_i  <= reset;                    -- reset für schieberegister
-------------------------------------------------------------------------------
  los : PROCESS (clock)
    VARIABLE edged : bit;
  BEGIN  -- PROCESS los
    IF clock'event AND clock = '1' THEN -- DW 2005_06_30 clock Flanke von negativ auf positiv geaendert.
      IF reset = '0' THEN               -- synchroner reset
        enable_i <= '0';                 -- normalerweise active high
        edged   := '0';                
      ELSE
        IF activ_i = '1' THEN
          IF edged = '0' THEN           -- Flanke schon gewesen?
            edged   := '1';             -- jetzt aber!
            enable_i <= '1';             -- Schiebetakt
          ELSE
            enable_i <= '0';               -- noch keine neg. Flanke
      
          END IF;
        ELSE
          edged   := '0';               -- neg. Flanke
          enable_i <= '0';               -- clock weg
        END IF;
      END IF;
    END IF;
  END PROCESS los;
-------------------------------------------------------------------------------
-- unterstes Register (hat Eingang bitin_i)
  bottom : rshift_cell1
    PORT MAP (
	  enable => enable_i,
      clock => clock,
      reset => reset_i,
      input => bitin_i,
      q     => q_i(0));
-------------------------------------------------------------------------------
-- Der Rest der Register, q(i)102 ist unbenutzt
  regs : FOR i IN 102 DOWNTO 1 GENERATE
    reg_i : rshift_cell1
      PORT MAP (
		enable => enable_i,
        clock => clock,
        reset => reset_i,
        input => q_i(i-1),
        q     => q_i(i));
  END GENERATE regs;
END behv;
