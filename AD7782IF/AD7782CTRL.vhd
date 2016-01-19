LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY AD7782CTRL IS
	GENERIC(RSTDEF: std_logic := '1';
			DEVICEID: std_logic_vector(3 DOWNTO 0) := "0010");
	PORT(	rst:		IN	std_logic;
			swrst:		IN 	std_logic;
			clk:		IN	std_logic;
			busy:		INOUT	std_logic;							-- busy bit indicates working component
			busyLED:	OUT 	std_logic;

			uartin:		IN 	std_logic_vector(7 DOWNTO 0);
			uartout:		INOUT std_logic_vector(7 DOWNTO 0);
			uartRd:		INOUT std_logic; 						-- indicates value was read from controller
			uartTx:		INOUT std_logic;						-- starts transmission of new byte
			uartRx:		IN		std_logic;						-- indicates new byte is available to read
			uartTxReady:IN 	std_logic;						-- indicates new byte can be send
			
			ADCdin: 	IN 	std_logic;
			ADCrng: 	OUT	std_logic;
			ADCsel: 	OUT 	std_logic;  -- logic output which selects the active channel AIN1 (=0) or ANI2 (=1)
         ADCmode:	OUT 	std_logic;  -- logic output which selects master (=0) or slave (=1) mode of operation
         ADCcs:  	OUT 	std_logic;  -- chip select, low active
         ADCsclk:	OUT 	std_logic); -- serial clock output

END AD7782CTRL;

ARCHITECTURE behaviour OF AD7782CTRL IS
	CONSTANT AIN1: std_logic := '0';
	CONSTANT AIN2: std_logic := '1';
	CONSTANT RANGEHIG: std_logic := '1';
	CONSTANT RANGELOW: std_logic := '0';
	
	CONSTANT BYTE:	natural	:= 8;

	SIGNAL dataIN: std_logic_vector(7 DOWNTO 0);
	SIGNAL cnt:		std_logic_vector(2 DOWNTO 0);
	SIGNAL adcBUF: std_logic_vector(24-1 DOWNTO 0);
	SIGNAL startLED: std_logic;
	
	SIGNAL strb:	std_logic;									-- Inicial new AD Calculation
	SIGNAL csel:	std_logic;									-- select wich chanel is used AIN1(0), AIN2(1)
	SIGNAL rsel: 	std_logic;									-- select wich range is used 2.56V(1), 160mV(0)
	SIGNAL done:	std_logic;									-- get done if datas are valid on ch1/2 output (High Active)
	SIGNAL ch1:		std_logic_vector(24-1 DOWNTO 0);
	SIGNAL ch2:		std_logic_vector(24-1 DOWNTO 0);

	TYPE tstate IS (IDLE, READSENDOK, WAITSENDOK, DELAY, REDCMD, EXECMD, ENDCOM);
	TYPE ADCSTATE IS (S0, S1, S2, FB, SB, TB);
	TYPE UARTSTATE IS (S0, S1, S2);
	TYPE CMDSTATE	IS	(IDLE, RW, setAIN1, setAIN2, setRNGH, setRNGL);
	SIGNAL state:		tstate;
	SIGNAL adcs:		ADCSTATE;
	SIGNAL uarts:		UARTSTATE;
	SIGNAL cmds:		CMDSTATE;
	
	COMPONENT AD7782IF IS
   GENERIC(RSTDEF: std_logic := '1');
   PORT( rst:  IN  std_logic;  -- reset RSTDEF active
         clk:  IN  std_logic;  -- rising edge active, 1 MHz
         strb: IN  std_logic;  -- strobe, high active
         csel: IN  std_logic;  -- select wich chanel is used AIN1(0), AIN2(1)
         rsel: IN  std_logic;  -- select wich range is used 2.56V(1), 160mV(0)
         din:  IN  std_logic;  -- serial data input
         rng:  OUT std_logic;  -- logic output which configures the input range on the internal PGA
         sel:  OUT std_logic;  -- logic output which selects the active channel AIN1 (=0) or ANI2 (=1)
         mode: OUT std_logic;  -- logic output which selects master (=0) or slave (=1) mode of operation
         cs:   OUT std_logic;  -- chip select, low active
         sclk: OUT std_logic;  -- serial clock output
         done: OUT std_logic;  -- set done if datas are valid on ch1/2 output (High Active)
         ch1:  OUT std_logic_vector(24-1 DOWNTO 0);
         ch2:  OUT std_logic_vector(24-1 DOWNTO 0));
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

