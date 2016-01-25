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
	GENERIC(RSTDEF: std_logic;
			DEVICEID: std_logic_vector);
	PORT(	rst:		IN	std_logic;
			swrst:		IN  std_logic;
			clk:		IN	std_logic;

			uartin:		IN 	std_logic_vector(7 DOWNTO 0);
			uartRx:		IN	std_logic;						-- indicates new byte is available
			uartRd:		INOUT std_logic; 						-- indicates value was read from controller
			uartout:	INOUT std_logic_vector(7 DOWNTO 0);
			uartTxReady:IN 	std_logic;						-- indicates new byte can be send
			uartTx:		INOUT std_logic;						-- starts transmission of new byte

			busy:		INOUT	std_logic;					-- busy bit indicates working component
			busyLED:	OUT 	std_logic;

			-- Component pins
			ADTsclk:	OUT std_logic;
			ADTcs:		OUT std_logic;
			ADTmosi:	OUT std_logic;
			ADTmiso:	IN std_logic
	);
	END COMPONENT;

	COMPONENT ADT7301
		PORT(sclk:	IN std_logic;  -- serial clock input
			cs:		IN std_logic;  -- chip select, low active
			din:	IN std_logic;  -- serial data input
			dout:	OUT std_logic); -- serial data output
	END COMPONENT;

	CONSTANT ADT_DEVICEID: std_logic_vector(3 DOWNTO 0) := "0011";
	CONSTANT CMD_READTEMP: std_logic_vector(3 DOWNTO 0) := "0000";

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

	SIGNAL result: std_logic_vector(15 DOWNTO 0);

BEGIN

	clk <= NOT clk AFTER tcyc/2;

   adt: ADT7301
   PORT MAP(sclk => ADTsclk,
            cs   => ADTcs,
            din  => ADTmosi,
            dout => ADTmiso);

	adtctrl: ADT7301CTRL
	GENERIC MAP(RSTDEF => RSTDEF,
				DEVICEID => "0011")
	PORT MAP(rst			=> rst,
			 swrst			=> NOT RSTDEF,
			 clk			=> clk,
			 uartin			=> uartin,
			 uartRx			=> uartRx,
			 uartRd			=> uartRd,
			 uartout		=> uartout,
			 uartTxReady	=> uartTxReady,
			 uartTx			=> uartTx,
			 busy			=> busy,
			 busyLED		=> OPEN,
			 ADTsclk		=> ADTsclk,
			 ADTcs			=> ADTcs,
			 ADTmosi		=> ADTmosi,
			 ADTmiso		=> ADTmiso);

	p1: PROCESS
		-- Returns TRUE only when the given value belongs to the range [0x0000,0x12C0]U[0x3B00,0x3FFF]
		FUNCTION valid_temp_value(val: std_logic_vector)
			RETURN boolean IS
		BEGIN
			RETURN val >= X"0000" AND (val <= X"12C0" OR val >= X"3B00") AND val <= X"3FFF";
		END FUNCTION;

		PROCEDURE uartSendN (dataIn: std_logic_vector(7 DOWNTO 0)) IS
		BEGIN
			-- Send command
			uartin <= dataIn(7 DOWNTO 0);
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

			-- Receive result
			WAIT UNTIL uartTx = '1';
			result <= x"00" & uartout;				-- first byte
			uartTxReady <= '0';
			WAIT FOR 1 us;
			uartTxReady <= '1';
			WAIT UNTIL uartTx = '1';
			result <= result(7 DOWNTO 0) & uartout;	-- second byte
			assert valid_temp_value(result) report "wrong result";
			uartTxReady <= '0';
			WAIT FOR 1 us;
			uartTxReady <= '1';

		END PROCEDURE;

		CONSTANT NUM_CHECKS: integer := 5000;
	BEGIN
		WAIT FOR 1 us;
		rst <= NOT RSTDEF;

		FOR i IN NUM_CHECKS DOWNTO 0 LOOP
			WAIT FOR 1.5 ms;	-- ADT's conversion time
			uartSendN(ADT_DEVICEID & CMD_READTEMP);
		END LOOP;

		REPORT "all tests done..." SEVERITY note;
		WAIT;

	END PROCESS;

END behaviour;