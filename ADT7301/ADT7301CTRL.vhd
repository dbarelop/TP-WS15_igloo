LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY ADT7301CTRL IS
	GENERIC(RSTDEF: std_logic := '1';
			DEVICEID: std_logic_vector(3 DOWNTO 0) := "0011");
	PORT(	rst:		IN	std_logic;
			clk:		IN	std_logic;

			uartin:		IN 	std_logic_vector(7 DOWNTO 0);
			uartRx:		IN	std_logic;						-- indicates new byte is available
			uartRd:		INOUT std_logic; 						-- indicates value was read from controller
			uartout:	INOUT std_logic_vector(7 DOWNTO 0);
			uartTxReady:IN 	std_logic;						-- indicates new byte can be send
			uartTx:		INOUT std_logic;						-- starts transmission of new byte

			busy:		INOUT	std_logic;					-- busy bit indicates working component

			-- Component pins
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

	CONSTANT CMD_READTEMP: std_logic_vector(3 DOWNTO 0) := "0001";

	TYPE tstate IS (IDLE, READSENDOK, WAITSENDOK, DELAY, EXECMD, ENDCOM);

	SIGNAL state: tstate;
	SIGNAL dataIN: std_logic_vector(7 DOWNTO 0);

	TYPE tuartstate IS (S0, S1, S2, FINISHED);
	SIGNAL uartstate: tuartstate;

	TYPE treadstate IS (S0, S1, S2, FINISHED);
	SIGNAL readstate: treadstate;

	TYPE tcmd IS (READTEMP);
	SIGNAL cmd: tcmd;

BEGIN

	adtif: ADT7301IF
	GENERIC MAP(RSTDEF => RSTDEF)
	PORT MAP(rst	=> rst,
			 clk	=> clk,
			 strb	=> strb,
			 dout	=> dout,
			 sclk	=> ADTsclk,
			 cs		=> ADTcs,
			 mosi	=> ADTmosi,
			 miso	=> ADTmiso);

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
						uartstate <= FINISHED;
					END IF;
				WHEN FINISHED =>
			END CASE;
		END PROCEDURE;

		PROCEDURE readADT IS
		BEGIN
			CASE readstate IS
				WHEN S0 =>
					strb <= '1';
					readstate <= S1;
					uartstate <= S0;
				WHEN S1 =>	-- send the first byte
					strb <= '0';
					--uartstate <= S0;
					sendUART("00" & dout(13 DOWNTO 8));
					IF uartstate = FINISHED THEN
						uartstate <= S0;
						readstate <= S2;
					END IF;
				WHEN S2 =>	-- send the second byte
					--uartstate <= S0;
					sendUART(dout(7 DOWNTO 0));
					IF uartstate <= FINISHED THEN
						readstate <= FINISHED;
					END IF;
				WHEN FINISHED =>
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
				CASE dataIn(3 DOWNTO 0) IS
					WHEN CMD_READTEMP =>
						cmd <= READTEMP;
						uartout <= x"AA"; -- OK message
						uartTx <= '1';
						uartRd <= '0';
						state <= DELAY;
					WHEN OTHERS =>
						uartout <= x"FF"; -- Error message
						uartTx <= '1';
						uartRd <= '0';
						state <= ENDCOM;
				END CASE;
			ELSIF state = DELAY THEN
				state <= WAITSENDOK;
			ELSIF state = WAITSENDOK THEN
				uartTx <= '0';
				IF uartTxReady = '1' THEN
					state <= EXECMD;
				END IF;
			ELSIF state = EXECMD THEN
				-- BEGIN handle command
				CASE cmd IS
					WHEN READTEMP =>
					-- Read ADT temperature value and output to UART
						--readstate <= S0;
						readADT;
						IF readstate = FINISHED THEN
							state <= ENDCOM;
							readstate <= S0;
						END IF;
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