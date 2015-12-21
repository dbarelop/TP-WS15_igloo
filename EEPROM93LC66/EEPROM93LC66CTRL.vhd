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
			 uartRd:	OUT std_logic; 						-- indicates value was read from controller
			 uartout:   OUT std_logic_vector(7 DOWNTO 0);
			 uartTxReady: IN std_logic;						-- indicates new byte can be send
			 uartTx:	OUT std_logic;						-- starts transmission of new byte
			 
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


	TYPE tstate IS (IDLE, READSENDOK, WAITSENDOK, DELAY, EXECMD, ENDCOM);
	
	SIGNAL state: tstate;
	SIGNAL dataIN: std_logic_vector(7 DOWNTO 0);
    SIGNAL sbusy: std_logic;

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
			TYPE tcmd IS (SENDCMD, WAITANSWER, TXANSWER);
			SIGNAL readcmd: tcmd;
		BEGIN
			IF readcmd = SENDCMD THEN
				cmd <= "0010";
				strb <= '1';
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

	BEGIN
		IF rst = RSTDEF THEN
			sbusy <= 'Z';
			uartout <= (others => 'Z');
			uartTx <= 'Z';
			uartRd <= 'Z';
			
			state <= IDLE;

			cmd <= (others => '0');
			strb <= '0';
			din <= (others => '0');
			adrin <= (others => '0');

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
				re4d;
				--CASE dataIN(3 DOWNTO 0) IS
				--	WHEN others =>
				--		uartout <= x"01";
                --        uartTx <= '1';
                --        state <= ENDCOM;
				--END CASE;
				-- END handle command
				state <= 
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