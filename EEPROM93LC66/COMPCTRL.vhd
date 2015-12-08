LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY COMPXCTRL IS
	GENERIC(RSTDEF: std_logic := '1');
	PORT(    rst:		IN	std_logic;
			 clk:		IN	std_logic;
			 
			 uartin:	IN 	std_logic_vector(7 DOWNTO 0);
			 -- uartRx??
			 uartout:   OUT std_logic_vector(7 DOWNTO 0);
			 uartTx:	OUT std_logic;
			 
			 busy:		INOUT	std_logic;			-- busy bit indicates working component
	);

END COMPXCTRL;

ARCHITECTURE behaviour OF COMPXCTRL IS

	CONSTANT DEVICEID: std_logic_vector(3 DOWNTO 0) := "0000";

BEGIN

	main: PROCESS (clk, rst) IS
		IF rst = RSTDEF THEN
			busy <= 'Z';
			uartout <= (others => '0');
			uartTx <= 'Z';
		ELSIF rising_edge(clk) THEN
		
		END IF;
	END PROCESS;

END behaviour;