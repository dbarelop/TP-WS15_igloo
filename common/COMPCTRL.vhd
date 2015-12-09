LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY COMPXCTRL IS
	GENERIC(RSTDEF: std_logic := '1';
			DEVICEID: std_logic_vector(3 DOWNTO 0) := "0000");
	PORT(    rst:		IN	std_logic;
			 clk:		IN	std_logic;
			 
			 uartin:	IN 	std_logic_vector(7 DOWNTO 0);
			 uartRx:	IN	std_logic;						-- indicates new byte is available
			 uartRd:	OUT std_logic; 						-- indicates value was read from controller
			 uartout:   OUT std_logic_vector(7 DOWNTO 0);
			 uartTx:	OUT std_logic;
			 
			 busy:		INOUT	std_logic					-- busy bit indicates working component
	);

END COMPXCTRL;

ARCHITECTURE behaviour OF COMPXCTRL IS

	TYPE tstate IS (IDLE, READSENDOK);
	
	SIGNAL state: tstate;
	SIGNAL dataIN: std_logic_vector(7 DOWNTO 0);

BEGIN

	main: PROCESS (clk, rst) IS

	BEGIN
		IF rst = RSTDEF THEN
			busy <= 'Z';
			uartout <= (others => 'Z');
			uartTx <= 'Z';
			uartRd <= 'Z';
			
			state <= IDLE;
		ELSIF rising_edge(clk) THEN
			IF state = IDLE AND uartRx = '1' THEN
				IF uartin(7 DOWNTO 4) = DEVICEID AND busy /= '1' THEN
					busy <= '1';
					uartRd <= '1';
					dataIN <= uartin;
					uartout <= "10101010"; -- OK message
					uartTx <= '1';
					state <= READSENDOK;
				END IF;
			ELSIF state = READSENDOK THEN
				uartRd <= 'Z';
				uartout <= (others => 'Z');
				uartTx <= 'Z';
				-- check command here
				state <= IDLE;
			END IF;
		END IF;
	END PROCESS;

END behaviour;