


PROCEDURE write (data: std_logic_vector, address: std_logic_vector)
	CONSTANT oppcode: std_logic_vector(1 DOWNTO 0) = "01";
BEGIN
	WAIT UNTIL clk'EVENT AND clk='1'
	spi_write(oppcode & address & data);
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