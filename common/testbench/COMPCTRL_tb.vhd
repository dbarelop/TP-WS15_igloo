LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY COMPXCTRL_tb IS
	-- empty
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

	CONSTANT RSTDEF: 	std_logic 	:= '0';
	CONSTANT FRQDEF: 	natural		:= 4e6;
	CONSTANT tcyc:		time		:= 1 sec / FRQDEF;
	
	SIGNAL rst:			std_logic := RSTDEF;
	SIGNAL clk:			std_logic := '0';
	SIGNAL uartin:		std_logic_vector(7 DOWNTO 0) := (others => '0');
	SIGNAL uartRx:		std_logic := '0';
	SIGNAL uartRd:		std_logic := '0';
	SIGNAL uartout:   	std_logic_vector(7 DOWNTO 0) := (others => '0');
	SIGNAL uartTxReady:	std_logic :='0';
	SIGNAL uartTx:		std_logic := '0';
	
	SIGNAL busy:		std_logic := '0';
	
	SIGNAL serOut:		std_logic_vector(7 DOWNTO 0) := (others => '0');

BEGIN

	clk <= NOT clk AFTER tcyc/2;

	c1: COMPXCTRL
	GENERIC MAP(RSTDEF => RSTDEF,
				DEVICEID => "0000")
	PORT MAP(	rst => rst,
				clk => clk,
				uartin => uartin,
				uartRx => uartRx,
				uartRd => uartRd,
				uartout => uartout,
				uartTxReady => uartTxReady,
				uartTx => uartTx,
				busy => busy
			);
			
	test: PROCESS IS
	
		VARIABLE n_bytes: integer;

		PROCEDURE uartSendN (dataIn: std_logic_vector((n_bytes*8)-1 DOWNTO 0); result: std_logic_vector) IS
			VARIABLE dataInLength: INTEGER := dataIn'LENGTH-1;
		BEGIN
			uartin <= dataIn(dataInLength DOWNTO dataInLength-7);
			uartRx <= '1';
			WAIT UNTIL uartRd = '1';
			uartRx <= '0';
			WAIT UNTIL uartTx = '1';
			assert uartout = x"AA" report "OK message failed";
			uartTxReady <= '1';
			WAIT UNTIL uartTx = '0';
			FOR i in 1 to n_bytes-1 LOOP
				uartin <= dataIn(dataInLength-8*i DOWNTO dataInLength-8*i-7);
				uartRx <= '1';
				WAIT UNTIL uartRd = '1';
				uartRx <= '0';
				WAIT UNTIL uartRd = '0';
			END LOOP;
			IF result'LENGTH = 8 THEN
				WAIT UNTIL uartTx = '1';
				assert uartout = result report "wrong result";
			END IF;

		END PROCEDURE;
	
	BEGIN
		WAIT FOR 1 us;
		rst <= NOT RSTDEF;

		n_bytes := 1;
		uartSendN("00000000", "00000001");
		
		REPORT "all tests done..." SEVERITY note;
		WAIT;
		
	END PROCESS;

END behaviour;