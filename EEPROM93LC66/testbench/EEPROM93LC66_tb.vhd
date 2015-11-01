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

BEGIN

   --rst <= RSTDEF, NOT RSTDEF AFTER 5 us;
--   clk <= NOT clk AFTER tcyc/2;

   u1: EEPROM93LC66
   PORT MAP(sclk => sclk,
            cs   => cs,
            din  => mosi,
            dout => miso,
			org => org);
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
				mosi <= serialOut(cnt);
				sclk <= '1';
				WAIT FOR tcyc;
				sclk <= '0';
				WAIT FOR tcyc;
			END LOOP;

			cs <= '0';
			WAIT FOR 2*tcyc;
		END PROCEDURE;
		
		--PROCEDURE delete (address: std_logic_vector) IS
		--	CONSTANT oppcode: std_logic_vector(1 DOWNTO 0) := "11";
		--BEGIN
		--	WAIT UNTIL clk'EVENT AND clk='1';
		--	spi_write(oppcode & address);
		--END PROCEDURE;
		--
		--PROCEDURE delete_all IS
		--	CONSTANT oppcode: std_logic_vector(1 DOWNTO 0) := "00";
		--	CONSTANT address: std_logic_vector(1 DOWNTO 0) := "10";
		--BEGIN
		--	WAIT UNTIL clk'EVENT AND clk='1';
		--	spi_write(oppcode & address);
		--END PROCEDURE;
		
		--PROCEDURE spi_read (VARIABLE data: out std_logic_vector(15 DOWNTO 0)) IS
		--	--VARIABLE reg: std_logic_vector(15 DOWNTO 0);
		--BEGIN
		--	FOR i IN data LOOP
		--		WAIT FOR tcyc;	
		--		sclk <= '1';
		--		WAIT FOR tcyc;
		--		sclk <= '0';
		--		reg <= reg(reg'LEFT-1 DOWNTO reg'RIGHT) & miso;		
		--	END LOOP;
		--END PROCEDURE;
	BEGIN
		-- write 8 bit
		spi_write("01", "000000000", "10101010", 20);
	END PROCESS;

END verhalten;