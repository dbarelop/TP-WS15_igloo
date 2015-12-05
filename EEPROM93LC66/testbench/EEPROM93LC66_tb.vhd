LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY EEPROM93LC66_tb IS
   -- empty
END EEPROM93LC66_tb;

ARCHITECTURE verhalten OF EEPROM93LC66_tb IS

   CONSTANT RSTDEF: std_logic := '0';
   CONSTANT FRQDEF: natural   := 1e6;
   CONSTANT tcyc:   time      := 1 sec / FRQDEF;

   COMPONENT EEPROM93LC66
      PORT(sclk: IN  std_logic;  -- serial clock input
           cs:   IN  std_logic;  -- chip select, low active
           din:  IN  std_logic;  -- serial data input
           dout: OUT std_logic; -- serial data output
		   org:  IN std_logic); -- 8 or 16 bit
   END COMPONENT;

   --SIGNAL rst:  std_logic := RSTDEF;
   --SIGNAL clk:  std_logic := '0';
   SIGNAL cs:   std_logic := '0';
   SIGNAL sclk: std_logic := '0';
   SIGNAL miso: std_logic := '0';
   SIGNAL mosi: std_logic := '0';
   SIGNAL org: std_logic := '0';

   SIGNAL serIN: std_logic_vector(15 DOWNTO 0) := (others => '0');

BEGIN

   --rst <= RSTDEF, NOT RSTDEF AFTER 5 us;
