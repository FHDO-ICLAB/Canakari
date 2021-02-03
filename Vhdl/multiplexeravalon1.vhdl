-------------------------------------------------------------------------------
--                                  CANAKARI CAN Modell                     
--                                     Diplomarbeit                    
-------------------------------------------------------------------------------
--                            Datei: multiplexavalon.vhd
--                     Beschreibung: Adressmultiplexer
-------------------------------------------------------------------------------
-- Unterteilung in Multiplexer: CPU liest: read_mux
-- und Demux, CPU schreibt: writedemux
-- sonst nur Struktur
-- write_demultiplexer: write_demux
-- read_multiplexer: read_mux
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_misc.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;
LIBRARY synopsys;
USE synopsys.attributes.ALL;

ENTITY multiplexer1 IS
  GENERIC (
      system_id : bit_vector(15 DOWNTO 0) );    -- HW-ID

  PORT( readdata    : OUT std_logic_vector(15 DOWNTO 0);
--        clock   : in  bit;
        writedata   : in  std_logic_vector(15 DOWNTO 0);
        address : IN    bit_vector(4 DOWNTO 0);
        cs      : in  std_logic;
        read_n  : in  std_logic;
        write_n : in  std_logic;
-- Ausänge der Register (CPU-Read-cycle)
        preregr : IN    bit_vector(15 DOWNTO 0);  --prescale register
        genregr : IN    bit_vector(15 DOWNTO 0);  --general register
        intregr : IN    bit_vector(15 DOWNTO 0);  --Interrupt register
        traconr : IN    bit_vector(15 DOWNTO 0);  --transmit message control register
        traar1r : IN    bit_vector(15 DOWNTO 0);  --arbitration Bits 28 - 13
        traar2r : IN    bit_vector(15 DOWNTO 0);  --arbitration Bits 12 - 0 
        trad01r : IN    bit_vector(15 DOWNTO 0);  --data0 + data1
        trad23r : IN    bit_vector(15 DOWNTO 0);  --data2 + data3
        trad45r : IN    bit_vector(15 DOWNTO 0);  --data4 + data5
        trad67r : IN    bit_vector(15 DOWNTO 0);  --data6 + data7
        recconr : IN    bit_vector(15 DOWNTO 0);  --receive message control register
        accmask1r : IN    bit_vector(15 DOWNTO 0);  -- Acceptance Mask Register1
        accmask2r : IN    bit_vector(15 DOWNTO 0);  -- Acceptance Mask Register2
        recar1r : IN    bit_vector(15 DOWNTO 0);  --arbitration Bits 28 - 13
        recar2r : IN    bit_vector(15 DOWNTO 0);  --arbitration Bits 12 - 0 
        recd01r : IN    bit_vector(15 DOWNTO 0);  --data0 + data1
        recd23r : IN    bit_vector(15 DOWNTO 0);  --data2 + data3
        recd45r : IN    bit_vector(15 DOWNTO 0);  --data4 + data5
        recd67r : IN    bit_vector(15 DOWNTO 0);  --data6 + data7
        fehlregr : IN   bit_vector(15 DOWNTO 0);
        regbus  : OUT   bit_vector(15 DOWNTO 0);  -- Interner Bus
-- Aktivierungssignale (CPU-write-cycle)
        presca  : OUT   bit;
        genrega : OUT   bit;  -- activate general register
        intrega : OUT   bit;  -- activate Interrupt register 
        tracona : OUT   bit;  -- activate transmit message control register
        traar1a : OUT   bit;  -- activate arbitration Bits 28 - 13
        traar2a : OUT   bit;  -- activate arbitration Bits 12 - 0 
        trad01a : OUT   bit;  -- activate data0 + data1
        trad23a : OUT   bit;  -- activate data2 + data3
        trad45a : OUT   bit;  -- activate data4 + data5
        trad67a : OUT   bit;  -- activate data6 + data7
        reccona : OUT   bit;  -- activate receive message control register
        recar1a : OUT   bit;  -- activate arbitration Bits 28 - 13w
        recar2a : OUT   bit;  -- activate arbitration Bits 12 - 0 + 3 Bits reserved
        accmask1a : OUT  bit; -- activate Acceptance Mask Register1
        accmask2a : OUT  bit); -- activate Acceptance Mask Register2
END multiplexer1;
-------------------------------------------------------------------------------
ARCHITECTURE behv OF multiplexer1 IS

  COMPONENT read_mux1
    GENERIC (
      system_id : bit_vector(15 DOWNTO 0) );    -- HW-ID
    PORT (
      address  : IN  bit_vector(4 DOWNTO 0);
      preregr  : IN  bit_vector(15 DOWNTO 0);
      genregr  : IN  bit_vector(15 DOWNTO 0);
      intregr  : IN    bit_vector(15 DOWNTO 0); 
      traconr  : IN  bit_vector(15 DOWNTO 0);
      traar1r  : IN  bit_vector(15 DOWNTO 0);
      traar2r  : IN  bit_vector(15 DOWNTO 0);
      trad01r  : IN  bit_vector(15 DOWNTO 0);
      trad23r  : IN  bit_vector(15 DOWNTO 0);
      trad45r  : IN  bit_vector(15 DOWNTO 0);
      trad67r  : IN  bit_vector(15 DOWNTO 0);
      recconr  : IN  bit_vector(15 DOWNTO 0);
      accmask1r : IN    bit_vector(15 DOWNTO 0);
      accmask2r : IN    bit_vector(15 DOWNTO 0);
      recar1r  : IN  bit_vector(15 DOWNTO 0);
      recar2r  : IN  bit_vector(15 DOWNTO 0);
      recd01r  : IN  bit_vector(15 DOWNTO 0);
      recd23r  : IN  bit_vector(15 DOWNTO 0);
      recd45r  : IN  bit_vector(15 DOWNTO 0);
      recd67r  : IN  bit_vector(15 DOWNTO 0);
      fehlregr : IN   bit_vector(15 DOWNTO 0); 
      data_out : OUT bit_vector(15 DOWNTO 0));
  END COMPONENT;
