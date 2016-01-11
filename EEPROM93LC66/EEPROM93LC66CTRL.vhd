LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY EEPROMCTRL IS
	GENERIC(RSTDEF: std_logic := '1';
			DEVICEID: std_logic_vector(3 DOWNTO 0) := "0001");
	PORT(	rst:		IN		std_logic;
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

END EEPROMCTRL;

ARCHITECTURE behaviour OF EEPROMCTRL IS

	COMPONENT EEPROM93LC66IF
	GENERIC(RSTDEF: std_logic);
	PORT(	rst:	IN	std_logic;
			clk:	IN	std_logic;			-- 4 MHz MAX!! leads to 2 MHz sclk
			cmd:	IN 	std_logic_vector(3 DOWNTO 0);
			strb:	IN	std_logic;			-- executes the given command with the given address 
			dout:	OUT std_logic_vector(15 DOWNTO 0);
			din:	IN 	std_logic_vector(15 DOWNTO 0);
			adrin:	IN 	std_logic_vector(8 DOWNTO 0);
			busyout:OUT	std_logic;			-- busy bit indicates working eeprom, dout not valid

			sclk:	OUT std_logic;			-- serial clock to EEPROM
			cs:		OUT std_logic;			-- chip select, HIGH active
			mosi:	OUT std_logic;
			miso:	IN 	std_logic;
			org:	OUT std_logic);			-- memory-config =1 16 bit / =0 8 bit wordlength

	END COMPONENT;

	-- component signals
	SIGNAL cmd: std_logic_vector(3 DOWNTO 0);
	SIGNAL strb: std_logic;
	SIGNAL dout: std_logic_vector(15 DOWNTO 0);
	SIGNAL din: std_logic_vector(15 DOWNTO 0);
	SIGNAL adrin: std_logic_vector(8 DOWNTO 0);
	SIGNAL busyout: std_logic;


	TYPE tstate IS (IDLE, READSENDOK, WAITSENDOK, DELAY, DEFCMD, EXECMD, ENDCOM);
	TYPE tmaincmd IS (READ, READ16, WRITE, WRITE16, ERASE, EWEN);

	SIGNAL state: tstate;
	SIGNAL maincmd: tmaincmd;
	SIGNAL dataIN: std_logic_vector(7 DOWNTO 0);

	TYPE tcmd IS (SENDCMD, RXARG1, DELAY, RXARG2, DELAY2, RXARG3, WAITANSWER, TXANSWER, TXANSWER2, FINISH);
	SIGNAL readcmd: tcmd;

BEGIN

	u2: EEPROM93LC66IF
	GENERIC MAP(RSTDEF => RSTDEF)
	PORT MAP(rst => rst,
			clk => clk,
			cmd => cmd,
			strb=> strb,
			dout=> dout,
			din => din,
			adrin => adrin,
			busyout => busyout,

			sclk => sclk,
			cs => cs,
			mosi => mosi,
			miso => miso,
			org => org

			);

	main: PROCESS (clk, rst) IS

		PROCEDURE readPro IS

		BEGIN
			IF readcmd = SENDCMD THEN
				cmd <= "0010";
				readcmd <= RXARG1;
			ELSIF readcmd = RXARG1 THEN
				-- rx address
				IF uartRx = '1' THEN
					adrin(8) <= uartin(0);
					uartRd <= '1';
					readcmd <= DELAY;
				END IF;
			ELSIF readcmd = DELAY THEN
				uartRd <= '0';
				IF uartRx = '0' THEN
					readcmd <= RXARG2;
				END IF;
			ELSIF readcmd = RXARG2 THEN
				IF uartRx = '1' THEN
					adrin(7 DOWNTO 0) <= uartin;
					uartRd <= '1';
					strb <= '1';
					readcmd <= WAITANSWER;
				END IF;
			ELSIF readcmd = WAITANSWER THEN
				strb <= '0';
				uartRd <= '0';
				IF busyout = '0' AND strb = '0' THEN
					readcmd <= TXANSWER;
				END IF;
			ELSIF readcmd = TXANSWER THEN
				uartout <= dout(7 DOWNTO 0);
				uartTx <= '1';
				state <= ENDCOM;
				readcmd <= SENDCMD;
			END IF;

		END PROCEDURE;

		PROCEDURE read16Pro IS

		BEGIN
			IF readcmd = SENDCMD THEN
				cmd <= "1010";
				readcmd <= RXARG1;
			ELSIF readcmd = RXARG1 THEN
				-- rx address
				IF uartRx = '1' THEN
					adrin(7 DOWNTO 0) <= uartin;
					uartRd <= '1';
					strb <= '1';
					readcmd <= WAITANSWER;
				END IF;
			ELSIF readcmd = WAITANSWER THEN
				strb <= '0';
				uartRd <= '0';
				IF busyout = '0' AND strb = '0' THEN
					readcmd <= TXANSWER;
				END IF;
			ELSIF readcmd = TXANSWER THEN
				uartout <= dout(15 DOWNTO 8);
				uartTx <= '1';
				readcmd <= DELAY;
			ELSIF readcmd = DELAY THEN
				uartTx <= '0';
				IF uartTxReady = '1' THEN
					readcmd <= TXANSWER2;
				END IF;
			ELSIF readcmd = TXANSWER2 THEN
				uartout <= dout(7 DOWNTO 0);
				uartTx <= '1';
				readcmd <= DELAY2;
			ELSIF readcmd = DELAY2 THEN
				IF uartTxReady = '0' THEN
					uartTx <= '0';
					readcmd <= FINISH;
				END IF;
			ELSIF readcmd = FINISH THEN
				IF uartTxReady = '1' THEN
					state <= ENDCOM;
					readcmd <= SENDCMD;
				END IF;
			END IF;

		END PROCEDURE;

		PROCEDURE ewenPro IS

		BEGIN
			IF readcmd = SENDCMD THEN
				cmd <= "0110";
				strb <= '1';
				readcmd <= WAITANSWER;
			ELSIF readcmd = WAITANSWER THEN
				strb <= '0';
				IF busyout = '0' AND strb = '0' THEN
					readcmd <= SENDCMD;
					state <= ENDCOM;
				END IF;
			END IF;
		END PROCEDURE;

		PROCEDURE erasePro IS

		BEGIN
			IF readcmd = SENDCMD THEN
				cmd <= "0100";
				strb <= '1';
				readcmd <= WAITANSWER;
			ELSIF readcmd = WAITANSWER THEN
				strb <= '0';
				IF busyout = '0' AND strb = '0' THEN
					readcmd <= SENDCMD;
					state <= ENDCOM;
				END IF;
			END IF;
		END PROCEDURE;

		PROCEDURE writePro IS

		BEGIN
			IF readcmd = SENDCMD THEN
				cmd <= "0001"; --write
				readcmd <= RXARG1;
			ELSIF readcmd = RXARG1 THEN
				-- rx address
				IF uartRx = '1' THEN
					adrin(8) <= uartin(0);
					uartRd <= '1';
					readcmd <= DELAY;
				END IF;
			ELSIF readcmd = DELAY THEN
				uartRd <= '0';
				IF uartRx = '0' THEN
					readcmd <= RXARG2;
				END IF;
			ELSIF readcmd = RXARG2 THEN
				IF uartRx = '1' THEN
					adrin(7 DOWNTO 0) <= uartin;
					uartRd <= '1';
					readcmd <= DELAY2;
				END IF;
			ELSIF readcmd = DELAY2 THEN
				uartRd <= '0';
				IF uartRx = '0' THEN
					readcmd <= RXARG3;
				END IF;
			ELSIF readcmd = RXARG3 THEN
				-- rx data
				IF uartRx = '1' THEN
					din(7 DOWNTO 0) <= uartin;
					strb <= '1';
					uartRd <= '1';
					readcmd <= WAITANSWER;
				END IF;
			ELSIF readcmd = WAITANSWER THEN
				uartRd <= '0';
				strb <= '0';
				IF busyout = '0' AND strb = '0' THEN
					readcmd <= SENDCMD;
					state <= ENDCOM;
				END IF;
			END IF;
		END PROCEDURE;

		PROCEDURE write16Pro IS

		BEGIN
			IF readcmd = SENDCMD THEN
				cmd <= "1001"; --write
				readcmd <= RXARG1;
			ELSIF readcmd = RXARG1 THEN
				-- rx address
				IF uartRx = '1' THEN
					adrin(7 DOWNTO 0) <= uartin;
					uartRd <= '1';
					readcmd <= DELAY;
				END IF;
			ELSIF readcmd = DELAY THEN
				uartRd <= '0';
				IF uartRx = '0' THEN
					readcmd <= RXARG2;
				END IF;
			ELSIF readcmd = RXARG2 THEN
				-- rx data
				IF uartRx = '1' THEN
					din(15 DOWNTO 8) <= uartin;
					uartRd <= '1';
					readcmd <= DELAY2;
				END IF;
			ELSIF readcmd = DELAY2 THEN
				uartRd <= '0';
				IF uartRx = '0' THEN
					readcmd <= RXARG3;
				END IF;
			ELSIF readcmd = RXARG3 THEN
				IF uartRx = '1' THEN
					din(7 DOWNTO 0) <= uartin;
					uartRd <= '1';
					strb <= '1';
					readcmd <= WAITANSWER;
				END IF;
			ELSIF readcmd = WAITANSWER THEN
				uartRd <= '0';
				strb <= '0';
				IF busyout = '0' AND strb = '0' THEN
					readcmd <= SENDCMD;
					state <= ENDCOM;
				END IF;
			END IF;
		END PROCEDURE;

	BEGIN
		IF rst = RSTDEF THEN
			busy <= 'Z';
			uartout <= (others => 'Z');
			uartTx <= 'Z';
			uartRd <= 'Z';

			state <= EXECMD;
			maincmd <= EWEN;

			cmd <= (others => '0');
			strb <= '0';
			din <= (others => '0');
			adrin <= (others => '0');
			readcmd <= SENDCMD;

		ELSIF rising_edge(clk) THEN
			IF state = IDLE AND uartRx = '1' THEN
				IF uartin(7 DOWNTO 4) = DEVICEID AND busy /= '1' AND busyout /= '1' THEN
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
					state <= DEFCMD;
				END IF;
			ELSIF state = DEFCMD THEN
				CASE dataIN(3 DOWNTO 0) IS
					WHEN x"0" => -- read
						maincmd <= READ;
					WHEN x"1" => -- write
						maincmd <= WRITE;
					WHEN x"2" => -- erase
						maincmd <= ERASE;
					WHEN x"7" => -- read16
						maincmd <= READ16;
					WHEN x"8" => -- write16
						maincmd <= WRITE16;
					WHEN others =>
						state <= ENDCOM;
					END CASE;
				state <= EXECMD;
			ELSIF state = EXECMD THEN
				-- BEGIN handle command
				IF maincmd = ERASE THEN
					erasePro;
				ELSIF maincmd = READ THEN
					readPro;
				ELSIF maincmd = WRITE THEN
					writePro;
				ELSIF maincmd = EWEN THEN
					ewenPro;
				ELSIF maincmd = READ16 THEN
					read16Pro;
				ELSIF maincmd = WRITE16 THEN
					write16Pro;
				END IF;
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