LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_signed.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY EEPROM93LC66IF IS
	GENERIC(RSTDEF: std_logic := '1');
	PORT(	rst:	IN	std_logic;
			clk:	IN	std_logic;
			cmd:	IN 	std_logic_vector(3 DOWNTO 0);
			strb:	IN	std_logic;			-- executes the given command with the given address 
			dout:	OUT std_logic_vector(15 DOWNTO 0);
			din:	IN 	std_logic_vector(15 DOWNTO 0);
			adrin	IN 	std_logic_vector(8 DOWNTO 0)
			busy:	OUT	std_logic;			-- busy bit indicates working eeprom, dout not valid

			sclk:	OUT std_logic;			-- serial clock to EEPROM
			cs:		OUT std_logic;			-- chip select, HIGH active
			mosi:	OUT std_logic;
			miso:	IN 	std_logic;
			org:	OUT std_logic);			-- memory-config =1 16 bit / =0 8 bit wordlength
END EEPROM93LC66IF;

-- comands:
-- X001		WRITE address
-- X010		READ  address
-- X011		ERASE address
-- X100		ERASE all
-- X101		WRITE all
-- X110		EWEN
-- X111		EWDS
-- X 		org =1 16bit / =0 8bit

ARCHITECTURE behaviour OF EEPROM93LC66IF IS

   	TYPE tstate IS (INIT, IDLE);

   	SIGNAL state:		tstate;

BEGIN

	main: PROCESS(rst, clk) IS
		SIGNAL serialOut: 	std_logic_vector(26 DOWNTO 0);

	BEGIN
		IF rst = RSTDEF THEN
			dout <= (others => '0');
			busy <= '0';

			sclk <= '0';
			cs <= '0';
			org <= '0';
			serialOut <= (others => '0');

			state <= INIT;
		ELSIF rising_edge(clk) THEN
			CASE state IS
				WHEN INIT =>

			END CASE;
		END IF;

	END PROCESS;

   mosi <= serialOut(serialOut'LEFT);


END behaviour;