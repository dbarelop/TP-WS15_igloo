


PROCEDURE write (data: std_logic_vector; address: std_logic_vector)
	CONSTANT oppcode: std_logic_vector(1 DOWNTO 0) = "01";
BEGIN
	WAIT UNTIL clk'EVENT AND clk='1'
	spi_write(oppcode & address & data);
END PROCEDURE;

PROCEDURE delete (address: std_logic_vector) IS
	CONSTANT oppcode: std_logic_vector(1 DOWNTO 0) = "11";
BEGIN
	WAIT UNTIL clk'EVENT AND clk='1'
	spi_write(oppcode & address);
END PROCEDURE;

PROCEDURE delete_all IS
	CONSTANT oppcode: std_logic_vector(1 DOWNTO 0) = "00";
	CONSTANT address: std_logic_vector(1 DOWNTO 0) = "10";
BEGIN
	WAIT UNTIL clk'EVENT AND clk='1'
	spi_write(oppcode & address);
END PROCEDURE;


	
PROCEDURE spi_write (data: std_logic_vector) IS
BEGIN
	mosi <= '1';
	sclk <= '1';
	WAIT FOR tcyc;
	sclk <= '0';
	WAIT FOR tcyc;
	
	FOR i IN data LOOP
		mosi <= i;
		sclk <= '1';
		WAIT FOR tcyc;
		sclk <= '0';
		WAIT FOR tcyc;
	END LOOP;
END PROCEDURE;

PROCEDURE spi_read (VARIABLE data: out std_logic_vector(15 DOWNTO 0)) IS
	--VARIABLE reg: std_logic_vector(15 DOWNTO 0);
BEGIN
	FOR i IN data data
		WAIT FOR tcyc;	
		sclk <= '1';
		WAIT FOR tcyc;
		sclk <= '0';
		reg <= reg(reg'LEFT-1 DOWNTO reg'RIGHT) & miso;		
	END LOOP;
END PROCEDURE;