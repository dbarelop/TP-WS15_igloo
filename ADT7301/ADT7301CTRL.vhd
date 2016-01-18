LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY ADT7301CTRL IS
	GENERIC(RSTDEF: std_logic := '1';
			DEVICEID: std_logic_vector(3 DOWNTO 0) := "0000");
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

END ADT7301CTRL;

ARCHITECTURE behaviour OF ADT7301CTRL IS

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

	-- Component signals
	SIGNAL strb: std_logic;
	SIGNAL dout: std_logic_vector(13 DOWNTO 0);
	SIGNAL sclk: std_logic;
	SIGNAL cs: std_logic;
	SIGNAL mosi: std_logic;
	SIGNAL miso: std_logic;

	CONSTANT CMD_READTEMP: std_logic_vector(3 DOWNTO 0) := X"1";

	TYPE tstate IS (IDLE, READSENDOK, WAITSENDOK, DELAY, EXECMD, ENDCOM);

	SIGNAL state: tstate;
	SIGNAL dataIN: std_logic_vector(7 DOWNTO 0);

	TYPE tuartstate IS (S0, S1, S2);
	SIGNAL uartstate: tuartstate;

	TYPE treadstate IS (S0, S1, S2);
	SIGNAL readstate: treadstate;

BEGIN

	adtif: ADT7301IF
	GENERIC MAP(RSTDEF => RSTDEF)
	PORT MAP(rst	=> rst,
			 clk	=> clk,
			 strb	=> strb,
			 dout	=> ADTdout,
			 sclk	=> ADTsclk,
			 cs		=> ADTcs,
			 mosi	=> ADTmosi,
			 miso	=> miso);

	main: PROCESS (clk, rst) IS

		PROCEDURE sendUART(value: IN std_logic_vector(7 DOWNTO 0)) IS
		BEGIN
			CASE uartstate IS
				WHEN S0 =>
					uartout <= value(7 DOWNTO 0);
					uartTx <= '1';
					uartstate <= S1;
				WHEN S1 =>
					IF uartTxReady = '0' THEN
						uartTx <= '0';
						uartstate <= S2;
					END IF;
				WHEN S2 =>
					IF uartTxReady = '1' THEN
						uartstate <= S0;
					END IF;
			END CASE;
		END PROCEDURE;

		PROCEDURE readADT IS
		BEGIN
			CASE readstate IS
				WHEN S0 =>
					strb <= '1';
					readstate <= S1;
				WHEN S1 =>	-- send the first byte
					strb <= '0';
					uartstate <= S0;
					sendUART("0000" & dout(13 DOWNTO 0));
					IF uartstate = S0 THEN
						readstate <= S2;
					END IF;
				WHEN S2 =>	-- send the second byte
					uartstate <= S0;
					sendUART(dout(7 DOWNTO 0));
					IF uartstate <= S0 THEN
						readstate <= S0;
					END IF;
			END CASE;
		END PROCEDURE;

	BEGIN
		IF rst = RSTDEF THEN
			busy <= 'Z';
			uartout <= (others => 'Z');
			uartTx <= 'Z';
			uartRd <= 'Z';

			state <= IDLE;
		ELSIF rising_edge(clk) THEN
			IF state = IDLE AND uartRx = '1' THEN
				IF uartin(7 DOWNTO 4) = DEVICEID AND busy /= '1' THEN
					busy <= '1';
					uartRd <= '1';
					dataIN <= uartin;
					state <= READSENDOK;
				END IF;
			ELSIF state = READSENDOK THEN
				uartout <= x"AA"; -- OK message
				uartTx <= '1';
				uartRd <= '0';
				state <= DELAY;
			ELSIF state = DELAY THEN
				state <= WAITSENDOK;
			ELSIF state = WAITSENDOK THEN
				uartTx <= '0';
				IF uartTxReady = '1' THEN
					state <= EXECMD;
				END IF;
			ELSIF state = EXECMD THEN
				-- BEGIN handle command
				CASE dataIN(3 DOWNTO 0) IS
					WHEN CMD_READTEMP =>
					-- Read ADT temperature value and output to UART
						readstate <= S0;
						readADT;
						IF readstate = S2 THEN
							state <= ENDCOM;
						END IF;
					WHEN others =>
						state <= ENDCOM;
				END CASE;
				-- END handle command
			ELSIF state = ENDCOM THEN
				uartout <= (others => 'Z');
				uartTx <= 'Z';
				uartRd <= 'Z';
				busy <= 'Z';
				state <= IDLE;
			END IF;
		END IF;
	END PROCESS;

END behaviour;