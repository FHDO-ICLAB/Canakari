-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell 
--                                     Diplomarbeit 
-------------------------------------------------------------------------------
--                            Datei: sum.vhd
--                     Beschreibung: arithmetische Einheit für die FSM
-------------------------------------------------------------------------------

ENTITY sum1 IS
  PORT(count              : IN  integer RANGE 0 TO 15;  -- timecount
       tseg1org           : IN  integer RANGE 0 TO 7;   -- 5(6) IOCPU, genreg.
       tseg1mpl           : IN  integer RANGE 0 TO 31;  -- 5(6) tseg_reg
       tseg2              : IN  integer RANGE 0 TO 7;   -- 4(5) IOCPU, genreg
       sjw                : IN  integer RANGE 0 TO 7;  -- IOCPU, genreg
       notnull            : OUT bit;    -- fsm
       gtsjwp1            : OUT bit;    -- fsm
       gttseg1p1          : OUT bit;    -- fsm
       cpsgetseg1ptseg2p2 : OUT bit;    -- fsm
       cetseg1ptseg2p1    : OUT bit;    -- fsm
       countesmpltime     : OUT bit;    -- fsm
       tseg1p1psjw        : OUT integer RANGE 0 TO 31;  -- tseg_reg
       tseg1pcount        : OUT integer RANGE 0 TO 31);  -- tseg_reg
END sum1;
-------------------------------------------------------------------------------
ARCHITECTURE behv OF sum1 IS
  SIGNAL tseg1m1       : integer RANGE 0 TO 7;
  SIGNAL tseg1p1mpl    : integer RANGE 0 TO 31;
  SIGNAL tseg1p1org    : integer RANGE 0 TO 15;
  SIGNAL sjwp1         : integer RANGE 0 TO 15;
  SIGNAL countpsjw     : integer RANGE 0 TO 31;
  SIGNAL tseg1ptseg2p1 : integer RANGE 0 TO 31;
  SIGNAL tseg1ptseg2p2 : integer RANGE 0 TO 31;
-------------------------------------------------------------------------------  
BEGIN
  PROCESS(tseg1mpl)
  BEGIN
    tseg1p1mpl <= tseg1mpl+1;
  END PROCESS;
-------------------------------------------------------------------------------
  PROCESS(tseg1org)
  BEGIN
    tseg1p1org <= tseg1org+1;
  END PROCESS;
-------------------------------------------------------------------------------
  PROCESS(tseg1org)
  BEGIN
    IF(tseg1org > 0) THEN
      tseg1m1 <= tseg1org-1;
    ELSE
      tseg1m1 <= 0;
    END IF;
  END PROCESS;
-------------------------------------------------------------------------------
  PROCESS(sjw)
  BEGIN
    sjwp1 <= sjw + 1;
  END PROCESS;
-------------------------------------------------------------------------------
  PROCESS(count, sjw)
  BEGIN
    countpsjw <= count+sjw;
  END PROCESS;
-------------------------------------------------------------------------------
  PROCESS(tseg1p1mpl, tseg2)
  BEGIN
    tseg1ptseg2p1 <= tseg1p1mpl+tseg2;
  END PROCESS;
-------------------------------------------------------------------------------
  PROCESS(tseg1ptseg2p1, tseg1ptseg2p2)
  BEGIN
    tseg1ptseg2p2 <= tseg1ptseg2p1+1;
  END PROCESS;
-------------------------------------------------------------------------------
  PROCESS(tseg1m1, count)
  BEGIN
    tseg1pcount <= tseg1m1+count;
  END PROCESS;
-------------------------------------------------------------------------------
  PROCESS(tseg1p1org, sjw)
  BEGIN
    tseg1p1psjw <= tseg1p1org+sjw;
  END PROCESS;
-------------------------------------------------------------------------------
  PROCESS(count)
  BEGIN
    IF(count /= 0) THEN
      notnull <= '1';
    ELSE
      notnull <= '0';
    END IF;
  END PROCESS;
-------------------------------------------------------------------------------
  PROCESS(count, sjwp1)
  BEGIN
    IF (count > sjwp1) THEN
      gtsjwp1 <= '1';
    ELSE
      gtsjwp1 <= '0';
    END IF;
  END PROCESS;
-------------------------------------------------------------------------------
  PROCESS(count, tseg1p1mpl)
  BEGIN
    IF(count > tseg1p1mpl) THEN
      gttseg1p1 <= '1';
    ELSE
      gttseg1p1 <= '0';
    END IF;
  END PROCESS;
-------------------------------------------------------------------------------
  PROCESS(countpsjw, tseg1ptseg2p2)
  BEGIN
    IF(countpsjw >= tseg1ptseg2p2) THEN
      cpsgetseg1ptseg2p2 <= '1';
    ELSE
      cpsgetseg1ptseg2p2 <= '0';
    END IF;
  END PROCESS;
-------------------------------------------------------------------------------
  PROCESS(count, tseg1ptseg2p1)
  BEGIN
    IF(count = tseg1ptseg2p1) THEN
      cetseg1ptseg2p1 <= '1';
    ELSE
      cetseg1ptseg2p1 <= '0';
    END IF;
  END PROCESS;
-------------------------------------------------------------------------------
  PROCESS(count, tseg1p1mpl)
  BEGIN
    IF(count = tseg1p1mpl) THEN
      countesmpltime <= '1';
    ELSE
      countesmpltime <= '0';
    END IF;
  END PROCESS;
END;
