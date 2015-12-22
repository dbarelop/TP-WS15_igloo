LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY EEPROMCTRL IS
	GENERIC(RSTDEF: std_logic := '1';
			DEVICEID: std_logic_vector(3 DOWNTO 0) := "0001");
	PORT(    rst:		IN	std_logic;
			 clk:		IN	std_logic;
			 
			 uartin:	IN 	std_logic_vector(7 DOWNTO 0);
			 uartRx:	IN	std_logic;						-- indicates new byte is available
			 uartRd:	INOUT std_logic; 						-- indicates value was read from controller
			 uartout:   INOUT std_logic_vector(7 DOWNTO 0);
			 uartTxReady: IN std_logic;						-- indicates new byte can be send
			 uartTx:	INOUT std_logic;						-- starts transmission of new byte
			 
			 busy:		INOUT	std_logic;					-- busy bit indicates working component
			-- component pins
			sclk:		OUT std_logic;
			cs:			OUT std_logic;
			mosi:		OUT std_logic;
			miso:		IN std_logic;
			org:		OUT std_logic
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
	TYPE tmaincmd IS (READ, WRITE, ERASE, EWEN);
	
	SIGNAL state: tstate;
	SIGNAL maincmd: tmaincmd;
	SIGNAL dataIN: std_logic_vector(7 DOWNTO 0);
    SIGNAL sbusy: std_logic;

    TYPE tcmd IS (SENDCMD, WAITANSWER, TXANSWER);
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

		PROCEDURE re4d IS
			
		BEGIN
			IF readcmd = SENDCMD THEN
				cmd <= "0010";
				strb <= '1';
                readcmd <= WAITANSWER;
			ELSIF readcmd = WAITANSWER THEN
				strb <= '0';
				IF busyout = '0' THEN
					readcmd <= TXANSWER;
				END IF;
			ELSIF readcmd = TXANSWER THEN
				uartout <= dout(7 DOWNTO 0);
				uartTx <= '1';
				state <= ENDCOM;
				readcmd <= SENDCMD;
			END IF;

		END PROCEDURE;

		PROCEDURE ewenPro IS

		BEGIN
			IF readcmd = SENDCMD THEN
				cmd <= "1110";
				strb <= '1';
				readcmd <= WAITANSWER;
			ELSIF readcmd = WAITANSWER THEN
				strb <= '0';
				IF busyout = '0' THEN
					readcmd <= SENDCMD;
					state <= ENDCOM;
				END IF;
			END IF;
		END PROCEDURE;

		PROCEDURE erasePro IS

		BEGIN
			IF readcmd = SENDCMD THEN
				cmd <= "1100";
				strb <= '1';
				readcmd <= WAITANSWER;
			ELSIF readcmd = WAITANSWER THEN
				strb <= '0';
				IF busyout = '0' THEN
					readcmd <= SENDCMD;
					state <= ENDCOM;
				END IF;
			END IF;
		END PROCEDURE;

		PROCEDURE writePro IS

		BEGIN
			IF readcmd = SENDCMD THEN
				cmd <= "0001"; --write
				din(7 DOWNTO 0) <= x"BB";
				strb <= '1';
				readcmd <= WAITANSWER;
			ELSIF readcmd = WAITANSWER THEN
				strb <= '0';
				IF busyout = '0' THEN
					readcmd <= SENDCMD;
					state <= ENDCOM;
				END IF;
			END IF;	
		END PROCEDURE;

	BEGIN
		IF rst = RSTDEF THEN
			sbusy <= 'Z';
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
                    state <= DEFCMD;
                END IF;
            ELSIF state = DEFCMD THEN
            	CASE dataIN(3 DOWNTO 0) IS
            		WHEN x"0" => -- read
            			maincmd <= READ;
                    WHEN x"1" => --write
                        maincmd <= WRITE;
            		WHEN x"2" => -- erase
            			maincmd <= ERASE;
            		WHEN others =>
                        state <= ENDCOM;
            	END CASE;
                state <= EXECMD;
			ELSIF state = EXECMD THEN				
				-- BEGIN handle command
				IF maincmd = ERASE THEN
					erasePro;
				ELSIF maincmd = READ THEN
					re4d;
                ELSIF maincmd = WRITE THEN
                    writePro;
				ELSIF maincmd = EWEN THEN
					ewenPro;
				END IF;
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