LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY EEPROM93LC66CTRL_tb IS
	-- empty
END EEPROM93LC66CTRL_tb;

ARCHITECTURE verhalten OF EEPROM93LC66CTRL_tb IS

	CONSTANT RSTDEF: 	std_logic 	:= '0';
	CONSTANT FRQDEF: 	natural		:= 4e6;
	CONSTANT tcyc:		time		:= 1 sec / FRQDEF;

	COMPONENT EEPROMCTRL
	GENERIC(RSTDEF: std_logic;
			DEVICEID: std_logic_vector);
	PORT(	rst:		IN	std_logic;
			clk:		IN	std_logic;

			uartin:		IN 	std_logic_vector(7 DOWNTO 0);
			uartRx:		IN	std_logic;						-- indicates new byte is available
			uartRd:		INOUT std_logic; 						-- indicates value was read from controller
			uartout:	INOUT std_logic_vector(7 DOWNTO 0);
			uartTxReady:IN std_logic;						-- indicates new byte can be send
			uartTx:		INOUT std_logic;						-- starts transmission of new byte
			 
			busy:		INOUT	std_logic;					-- busy bit indicates working component
			-- component pins
			sclk:		OUT std_logic;
			cs:			OUT std_logic;
			mosi:		OUT std_logic;
			miso:		IN std_logic;
			org:		OUT std_logic
	);
	END COMPONENT;

	COMPONENT EEPROM93LC66
	PORT(	sclk:	IN std_logic;
			cs:		IN std_logic;
			din:	IN std_logic;
			dout:	OUT std_logic;
			org:	IN std_logic);
	END COMPONENT;



	SIGNAL rst:	std_logic := RSTDEF;
	SIGNAL clk:	std_logic := '0';
	SIGNAL sclk:std_logic := '0';
	SIGNAL cs:	std_logic := '0';
	SIGNAL mosi:std_logic := '0';
	SIGNAL miso:std_logic := '0';
	SIGNAL org: std_logic := '0';

	SIGNAL uartin:std_logic_vector(7 DOWNTO 0) := (others => '0');
	SIGNAL uartRx:std_logic:= '0';
	SIGNAL uartRd:std_logic:= '0';
	SIGNAL uartout:std_logic_vector(7 DOWNTO 0) := (others => '0');
	SIGNAL uartTxReady:std_logic :='1';
	SIGNAL uartTx: std_logic:='0';
	SIGNAL busy:	std_logic := '0';

BEGIN

	clk <= NOT clk AFTER tcyc/2;

	u1: EEPROM93LC66
	PORT MAP(sclk 	=> sclk,
			cs 		=> cs,
			din 	=> mosi,
			dout 	=> miso,
			org 	=> org);

	u2: EEPROMCTRL
	GENERIC MAP(RSTDEF => RSTDEF,
				DEVICEID => "0001")
	PORT MAP(rst		=>	rst,
			clk		=>	clk,
			uartin	=>	uartin,
			uartRx	=>	uartRx,
			uartRd	=>	uartRd,
			uartout	=>	uartout,
			uartTxReady	=>	uartTxReady,
			uartTx	=>	uartTx,
			busy	=>	busy,
			sclk	=>	sclk,
			cs		=>	cs,
			mosi	=>	mosi,
			miso	=>	miso,
			org		=>	org
	);



	p1: PROCESS
		VARIABLE n_rxbytes: integer;
		VARIABLE n_txbytes: integer;

		PROCEDURE setNBytes(rxBytes: integer; txBytes: integer) IS

		BEGIN
			n_rxbytes := rxBytes;
			n_txbytes := txBytes;
		END PROCEDURE;

		PROCEDURE uartSendN (dataIn: std_logic_vector((n_rxbytes*8)-1 DOWNTO 0); result: std_logic_vector((n_txbytes*8)-1 DOWNTO 0)) IS
			VARIABLE dataInLength: INTEGER := dataIn'LENGTH-1;
			VARIABLE dataOutLength: INTEGER := result'LENGTH-1;
		BEGIN
			uartin <= dataIn(dataInLength DOWNTO dataInLength-7);
			uartRx <= '1';
			WAIT UNTIL uartRd = '1';
			uartRx <= '0';
			WAIT UNTIL uartTx = '1';
			assert uartout = x"AA" report "OK message failed";
			uartTxReady <= '0';
			WAIT FOR 1 us;
			uartTxReady <= '1';
			IF uartTx /= '0' THEN
				WAIT UNTIL uartTx = '0';
			END IF;
			FOR i in 1 to n_rxbytes-1 LOOP
				uartin <= dataIn(dataInLength-8*i DOWNTO dataInLength-8*i-7);
				uartRx <= '1';
				IF uartRd = '0' THEN
					WAIT UNTIL uartRd = '1';
				END IF;
				uartRx <= '0';
				IF uartRd = '1' THEN
					WAIT UNTIL uartRd = '0';
				END IF;
			END LOOP;
			IF result'LENGTH >= 8 THEN
				FOR i in 0 to n_txbytes-1 LOOP
					WAIT UNTIL uartTx = '1';
					assert uartout = result(dataOutLength-8*i DOWNTO dataOutLength-8*i-7) report "wrong result";
					uartTxReady <= '0';
					WAIT FOR 1 us;
					uartTxReady <= '1';
					IF uartTx = '1' THEN
						WAIT UNTIL uartTx = '0';
					END IF;
				END LOOP;
			END IF;

		END PROCEDURE;

	BEGIN
		WAIT FOR 1 us;
		rst <= NOT RSTDEF;

		setNBytes(2,1);
		uartSendN("00010000"&"00000000", x"FF");
		setNBytes(3,0);
		uartSendN("00010001"&"00000000"&x"CC", "");
		uartSendN("00010001"&"00000001"&x"DD", "");
		uartSendN("00010001"&"00000010"&x"EE", "");
		setNBytes(2,1);
		uartSendN("00010000"&"00000000", x"CC");
		uartSendN("00010000"&"00000001", x"DD");
		uartSendN("00010000"&"00000010", x"EE");
		--ERAL
		setNBytes(1,0);
		uartSendN("00010010", "");
		setNBytes(2,1);
		uartSendN("00010000"&"00000000", x"FF");
		uartSendN("00010000"&"00000001", x"FF");
		uartSendN("00010000"&"00000010", x"FF");


		REPORT "all tests done..." SEVERITY note;
		WAIT;

	END PROCESS;

END verhalten;