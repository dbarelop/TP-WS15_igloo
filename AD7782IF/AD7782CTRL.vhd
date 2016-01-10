LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY AD7782CTRL IS
	GENERIC(RSTDEF: std_logic := '1');
	PORT( rst:			IN			std_logic;
			clk: 			IN 		std_logic;
			busy:			INOUT		std_logic;

			uartEN: 		OUT 		std_logic;
			uartin:		IN 		std_logic_vector(7 DOWNTO 0);
			uartout: 	INOUT 	std_logic_vector(7 DOWNTO 0);
			uartRd:		INOUT 	std_logic;						-- indicates value was read from controller
			uartTxReady:IN 		std_logic;						-- indicates new byte can be send
			uartRx:		IN			std_logic;						-- indicates new byte is available
			uartTx:		INOUT 	std_logic;						-- starts transmission of new byte

			strb: OUT  	std_logic;  									-- strobe, inicial new ADC:	high active
			csel: OUT  	std_logic;  									-- select wich chanel is used AIN1(0), AIN2(1)
			rsel: OUT  	std_logic;  									-- select wich range is used 2.56V(1), 160mV(0)
			done: IN 	std_logic;  									-- set done if datas are valid on ch1/2 output (High Active)
			ch1:  IN 	std_logic_vector(24-1 DOWNTO 0);
			ch2:  IN 	std_logic_vector(24-1 DOWNTO 0));
END AD7782CTRL;

ARCHITECTURE behaviour OF AD7782CTRL IS

BEGIN
	p1: PROCESS(clk, rst) IS
	BEGIN
		IF rst=RSTDEF THEN
			-- 
		END IF;
	END PROCESS;
END behaviour;