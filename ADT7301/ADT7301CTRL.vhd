LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY ADT7301CTRL IS
	GENERIC(RSTDEF: std_logic := '1';
			DEVICEID: std_logic_vector(3 DOWNTO 0) := "0011");
	PORT(	rst:		IN	std_logic;
			swrst:		IN 	std_logic;
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

	COMPONENT BUSYCOUNTER
    GENERIC(RSTDEF: std_logic;
            LENGTH: NATURAL);
	PORT(	rst:		IN	std_logic;
            swrst:      IN  std_logic;
			clk:		IN	std_logic;
            en:         IN  std_logic;
			delayOut:   OUT std_logic 
	);
	END COMPONENT;

	SIGNAL startLED: std_logic;
	-- Component signals
	SIGNAL strb: std_logic;
	SIGNAL dout: std_logic_vector(13 DOWNTO 0);
	SIGNAL cs: std_logic;
	SIGNAL result: std_logic_vector(13 DOWNTO 0);

	CONSTANT CMD_READTEMP: std_logic_vector(3 DOWNTO 0) := "0000";

	TYPE tstate IS (IDLE, READSENDOK, WAITSENDOK, DELAY, EXECMD, ENDCOM);

	SIGNAL state: tstate;
	SIGNAL dataIN: std_logic_vector(7 DOWNTO 0);

	TYPE tuartstate IS (S0, S1, S2, FINISHED);
	SIGNAL uartstate: tuartstate;

	TYPE treadstate IS (S0, S1, DELAY, S2, S3, FINISHED);
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
			 cs		=> cs,
			 mosi	=> ADTmosi,
			 miso	=> ADTmiso);

	bsyCnt: BUSYCOUNTER
    GENERIC MAP(RSTDEF	=> RSTDEF,
            LENGTH		=> 16)
	PORT MAP(rst 		=> rst,		
            swrst		=> swrst,      
			clk			=> clk,		
            en 			=> startLED,
			delayOut	=> busyLED
	);

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
				WHEN S1 =>
					readstate <= DELAY;
					uartstate <= S0;
				WHEN DELAY =>
					IF cs = '1' THEN
						readstate <= S2;
						result <= dout(result'RANGE);
					END IF;
				WHEN S2 =>	-- send the first byte
					strb <= '0';
					sendUART("00" & result(13 DOWNTO 8));
					IF uartstate = FINISHED THEN
						uartstate <= S0;
						readstate <= S3;
					END IF;
				WHEN S3 =>	-- send the second byte
					sendUART(result(7 DOWNTO 0));
					IF uartstate <= FINISHED THEN
						readstate <= FINISHED;
					END IF;
				WHEN FINISHED =>
			END CASE;
		END PROCEDURE;

		PROCEDURE reset IS
		BEGIN
			busy <= 'Z';
			uartout <= (others => 'Z');
			uartTx <= 'Z';
			uartRd <= 'Z';
			startLED <= '0';

			state <= IDLE;
			readstate <= S0;
			uartstate <= S0;
		END PROCEDURE;

	BEGIN
		IF rst = RSTDEF THEN
			reset;
		ELSIF rising_edge(clk) THEN
			IF state = IDLE AND uartRx = '1' THEN
				IF uartin(7 DOWNTO 4) = DEVICEID AND busy /= '1' THEN
					busy <= '1';
					uartRd <= '1';
					dataIN <= uartin;
					state <= READSENDOK;
					startLED <= '1';
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
				startLED <= '0';
			END IF;
			IF swrst = RSTDEF THEN
				reset;
			END IF;
		END IF;
	END PROCESS;

	ADTcs <= cs;

END behaviour;