-------------------------------------------------------------------------------
  COMPONENT write_demux1
    PORT (
      address   : IN  bit_vector(4 DOWNTO 0);
      activ_in  : IN  bit;              -- Aktivierungssignal
      activ_out : OUT bit_vector(14 DOWNTO 0));  -- Aktivierungssignale Ausgang
  END COMPONENT;
-------------------------------------------------------------------------------  
  -- SIGNAL data_regin_i     : bit_vector(15 DOWNTO 0);
  SIGNAL data_regout_i       : bit_vector(15 DOWNTO 0);  -- Ausgang des gewählten
                                                         -- Registers
  SIGNAL writedata_i              : bit_vector(15 DOWNTO 0);
  SIGNAL data_tri_out        : std_logic_vector(15 DOWNTO 0);
  SIGNAL activ_i             : bit;
  SIGNAL write_sig, read_sig : std_logic;
-------------------------------------------------------------------------------
  FUNCTION bit_to_stdlogic(ARG : bit_vector(15 DOWNTO 0)) RETURN std_logic_vector IS
    VARIABLE result : std_logic_vector(15 DOWNTO 0);
    VARIABLE tmp    : bit;
  BEGIN
    result := (OTHERS => '0');
    FOR i IN ARG'range LOOP
      tmp := ARG(i);
      IF tmp = '1' THEN
        result(i) := '1';
      ELSE
        result(i) := '0';
      END IF;
    END LOOP;
    RETURN result;
  END;
-------------------------------------------------------------------------------
  FUNCTION stdlogic_to_bit(ARG : std_logic_vector(15 DOWNTO 0)) RETURN bit_vector IS
    VARIABLE result : bit_vector(15 DOWNTO 0);
    VARIABLE tmp    : std_logic;
  BEGIN
    result := (OTHERS => '0');
    FOR i IN ARG'range LOOP
      tmp := ARG(i);
      IF tmp = '1' THEN
        result(i) := '1';
      ELSE
        result(i) := '0';
      END IF;
    END LOOP;
    RETURN result;
  END;
-------------------------------------------------------------------------------
BEGIN
-------------------------------------------------------------------------------
-- Registerausgänge liegen nur von der Adresse abhängig auf dem internen Signal
-- data_out_i
-------------------------------------------------------------------------------
  read_multiplexer : read_mux1
    generic map (
      system_id => system_id)
    PORT MAP (
      address  => address,
      preregr  => preregr,
      genregr  => genregr,
      intregr  => intregr,
      traconr  => traconr,
      traar1r  => traar1r,
      traar2r  => traar2r,
      trad01r  => trad01r,
      trad23r  => trad23r,
      trad45r  => trad45r,
      trad67r  => trad67r,
      recconr  => recconr,
      accmask1r => accmask1r,
      accmask2r => accmask2r,
      recar1r  => recar1r,
      recar2r  => recar2r,
      recd01r  => recd01r,
      recd23r  => recd23r,
      recd45r  => recd45r,
      recd67r  => recd67r,
      fehlregr => fehlregr,
      data_out => data_regout_i);

-------------------------------------------------------------------------------
-- Abhängig von der Adresse wird das activ_i (intern) Signal auf die Register
-- verteilt. 
-------------------------------------------------------------------------------
  
  write_demultiplexer : write_demux1
    PORT MAP (
      address       => address,
      activ_in      => activ_i,
      activ_out(14) => intrega,
      activ_out(13) => accmask1a,
      activ_out(12) => accmask2a,
      activ_out(11) => presca,
      activ_out(10) => genrega,
      activ_out( 9) => tracona,
      activ_out( 8) => traar1a,
      activ_out( 7) => traar2a,
      activ_out( 6) => trad01a,
      activ_out( 5) => trad23a,
      activ_out( 4) => trad45a,
      activ_out( 3) => trad67a,
      activ_out( 2) => reccona,
      activ_out( 1) => recar1a,
      activ_out( 0) => recar2a);

  
-------------------------------------------------------------------------------
	-- Buszugriffslogik
-------------------------------------------------------------------------------
regbus <= writedata_i;                    -- Verbindung aller Eingänge auf regbus
readdata   <= data_tri_out;              


  read_sig  <= cs and (not read_n);         -- 1, wenn cs=1, read_n=0 
  write_sig <= cs and (not write_n);        -- 1, wenn cs=1, write_n=0

-- Tristate: CPU liest, Controller schreibt auf Datenbus
  cpu_read : PROCESS (read_sig, data_regout_i)
  BEGIN  -- PROCESS RW
    data_tri_out <= (OTHERS => '0');
    IF read_sig = '1' THEN
      data_tri_out <= bit_to_stdlogic(data_regout_i);
    ELSE
      data_tri_out <= (OTHERS => '0');
    END IF;
  END PROCESS cpu_read;

-- CPU schreibt, aktivierungssignal an write_demux leiten, die das entsprechende Register aktiviert 
-- und die Daten ueber den regbus dorthin weiterleitet
  cpu_write : PROCESS (write_sig, writedata)
  BEGIN  -- PROCESS RW
    writedata_i <= stdlogic_to_bit(writedata);
    IF write_sig = '1' THEN
      activ_i <= '1';
    ELSE
      activ_i <= '0';
    END IF;
  END PROCESS cpu_write;
END behv;
