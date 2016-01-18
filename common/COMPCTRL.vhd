LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY COMPXCTRL IS
	GENERIC(RSTDEF: std_logic := '1';
			DEVICEID: std_logic_vector(3 DOWNTO 0) := "0000";
            TIMEOUT: NATURAL := 17);
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
			watchdog:	OUT	std_logic;
			watchdogen: IN  std_logic
	);

END COMPXCTRL;

ARCHITECTURE behaviour OF COMPXCTRL IS

    COMPONENT COUNTER
		GENERIC(RSTDEF: std_logic;
				LENGTH: NATURAL);
        PORT(	rst:		IN	std_logic;
                swrst:      IN  std_logic;
                clk:		IN	std_logic;
                en:         IN  std_logic;
                overflow:   OUT std_logic
        );
	END COMPONENT;

	TYPE tstate IS (IDLE, READSENDOK, WAITSENDOK, DELAY, EXECMD, ENDCOM);

	SIGNAL state: tstate;
	SIGNAL dataIN: std_logic_vector(7 DOWNTO 0);
    SIGNAL overflow: std_logic;
    SIGNAL wen: std_logic;


BEGIN

	wen <= '1' WHEN watchdogen = '1' AND busy = '1' ELSE '0';

	main: PROCESS (clk, rst) IS

		PROCEDURE reset IS

		BEGIN
			busy <= 'Z';
			uartout <= (others => 'Z');
			uartTx <= 'Z';
			uartRd <= 'Z';

			state <= IDLE;
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
					WHEN "0000" =>
						uartout <= x"03";
						uartTx <= '1';
						state <= ENDCOM;
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
			IF swrst = RSTDEF THEN
				reset;
			END IF;
		END IF;
	END PROCESS;

    timoutCounter: COUNTER
    GENERIC MAP(RSTDEF	=> 	RSTDEF,
    			LENGTH =>	TIMEOUT)
    PORT MAP(
            rst => rst,
            swrst => swrst,
            clk => clk,
            en => wen,
            overflow => watchdog
	);

END behaviour;