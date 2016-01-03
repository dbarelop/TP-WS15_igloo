LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY COMPXCTRL_tb IS

END COMPXCTRL_tb;

ARCHITECTURE behaviour OF COMPXCTRL_tb IS
	
	COMPONENT COMPXCTRL
		GENERIC(RSTDEF: std_logic;
				DEVICEID: std_logic_vector);
		PORT(    rst:		IN	std_logic;
				 clk:		IN	std_logic;
				 
				 uartin:	IN 	std_logic_vector(7 DOWNTO 0);
				 uartRx:	IN	std_logic;						-- indicates new byte is available
				 uartRd:	INOUT std_logic; 						-- indicates value was read from controller
				 uartout:   INOUT std_logic_vector(7 DOWNTO 0);
			 	 uartTxReady: IN std_logic;						-- indicates new byte can be send
				 uartTx:	INOUT std_logic;
				 
				 busy:		INOUT	std_logic					-- busy bit indicates working component
		);
	END COMPONENT;

	CONSTANT RSTDEF: 	std_logic := '1';
	
	SIGNAL rst:			std_logic := RSTDEF;
	SIGNAL clk:			std_logic := '0';
	SIGNAL uartin:		std_logic_vector(7 DOWNTO 0) := (others => '0');
	SIGNAL uartRx:		std_logic := '0';
	SIGNAL uartRd:		std_logic := '0';
	SIGNAL uartout:   	std_logic_vector(7 DOWNTO 0) := (others => '0');
	SIGNAL uartTx:		std_logic := '0';
	
	SIGNAL busy:		std_logic := 'L';
	
	SIGNAL serOut:		std_logic_vector(7 DOWNTO 0) := (others => '0');

BEGIN

	c1: COMPXCTRL
	GENERIC MAP(RSTDEF => RSTDEF,
				DEVICEID => "1010")
	PORT MAP(	rst => rst,
				clk => clk,
				uartin => uartin,
				uartRx => uartRx,
				uartRd => uartRd,
				uartout => uartout,
				uartTxReady => '1',
				uartTx => uartTx,
				busy => busy
			);
			
	c2: COMPXCTRL
	GENERIC MAP(RSTDEF => RSTDEF,
				DEVICEID => "0010")
	PORT MAP(	rst => rst,
				clk => clk,
				uartin => uartin,
				uartRx => uartRx,
				uartRd => uartRd,
				uartout => uartout,
				uartTxReady => '1',
				uartTx => uartTx,
				busy => busy
			);
			
	test: PROCESS IS
	
		PROCEDURE newByte(data: std_logic_vector) IS
		
		BEGIN
			IF clk /= '0' THEN
				WAIT UNTIL clk = '0';
			END IF;
			uartin <= data;
			uartRx <= '1';
			WAIT UNTIL uartRd = '1';
			WAIT UNTIL clk = '1';
			uartRx <= '0';
			WAIT UNTIL busy /= '1';
		END PROCEDURE;
	
	BEGIN
		WAIT UNTIL rst = NOT RSTDEF;
		newByte("10100101");
		newByte("00100101");
		WAIT;
		
	END PROCESS;
	
	serialOut: PROCESS(clk) IS
	
	BEGIN
		IF rising_edge(clk) AND uartTx = '1' THEN
			serOut <= uartout;
		END IF;
	END PROCESS;
	
	rst <= RSTDEF, NOT RSTDEF AFTER 10 ns;
	clk <= NOT clk AFTER 10 ns;

END behaviour;