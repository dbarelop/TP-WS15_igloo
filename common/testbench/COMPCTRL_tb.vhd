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
				 uartRd:	OUT std_logic; 						-- indicates value was read from controller
				 uartout:   OUT std_logic_vector(7 DOWNTO 0);
				 uartTx:	OUT std_logic;
				 
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
				uartTx => uartTx,
				busy => busy
			);
			
	--test: PROCESS IS
	--
	--BEGIN
	--	
	--	
	--END PROCESS;
	
	rst <= RSTDEF, NOT RSTDEF AFTER 1 us;
	clk <= NOT clk AFTER 10 ns;

END behaviour;