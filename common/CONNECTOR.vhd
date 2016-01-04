LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY CONNECTOR IS
	PORT(	rst:		IN	std_logic;
			clk:		IN	std_logic;

			uartRx:		IN	std_logic;
			uartTx:		OUT std_logic

	);

END CONNECTOR;

ARCHITECTURE behaviour OF CONNECTOR IS

	CONSTANT RSTDEF: std_logic := '1';

	SIGNAL rden:	std_logic;
	SIGNAL wren:	std_logic;
	SIGNAL din:		std_logic_vector(7 DOWNTO 0);
	SIGNAL rhrf:	std_logic;
	SIGNAL tsre:	std_logic;
	SIGNAL thre:	std_logic;
	SIGNAL dout:	std_logic_vector(7 DOWNTO 0);

	SIGNAL uartTxReady: std_logic;

	COMPONENT uart 
			GENERIC(RSTDEF: std_logic;
					BAUDEF: real;  -- baud rate
					FRQDEF: real);  -- clock frequency
		 	PORT(rst:	IN 	std_logic;  -- reset RSTDEF active
				clk:	IN 	std_logic;  -- clock, rising edge active
				swrst:	IN 	std_logic;  -- software reset,  RSTDEF active
				ena:	IN 	std_logic;  -- enable,		  high active

				rxd:	IN 	std_logic;  -- receive data
				rden:	IN 	std_logic;  -- read enable,	 high active
				dout:	OUT std_logic_vector(7 DOWNTO 0);
				rhrf:	OUT std_logic;  -- RHR full,		high active
				ovre:	OUT std_logic;  -- overrun error,   high active
				frme:	OUT std_logic;  -- framing error,   high active

				txd:	OUT std_logic;  -- transmit data output, high active
				wren:	IN 	std_logic;  -- write enable, high active
				din:	IN 	std_logic_vector(7 DOWNTO 0); -- data input
				tsre:	OUT std_logic;  -- transmit shift   register empty, high active
				thre:	OUT std_logic); -- transmit holding register empty, high active
	END COMPONENT;

BEGIN

	uartTxReady <= tsre AND thre;

	u1: uart
	GENERIC MAP(RSTDEF => RSTDEF,
				BAUDEF => 9.6e3,
				FRQDEF => 1.0e6)
	PORT MAP(
			rst		=>	rst,  -- reset RSTDEF active
			clk		=>	clk,  -- clock, rising edge active
			swrst	=>	'0',  -- software reset,  RSTDEF active
			ena		=>	'1',  -- enable,		  high active

			rxd		=>	uartRx,  -- receive data
			rden	=>	rden,  -- read enable,	 high active
			dout	=>	dout,
			rhrf	=>	rhrf,  -- RHR full,		high active
			ovre	=>	OPEN,  -- overrun error,   high active
			frme	=>	OPEN,  -- framing error,   high active

			txd		=>	uartTx,  -- transmit data output, high active
			wren	=>	wren,  -- write enable, high active
			din		=>	din, -- data input
			tsre	=>	tsre,  -- transmit shift   register empty, high active
			thre	=>	thre -- transmit holding register empty, high active
		);

END behaviour;