BEGIN
	adcBUF <= ch1 WHEN csel='0' ELSE ch2 WHEN csel='1';
	
	adif: AD7782IF
	GENERIC MAP(RSTDEF => RSTDEF)
	PORT MAP(rst 	=> rst,
				clk 	=> clk,
				strb 	=> strb,
				csel 	=> csel,
				rsel 	=> rsel,
				din 	=> ADCdin,
				rng	=> ADCrng,
				sel	=> ADCsel,
				mode	=> ADCmode,
				cs 	=> ADCcs,
				sclk 	=> ADCsclk,
				done	=> done,
				ch1 	=> ch1,
				ch2	=> ch2);

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
	
	PROCEDURE readADwriteUART IS
	BEGIN
		CASE adcs IS
			WHEN S0 =>				-- set strb to '1'
				strb	<= '1';
				adcs		<= S1;	
			WHEN S1 =>				-- set strb back to '0'
				strb 	<= '0';
				adcs		<= S2;
			WHEN S2 =>				-- wait for AD Conversion
				IF done='1' THEN
					adcs	<= FB;
				END IF;
			WHEN FB => 				-- Send first Byte
				CASE uarts IS
					WHEN S0 =>		-- Set uartOUT and uartTx
						uartout 	<= adcBUF(23 DOWNTO 16);
						uartTx	<= '1';
						uarts			<= S1;
					WHEN S1 =>		-- Wait on Ready
						IF uartTxReady='0' THEN
							uartTx	<= '0';
							uarts			<= S2;
						END IF;
					WHEN S2 =>
						IF uartTxReady='1' THEN
							uarts 	<= S0;
							adcs		<= SB;
						END IF;
				END CASE;
			WHEN SB => 				-- Send second Byte
				CASE uarts IS
					WHEN S0 =>
						uartout 	<= adcBUF(15 DOWNTO 8);
						uartTx	<= '1';
						uarts			<= S1;
					WHEN S1 =>
						IF uartTxReady='0' THEN
							uartTx	<= '0';
							uarts			<= S2;
						END IF;
					WHEN S2 =>
						IF uartTxReady='1' THEN
							uarts 	<= S0;
							adcs		<= TB;
						END IF;
				END CASE;
			WHEN TB => 				-- Send third(last) Byte
				CASE uarts IS
					WHEN S0 =>
						uartout 	<= adcBUF(7 DOWNTO 0);
						uartTx	<= '1';
						uarts			<= S1;
					WHEN S1 =>
						IF uartTxReady='0' THEN
							uartTx	<= '0';
							uarts			<= S2;
						END IF;
					WHEN S2 =>
						IF uartTxReady='1' THEN
							uarts 	<= S0;
							adcs		<= S0;
							state <= ENDCOM;
							cmds	<= IDLE;
						END IF;
				END CASE;
		END CASE;
	END PROCEDURE;

	PROCEDURE reset IS
	BEGIN
		busy <= 'Z';
		uartout <= (others => 'Z');
		uartTx <= 'Z';
		uartRd <= 'Z';
		startLED <= '0';
		
		csel 	<= AIN1;
		rsel	<= RANGEHIG;
		cmds	<= IDLE;
		strb	<= '0';
		cnt	<= (OTHERS => '0');

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
					startLED <= '1';
					
					cnt	<= (OTHERS => '0');
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
					state <= REDCMD;
				END IF;
			ELSIF state = REDCMD THEN
				-- BEGIN handle command
				CASE dataIN(3 DOWNTO 0) IS
					WHEN X"0" =>
						cmds	<= RW;
					WHEN X"3" =>
						cmds	<= setAIN1;
					WHEN X"4" =>
						cmds	<= setAIN2;
					WHEN X"5" =>
						cmds	<= setRNGH;
					WHEN X"6" =>
						cmds	<= setRNGL;
					WHEN others =>
						cmds	<= IDLE;
				END CASE;
				state <= EXECMD;
			ELSIF state = EXECMD THEN
				CASE cmds IS									-- (IDLE, RW, setAIN1, setAIN2, setRNGH, setRNGL)
					WHEN IDLE 	=>
						-- Do Nothing |_|>
					WHEN RW		=>
						readADwriteUART;
					WHEN setAIN1 =>
						csel 	<= AIN1;
						state <= ENDCOM;
					WHEN setAIN2 =>
						csel	<= AIN2;
						state <= ENDCOM;
					WHEN setRNGH =>
						rsel	<= RANGEHIG;
						state <= ENDCOM;
					WHEN setRNGL =>
						rsel	<= RANGELOW;
						state	<= ENDCOM;
				END CASE;
			ELSIF state = ENDCOM THEN
				uartout <= (others => 'Z');
				uartTx <= 'Z';
				uartRd <= 'Z';
				busy <= 'Z';
				state <= IDLE;
				startLED <= '0';
				
				cnt	<= (OTHERS => '0');
			END IF;
			IF swrst = RSTDEF THEN
				reset;
			END IF;
		END IF;
	END PROCESS;

END behaviour;