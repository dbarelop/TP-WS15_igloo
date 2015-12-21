LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY COMPXCTRL IS
	GENERIC(RSTDEF: std_logic := '1';
			DEVICEID: std_logic_vector(3 DOWNTO 0) := "0000");
	PORT(    rst:		IN	std_logic;
			 clk:		IN	std_logic;
			 
			 uartin:	IN 	std_logic_vector(7 DOWNTO 0);
			 uartRx:	IN	std_logic;						-- indicates new byte is available
			 uartRd:	OUT std_logic; 						-- indicates value was read from controller
			 uartout:   OUT std_logic_vector(7 DOWNTO 0);
			 uartTxReady: IN std_logic;						-- indicates new byte can be send
			 uartTx:	OUT std_logic;						-- starts transmission of new byte
			 
			 busy:		INOUT	std_logic					-- busy bit indicates working component
	);

END COMPXCTRL;

ARCHITECTURE behaviour OF COMPXCTRL IS

	TYPE tstate IS (IDLE, READSENDOK, WAITSENDOK, DELAY, EXECMD, ENDCOM);
    --TYPE tcmd IS (GETVERSION);
	
	SIGNAL state: tstate;
	SIGNAL dataIN: std_logic_vector(7 DOWNTO 0);
    SIGNAL sbusy: std_logic;

BEGIN

	main: PROCESS (clk, rst) IS

	BEGIN
		IF rst = RSTDEF THEN
			sbusy <= 'Z';
			uartout <= (others => 'Z');
			uartTx <= 'Z';
			uartRd <= 'Z';
			
			state <= IDLE;
		ELSIF rising_edge(clk) THEN
			IF state = IDLE AND uartRx = '1' THEN
				IF uartin(7 DOWNTO 4) = DEVICEID AND sbusy /= '1' THEN
					sbusy <= '1';
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
					WHEN others =>
						uartout <= x"01";
                        uartTx <= '1';
                        state <= ENDCOM;
				END CASE;
				-- END handle command
			ELSIF state = ENDCOM THEN
				uartout <= (others => 'Z');
				uartTx <= 'Z';
				uartRd <= 'Z';
				sbusy <= 'Z';
				state <= IDLE;
			END IF;
		END IF;
	END PROCESS;

    busy <= sbusy;

END behaviour;