-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                       
--                                     Diplomarbeit                         
-------------------------------------------------------------------------------
-- Ausgelagerter Multiplexer für CPU-Lesezyklus, umschalten der
-- Registerausgänge auf Datenbus. Ein einfacher Multiplexer, mit Synopsys
-- Attribut dazu genötigt, einer zu sein
LIBRARY ieee, synopsys;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;
USE synopsys.attributes.ALL;

ENTITY read_mux1 IS
  GENERIC (
      system_id : bit_vector(15 DOWNTO 0) );    -- HW-ID

  PORT (
    address  : IN  bit_vector(4 DOWNTO 0);    -- aussen
    preregr  : IN  bit_vector(15 DOWNTO 0);   -- prescalereg.
    genregr  : IN  bit_vector(15 DOWNTO 0);   -- generalreg.
    intregr  : IN  bit_vector(15 DOWNTO 0);   -- interrupt register 
    traconr  : IN  bit_vector(15 DOWNTO 0);   -- transmit message ctrl. reg.
    traar1r  : IN  bit_vector(15 DOWNTO 0);   -- trans. arbit. reg.1
    traar2r  : IN  bit_vector(15 DOWNTO 0);   -- trans. arbit. reg.2
    trad01r  : IN  bit_vector(15 DOWNTO 0);   -- trans. data 1&2
    trad23r  : IN  bit_vector(15 DOWNTO 0);   -- trans. data 3&4
    trad45r  : IN  bit_vector(15 DOWNTO 0);   -- trans. data 5&6
    trad67r  : IN  bit_vector(15 DOWNTO 0);   -- trans. data 7&8
    recconr  : IN  bit_vector(15 DOWNTO 0);   -- recv. mess. ctrl. 
    accmask1r : IN    bit_vector(15 DOWNTO 0);-- Acceptance Mask Register 1
    accmask2r : IN    bit_vector(15 DOWNTO 0);-- Accpetance Mask Register 2
    recar1r  : IN  bit_vector(15 DOWNTO 0);   -- recv. arbit. 1
    recar2r  : IN  bit_vector(15 DOWNTO 0);   -- recv. arbit. 2
    recd01r  : IN  bit_vector(15 DOWNTO 0);   -- recv data 1&2
    recd23r  : IN  bit_vector(15 DOWNTO 0);   -- recv data 3&4
    recd45r  : IN  bit_vector(15 DOWNTO 0);   -- recv data 5&6
    recd67r  : IN  bit_vector(15 DOWNTO 0);   -- recv data 7&8
    fehlregr : IN  bit_vector(15 DOWNTO 0);   -- Fehlerzaehler Register TEC/REC
    data_out : OUT bit_vector(15 DOWNTO 0));  -- zum Datenbus
END read_mux1;

ARCHITECTURE behv OF read_mux1 IS

BEGIN  -- behv

-------------------------------------------------------------------------------
-- Read (CPU liest vom Controller)
-------------------------------------------------------------------------------  
  mux : PROCESS(address, preregr, genregr, intregr, traconr, traar1r,
                traar2r, trad01r, trad23r, trad45r,
                trad67r, recconr, recar1r, recar2r,
                recd01r, recd23r, recd45r, recd67r, accmask1r, accmask2r,fehlregr)
  BEGIN
    -- nächstes Attribut Synopsys VHDL Compiler Reference Manual S. 7-78
    CASE address IS                     -- synopsys infer_mux
      when "10100" => data_out <= system_id;
      WHEN "10011" => data_out <= fehlregr;
      WHEN "10010" => data_out <= intregr;
      WHEN "10001" => data_out <= accmask1r;
      WHEN "10000" => data_out <= accmask2r;
      WHEN "01111" => data_out <= preregr;
      WHEN "01110" => data_out <= genregr;
      WHEN "01101" => data_out <= traconr;
      WHEN "01100" => data_out <= traar1r;
      WHEN "01011" => data_out <= traar2r;
      WHEN "01010" => data_out <= trad01r;
      WHEN "01001" => data_out <= trad23r;
      WHEN "01000" => data_out <= trad45r;
      WHEN "00111" => data_out <= trad67r;
      WHEN "00110" => data_out <= recconr;
      WHEN "00101" => data_out <= recar1r;
      WHEN "00100" => data_out <= recar2r;
      WHEN "00011" => data_out <= recd01r;
      WHEN "00010" => data_out <= recd23r;
      WHEN "00001" => data_out <= recd45r;
      WHEN "00000" => data_out <= recd67r;
      WHEN OTHERS => data_out <= (OTHERS => '0');
    END CASE;
  END PROCESS mux;
END behv;