--   clk <= NOT clk AFTER tcyc/2;

   u1: EEPROM93LC66
   PORT MAP(sclk => sclk,
            cs   => cs,
            din  => mosi,
            dout => miso,
			org => org);

    serialIn: PROCESS (sclk) IS

	BEGIN
		IF falling_edge(sclk) THEN
			serIN <= serIN(14 DOWNTO 0) & miso;
		END IF;

	END PROCESS;

	p1: PROCESS
		PROCEDURE spi_write (opcode: std_logic_vector; address: std_logic_vector;
							 data: std_logic_vector; clkcycl: integer) IS
			VARIABLE cnt : integer := 0;
			VARIABLE serialOut: std_logic_vector(clkcycl - 2 DOWNTO 0);
		BEGIN
			serialOut := (opcode & address & data);

			cs <= '1';
			WAIT FOR tcyc;
			sclk <= '1';
			WAIT FOR tcyc;
			sclk <= '0';
			WAIT FOR tcyc;
			mosi <= '1';
			sclk <= '1';
			WAIT FOR tcyc;
			sclk <= '0';
			WAIT FOR tcyc;
			
			FOR cnt IN clkcycl - 2 DOWNTO 0 LOOP
				mosi <= serialOut(serialOut'left);
				serialOut := serialOut(serialOut'left - 1 DOWNTO 0)  & '0';
				sclk <= '1';
				WAIT FOR tcyc;
				sclk <= '0';
				WAIT FOR tcyc;
			END LOOP;

			mosi <= '0';
			cs <= '0';
			WAIT FOR tcyc;
			cs <= '1';
			IF miso /= '1' THEN
				WAIT UNTIL miso = '1';
			END IF;
			cs <= '0';
			WAIT FOR 2*tcyc;
		END PROCEDURE;
		
	BEGIN
		-- EWEN
		spi_write("00", "110000000", "", 12);
		-- write 8 bit
		spi_write("01", "000000000", "10101010", 20);
		-- read 8 bit
		spi_write("10", "000000000", "00000000", 20);
		assert serIN(7 DOWNTO 0) = "10101010" report "8bit write / read failed";
		-- EWDS
		spi_write("00", "000000000", "", 12);
		-- write 8 bit
		spi_write("01", "000000000", "01010101", 20);
		-- read 8 bit
		spi_write("10", "000000000", "00000000", 20);
		assert serIN(7 DOWNTO 0) = "10101010" report "write protection failed";
		-- erase 8 bit with EWDS
		spi_write("11", "000000000", "", 12);
		-- read 8 bit
		spi_write("10", "000000000", "00000000", 20);
		assert serIN(7 DOWNTO 0) = "10101010" report "erase protection failed";
		-- ERAL 8 bit with EWDS
		spi_write("00", "100000000", "", 12);
		-- read 8 bit
		spi_write("10", "000000000", "00000000", 20);
		assert serIN(7 DOWNTO 0) = "10101010" report "ERAL protection failed";
		-- EWEN
		spi_write("00", "110000000", "", 12);
		-- ERAL 8 bit with EWEN
		spi_write("00", "100000000", "", 12);
		-- read 8 bit
		spi_write("10", "000000000", "00000000", 20);
		assert serIN(7 DOWNTO 0) = "11111111" report "ERAL failed";

		-- EWEN
		spi_write("00", "110000000", "", 12);
		-- write 8 bit
		spi_write("01", "111110000", "11111010", 20);
		-- read 8 bit
		spi_write("10", "111110000", "00000000", 20);
		assert serIN(7 DOWNTO 0) = "11111010" report "8bit write / read failed";
		-- write 8 bit
		spi_write("01", "000011111", "10101111", 20);
		-- read 8 bit
		spi_write("10", "000011111", "00000000", 20);
		assert serIN(7 DOWNTO 0) = "10101111" report "8bit write / read failed";
		-- ERASE 8 bit
		spi_write("11", "111110000", "", 12);
		-- read 8 bit
		spi_write("10", "111110000", "00000000", 20);
		assert serIN(7 DOWNTO 0) = "11111111" report "ERASE failed";
		-- read 8 bit
		spi_write("10", "000011111", "00000000", 20);
		assert serIN(7 DOWNTO 0) = "10101111" report "ERASED all!?";

		-- WRAL 8 bit
		spi_write("00", "010000000", "11001100", 20);
		-- read 8 bit
		spi_write("10", "011111111", "00000000", 20);
		assert serIN(7 DOWNTO 0) = "11001100" report "WRAL fail1";
		-- read 8 bit
		spi_write("10", "000000000", "00000000", 20);
		assert serIN(7 DOWNTO 0) = "11001100" report "WRAL fail2";
		-- read 8 bit
		spi_write("10", "111111111", "00000000", 20);
		assert serIN(7 DOWNTO 0) = "11001100" report "WRAL fail3";


		-- =====================
		-- 16 BIT
		-- =====================

		org <= '1';
		-- ERAL 16 bit
		spi_write("00", "10000000", "", 11);
		-- write 16 bit
		spi_write("01", "00000000", "1010101000000000", 27);
		-- read 16 bit
		spi_write("10", "00000000", "0000000000000000", 27);
		assert serIN = "1010101000000000" report "16bit write / read failed";

		-- WRAL 16 bit
		spi_write("00", "01000000", "1100110011110000", 27);
		-- read 16 bit
		spi_write("10", "01010101", "0000000000000000", 27);
		assert serIN = "1100110011110000" report "16bit WRAL failed";

		-- =====================
		-- 8 BIT
		-- =====================

		org <= '0';
		-- read 8 bit
		spi_write("10", "011111110", "00000000", 20);
		assert serIN(7 DOWNTO 0) = "11001100" report "8bit read failed";
		-- read 8 bit
		spi_write("10", "011111111", "00000000", 20);
		assert serIN(7 DOWNTO 0) = "11110000" report "8bit read failed";

		-- =====================
		-- continous reading
		-- =====================
		-- ERAL 8 bit
		spi_write("00", "100000000", "", 12);
		-- =====================
		-- 16 BIT
		-- =====================
		org <= '1';
		-- WRAL 16 bit
		spi_write("00", "01000000", "1100110011110000", 27);
		-- =====================
		-- 8 BIT
		-- =====================
		org <= '0';
		-- read 8 bit - continious
		spi_write("10", "011111110", "0000000000000000", 28);
		assert serIN = "1100110011110000" report "8bit continious read failed";

		-- =====================
		-- 16 BIT
		-- =====================
		org <= '1';
		-- read 16 bit - continious
		spi_write("10", "11111110", "00000000000000000000000000000000", 43);
		-- first 16 bits cant be checked :(
		assert serIN = "1100110011110000" report "16bit continious read failed";
      
      	REPORT "all tests done..." SEVERITY note;
		WAIT;


	END PROCESS;

END verhalten;