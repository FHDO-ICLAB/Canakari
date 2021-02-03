-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                           
-------------------------------------------------------------------------------
-- Ausgelagert aus bittiming fsm, wg. extraktion bei synthese. Latch (kein
-- clock, kein reset) für tseg-wert bei resynchronisation. Steuerbefehle (ctrl)
-- aus Bittiming FSM
-- DW 2005.06.26 Aus dem Latch wuurde ein Register, welches mit Prescle_EN tacktet.

ENTITY tseg_reg1 IS
  PORT (
    clock       : in  bit;                     --DW 2005.06.26 Clock
    reset       : in  bit;                     --DW 2005.06.26 Reset aktiv low
    ctrl        : in  bit_vector(1 downto 0);
    tseg1       : in  integer range 0 to 7;    -- IOCPU, genreg.
    tseg1pcount : in  integer range 0 to 31;   -- sum
    tseg1p1psjw : in  integer range 0 to 31;   -- sum
    tseg1mpl    : out integer range 0 to 31);  -- sum
END tseg_reg1;

ARCHITECTURE behv OF tseg_reg1 IS

begin  -- behv
-- aus dem  Latch wird ein Register 
  regs : process (Clock, Reset)
--DW 2005.06.26 Prescle_EN und Reset eingefügt
  begin  -- PROCESS Register
    if (reset = '0') then
      tseg1mpl <= 0;
    elsif (clock'event and clock = '1') then
        case ctrl is                    -- umschalten
          when "01"   => tseg1mpl <= tseg1;
          when "10"   => tseg1mpl <= tseg1pcount;
          when "11"   => tseg1mpl <= tseg1p1psjw;
          when others => null;          -- halten
        end case;
    end if;
  end process regs;
end behv;
