LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ADT7301CTRL_tb IS
	-- empty
END ADT7301CTRL_tb;

ARCHITECTURE behaviour OF ADT7301CTRL_tb IS

	CONSTANT RSTDEF: 	std_logic 	:= '0';
	CONSTANT FRQDEF: 	natural		:= 4e6;
	CONSTANT tcyc:		time		:= 1 sec / FRQDEF;

	COMPONENT ADT7301CTRL
	GENERIC(RSTEDF: std_logic;
			DEVICEID: std_logic_vector);
	PORT(	rst:		IN	std_logic;
			clk:		IN	std_logic;

			uartin:		IN 	std_logic_vector(7 DOWNTO 0);
			uartRx:		IN	std_logic;						-- indicates new byte is available
			uartRd:		INOUT std_logic; 						-- indicates value was read from controller
			uartout:	INOUT std_logic_vector(7 DOWNTO 0);
			uartTxReady:IN 	std_logic;						-- indicates new byte can be send
			uartTx:		INOUT std_logic;						-- starts transmission of new byte

			busy:		INOUT	std_logic					-- busy bit indicates working component

			-- Component pins
			ADTdout:	OUT std_logic_vector(13 DOWNTO 0);
			ADTsclk:	OUT std_logic;
			ADTcs:		OUT std_logic;
			ADTmosi:	OUT std_logic;
			ADTmiso:	IN std_logic
	);
	END COMPONENT;

	COMPONENT ADT7301IF IS
	GENERIC(RSTDEF: std_logic);
	PORT(rst:	IN std_logic;
		 clk:	IN std_logic;
		 strb:	IN std_logic;
		 dout:	OUT std_logic_vector(13 DOWNTO 0);
		 sclk:	OUT std_logic;
		 cs:	OUT std_logic;
		 mosi:	OUT std_logic;
		 miso:	IN std_logic);
	END COMPONENT;

	SIGNAL rst:	std_logic := RSTDEF;
	SIGNAL clk:	std_logic := '0';
	SIGNAL ADTdout:	std_logic_vector(13 DOWNTO 0) := (OTHERS => '0');
	SIGNAL ADTsclk:	std_logic := '0';
	SIGNAL ADTcs:	std_logic := '0';
	SIGNAL ADTmosi:	std_logic := '0';
	SIGNAL ADTmiso: std_logic := '0';

	SIGNAL uartin:std_logic_vector(7 DOWNTO 0) := (others => '0');
	SIGNAL uartRx:std_logic:= '0';
	SIGNAL uartRd:std_logic:= '0';
	SIGNAL uartout:std_logic_vector(7 DOWNTO 0) := (others => '0');
	SIGNAL uartTxReady:std_logic :='1';
	SIGNAL uartTx: std_logic:='0';
	SIGNAL busy:	std_logic := '0';

BEGIN

	clk <= NOT clk AFTER tcyc/2;

	adtif: ADT7301IF
	GENERIC MAP(RSTDEF => RSTDEF)
	PORT MAP(rst	=> rst,
			 clk	=> clk,
			 strb	=> strb,
			 dout	=> ADTdout,
			 sclk	=> ADTsclk,
			 cs		=> ADTcs,
			 mosi	=> ADTmosi,
			 miso	=> ADTmiso);

	adtctrl: ADT7301CTRL
	GENERIC MAP(RSTDEF => RSTDEF,
				DEVICEID => "0011")
	PORT MAP(rst			=> rst,
			 clk			=> clk,
			 uartin			=> uartin,
			 uartRx			=> uartRx,
			 uartRd			=> uartRd,
			 uartout		=> uartout,
			 uartTxReady	=> uartTxReady,
			 uartTx			=> uartTx,
			 busy			=> busy,
			 ADTdout		=> ADTdout,
			 ADTsclk		=> ADTsclk,
			 ADTcs			=> ADTcs,
			 ADTmosi		=> ADTmosi,
			 ADTmiso		=> ADTmiso);

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

		-- TODO: program tests

		REPORT "all tests done..." SEVERITY note;
		WAIT;

	END PROCESS;

END behaviour;