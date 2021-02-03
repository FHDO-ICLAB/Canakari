-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell 
--                                     Diplomarbeit 
-------------------------------------------------------------------------------
--                            Datei: genreg.vhd
--                     Beschreibung: general register
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;

ENTITY generalregister1 IS
  PORT( clk   : IN  bit;
        rst   : IN  bit;
        cpu   : IN  bit;                -- CPU wuenscht Zugriff
        can   : IN  bit;                -- controller wuenscht Zugriff
        bof   : IN  bit;                -- bus off
        era   : IN  bit;                -- error activ
        erp   : IN  bit;                -- error passive
        war   : IN  bit;                -- warning error count level
        sjw   : IN  bit_vector(2 DOWNTO 0);
        tseg1 : IN  bit_vector(2 DOWNTO 0);
        tseg2 : IN  bit_vector(2 DOWNTO 0);
        ssp   : IN  bit;                -- succesfull send processor
        srp   : IN  bit;                -- succesfull received processor
        ssc   : IN  bit;                -- succesfull send can
        src   : IN  bit;                -- succesfull received can
        rsp   : IN  bit;                -- reset/initialization processor
        reg   : OUT bit_vector(15 DOWNTO 0));  -- generalregister
END generalregister1;

ARCHITECTURE behv OF generalregister1 IS
BEGIN
  PROCESS(clk)
  BEGIN
    IF clk'event AND clk = '1' THEN
      IF rst = '0' THEN
        reg             <= "0000000010101100";
      ELSE
        reg(15)           <= bof;
        reg(14)           <= era;
        reg(13)           <= erp;
        reg(12)           <= war;
          IF can = '1' THEN
            reg(11)         <= ssc;
            reg(10)         <= src;
          ELSIF cpu = '1' THEN
            reg(11)         <= ssp;
            reg(10)         <= srp;
            reg( 9)         <= rsp;
            reg(8 DOWNTO 6) <= sjw;
            reg(5 DOWNTO 3) <= tseg1;
            reg(2 DOWNTO 0) <= tseg2;
          END IF;
      END IF;
    END IF;
  END PROCESS;
END;
