LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY CONNECTOR IS
	PORT(	rst:		IN	std_logic;
			clk:		IN	std_logic;

			uartRx:		IN	std_logic;
			uartTx:		OUT std_logic;

			eepromCS:	OUT std_logic;
			eepromSCLK:	OUT std_logic;
			eepromMOSI: OUT std_logic;
			eepromMISO: IN  std_logic;
			eepromORG:	OUT std_logic;
			
			ADCdin: 	IN 	std_logic;	-- Serial Datainput from the AD Converter
			ADCrng: 	OUT	std_logic;	-- logic output which selects the range for AD Converter: 2.56V(1), 160mV(0)
			ADCsel: 	OUT 	std_logic;  -- logic output which selects the active channel: AIN1 (=0) or ANI2 (=1)
         ADCmode:	OUT 	std_logic;  -- logic output which selects master (=0) or slave (=1) mode of operation
         ADCcs:  	OUT 	std_logic;  -- chip select, low active
         ADCsclk:	OUT 	std_logic); -- serial clock output

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
				DEVICEID: 	std_logic_vector(3 DOWNTO 0));
		PORT(rst:		IN	std_logic;
			clk:		IN	std_logic;

			uartin:		IN 	std_logic_vector(7 DOWNTO 0);
			uartRx:		IN	std_logic;						-- indicates new byte is available
			uartRd:		INOUT std_logic; 						-- indicates value was read from controller
			uartout:	INOUT std_logic_vector(7 DOWNTO 0);
			uartTxReady:IN 	std_logic;						-- indicates new byte can be send
			uartTx:		INOUT std_logic;						-- starts transmission of new byte

			busy:		INOUT	std_logic					-- busy bit indicates working component
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
	
	COMPONENT AD7782CTRL IS
	GENERIC(RSTDEF: std_logic := '1';
			DEVICEID: std_logic_vector(3 DOWNTO 0) := "0010");
	PORT(	rst:		IN	std_logic;
			clk:		IN	std_logic;
			busy:		INOUT	std_logic;							-- busy bit indicates working component

			uartin:		IN 	std_logic_vector(7 DOWNTO 0);
			uartout:		INOUT std_logic_vector(7 DOWNTO 0);
			uartRd:		INOUT std_logic; 						-- indicates value was read from controller
			uartTx:		INOUT std_logic;						-- starts transmission of new byte
			uartRx:		IN		std_logic;						-- indicates new byte is available to read
			uartTxReady:IN 	std_logic;						-- indicates new byte can be send
			
			ADCdin: 	IN 	std_logic;
			ADCrng: 	OUT	std_logic;
			ADCsel: 	OUT 	std_logic;  -- logic output which selects the active channel AIN1 (=0) or ANI2 (=1)
         ADCmode:	OUT 	std_logic;  -- logic output which selects master (=0) or slave (=1) mode of operation
         ADCcs:  	OUT 	std_logic;  -- chip select, low active
         ADCsclk:	OUT 	std_logic); -- serial clock output

	END COMPONENT;


BEGIN

	uartTxReady <= tsre AND thre;		-- new byte can be send

	u1: uart
	GENERIC MAP(RSTDEF => RSTDEF,
				BAUDEF => 9.6e3,
				FRQDEF => 1.0e6)
	PORT MAP(
			rst		=>	rst,
			clk		=>	clk,
			swrst	=>	NOT RSTDEF,
			ena		=>	'1',

			rxd		=>	uartRx,			-- pc Connection
			rden	=>	rden,					-- dout read
			dout	=>	dout,
			rhrf	=>	rhrf,					-- new byte on dout
			ovre	=>	OPEN,
			frme	=>	OPEN,

			txd		=>	uartTx,			-- pc Connection
			wren	=>	wren,					-- send din
			din		=>	din, 
			tsre	=>	tsre,
			thre	=>	thre 
		);

	m1: COMPXCTRL
	GENERIC MAP(RSTDEF	=> 	RSTDEF,
				DEVICEID=> 	"0000")
	PORT MAP(rst	=>		rst,
			clk		=>		clk,

			uartin	=>		dout,
			uartRx	=>		rhrf,
			uartRd	=>		rden,
			uartout	=>		din,
			uartTxReady	=>	uartTxReady,
			uartTx	=>		wren,

			busy	=>		busy
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
	
	d2: AD7782CTRL
	GENERIC MAP(RSTDEF	=>	RSTDEF,
			DEVICEID	=>	"0010")
	PORT MAP(rst	=> rst,
				clk:	=> clk,
				busy	=> busy,								-- busy bit indicates working component

				uartin			=> dout,
				uartout			=> din,
				uartRd			=> rden,					-- indicates value was read from controller
				uartTx			=> wren,					-- starts transmission of new byte
				uartRx			=> rhrf,					-- indicates new byte is available to read
				uartTxReady		=> uartTxReady,		-- indicates new byte can be send
				
				ADCdin			=> ADCdin,
				ADCrng			=> ADCrng,
				ADCsel			=> ADCsel,				-- logic output which selects the active channel AIN1 (=0) or ANI2 (=1)
				ADCmode			=> ADCmode,				-- logic output which selects master (=0) or slave (=1) mode of operation
				ADCcs				=> ADCcs,				-- chip select, low active
				ADCsclk			=> ADCsclk);			-- serial clock output

END behaviour;