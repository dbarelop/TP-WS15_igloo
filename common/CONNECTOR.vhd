LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY CONNECTOR IS
	PORT(	rst:		IN	std_logic;
			clk:		IN	std_logic;

			rxd:		IN	std_logic;
			txd:		OUT std_logic;

			watchdogen: IN 	std_logic;

			eepromCS:	OUT std_logic;
			eepromSCLK:	OUT std_logic;
			eepromMOSI: OUT std_logic;
			eepromMISO: IN  std_logic;
			eepromORG:	OUT std_logic

	);

END CONNECTOR;

ARCHITECTURE behaviour OF CONNECTOR IS

	CONSTANT RSTDEF: std_logic := '1';

	SIGNAL swrst:	std_logic;

	SIGNAL rden:	std_logic;
	SIGNAL wren:	std_logic;
	SIGNAL din:		std_logic_vector(7 DOWNTO 0);
	SIGNAL rhrf:	std_logic;
	SIGNAL tsre:	std_logic;
	SIGNAL thre:	std_logic;
	SIGNAL dout:	std_logic_vector(7 DOWNTO 0);

	SIGNAL uartTxReady: std_logic;
	SIGNAL busy:		std_logic;

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
			thre:	OUT std_logic -- transmit holding register empty, high active
			);
	END COMPONENT;

	COMPONENT COMPXCTRL
		GENERIC(RSTDEF: 	std_logic;
				DEVICEID: 	std_logic_vector(3 DOWNTO 0);
				TIMEOUT:	NATURAL);
		PORT(rst:		IN	std_logic;
			swrst:		IN  std_logic;
			clk:		IN	std_logic;

			uartin:		IN 	std_logic_vector(7 DOWNTO 0);
			uartRx:		IN	std_logic;						-- indicates new byte is available
			uartRd:		INOUT std_logic; 						-- indicates value was read from controller
			uartout:	INOUT std_logic_vector(7 DOWNTO 0);
			uartTxReady:IN 	std_logic;						-- indicates new byte can be send
			uartTx:		INOUT std_logic;						-- starts transmission of new byte

			busy:		INOUT	std_logic;					-- busy bit indicates working component
			watchdog:	OUT 	std_logic;
			watchdogen: IN 		std_logic
			);
	END COMPONENT;

	COMPONENT EEPROMCTRL
		GENERIC(RSTDEF: std_logic;
				DEVICEID: std_logic_vector(3 DOWNTO 0));
		PORT(rst:		IN		std_logic;
			clk:		IN		std_logic;
			 
			uartin:		IN 		std_logic_vector(7 DOWNTO 0);
			uartRx:		IN		std_logic;						-- indicates new byte is available
			uartRd:		INOUT 	std_logic;				-- indicates value was read from controller
			uartout: 	INOUT 	std_logic_vector(7 DOWNTO 0);
			uartTxReady:IN 		std_logic;						-- indicates new byte can be send
			uartTx:		INOUT 	std_logic;						-- starts transmission of new byte
				 
			busy:		INOUT	std_logic;					-- busy bit indicates working component
			-- component pins
			sclk:		OUT 	std_logic;
			cs:			OUT 	std_logic;
			mosi:		OUT 	std_logic;
			miso:		IN 		std_logic;
			org:		OUT 	std_logic
		);
	END COMPONENT;


BEGIN

	uartTxReady <= tsre AND thre;

	u1: uart
	GENERIC MAP(RSTDEF => RSTDEF,
				BAUDEF => 9.6e3,
				FRQDEF => 1.0e6)
	PORT MAP(
			rst		=>	rst,
			clk		=>	clk,
			swrst	=>	swrst,
			ena		=>	'1',

			rxd		=>	rxd,
			rden	=>	rden,
			dout	=>	dout,
			rhrf	=>	rhrf,
			ovre	=>	OPEN,
			frme	=>	OPEN,

			txd		=>	txd,
			wren	=>	wren,
			din		=>	din, 
			tsre	=>	tsre,
			thre	=>	thre 
		);

	m1: COMPXCTRL
	GENERIC MAP(RSTDEF	=> 	RSTDEF,
				DEVICEID=> 	"0000",
				TIMEOUT =>	17)
	PORT MAP(rst	=>		rst,
			swrst	=>		swrst,
			clk		=>		clk,

			uartin	=>		dout,
			uartRx	=>		rhrf,
			uartRd	=>		rden,
			uartout	=>		din,
			uartTxReady	=>	uartTxReady,
			uartTx	=>		wren,

			busy	=>		busy,
			watchdog=>		swrst,
			watchdogen=>	watchdogen
			);

	d1: EEPROMCTRL
	GENERIC MAP(RSTDEF	=>	RSTDEF,
			DEVICEID	=>	"0001")
	PORT MAP(rst	=>		rst,
			clk		=>		clk,
			 
			uartin	=>		dout,
			uartRx	=>		rhrf,				-- indicates new byte is available
			uartRd	=>		rden,				-- indicates value was read from controller
			uartout	=> 		din,
			uartTxReady	=>	uartTxReady,		-- indicates new byte can be send
			uartTx	=>		wren,				-- starts transmission of new byte
			 
			busy	=>		busy,				-- busy bit indicates working component
			-- component pins
			sclk	=>		eepromSCLK,
			cs		=>		eepromCS,
			mosi	=>		eepromMOSI,
			miso	=>		eepromMISO,
			org		=>		eepromORG
			);

END behaviour;