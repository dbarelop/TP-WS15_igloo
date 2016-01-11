LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY AD7782CTRL IS
	GENERIC(RSTDEF: std_logic := '1';
			DEVICEID: std_logic_vector(3 DOWNTO 0) := "0010");
	PORT(	rst:		IN	std_logic;
			clk:		IN	std_logic;
			busy:		INOUT	std_logic;							-- busy bit indicates working component

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
	SIGNAL blockCMDs: std_logic := '0';
	
	SIGNAL strb:	std_logic;									-- Inicial new AD Calculation
	SIGNAL csel:	std_logic;									-- select wich chanel is used AIN1(0), AIN2(1)
	SIGNAL rsel: 	std_logic;									-- select wich range is used 2.56V(1), 160mV(0)
	SIGNAL done:	std_logic;									-- get done if datas are valid on ch1/2 output (High Active)
	SIGNAL ch1:		std_logic_vector(24-1 DOWNTO 0);
	SIGNAL ch2:		std_logic_vector(24-1 DOWNTO 0);

	TYPE tstate IS (IDLE, READSENDOK, WAITSENDOK, DELAY, EXECMD, ENDCOM);
	TYPE pstate IS (S0, S1, S2, FB, SB, TB);
	TYPE sstate IS (S0, S1, S2, D0, D1);
	SIGNAL state:	tstate;
	SIGNAL ps: 		pstate;
	SIGNAL ss:		sstate;
	
	
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

BEGIN
	adcBUF <= ch1 WHEN csel='0' ELSE ch2 WHEN csel='1';
	
	u1: AD7782IF
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

	main: PROCESS (clk, rst) IS
	
	PROCEDURE readADwriteUART IS
	BEGIN
		CASE ps IS
			WHEN S0 =>				-- set strb to '1'
				blockCMDs <= '1';
				strb	<= '1';
				ps		<= S1;	
			WHEN S1 =>				-- set strb back to '0'
				strb 	<= '0';
				ps		<= S2;
			WHEN S2 =>				-- wait for AD Conversion
				IF done='1' THEN
					ps	<= FB;
				END IF;
			WHEN FB => 				-- Send first Byte
				CASE ss IS
					WHEN S0 =>
						uartout 	<= adcBUF(7 DOWNTO 0);
						uartTx	<= '1';
						ss			<= S1;
					WHEN S1 =>
						IF uartTxReady='0' THEN
							uartTx	<= '0';
							ss			<= S2;
						END IF;
					WHEN S2 =>
						IF uartTxReady='1' THEN
							ss 	<= S0;
							ps		<= SB;
						END IF;
				END CASE;
			WHEN SB => 				-- Send second Byte
				CASE ss IS
					WHEN S0 =>
						uartout 	<= adcBUF(15 DOWNTO 8);
						uartTx	<= '1';
						ss			<= S1;
					WHEN S1 =>
						IF uartTxReady='0' THEN
							uartTx	<= '0';
							ss			<= S2;
						END IF;
					WHEN S2 =>
						IF uartTxReady='1' THEN
							ss 	<= S0;
							ps		<= TB;
						END IF;
				END CASE;
			WHEN TB => 				-- Send third(last) Byte
				CASE ss IS
					WHEN S0 =>
						uartout 	<= adcBUF(23 DOWNTO 16);
						uartTx	<= '1';
						ss			<= S1;
					WHEN S1 =>
						IF uartTxReady='0' THEN
							uartTx	<= '0';
							ss			<= S2;
						END IF;
					WHEN S2 =>
						IF uartTxReady='1' THEN
							ss 	<= S0;
							ps		<= S0;
							blockCMDs <= '0';
						END IF;
				END CASE;
		END CASE;
	END PROCEDURE
	
	BEGIN
		IF rst = RSTDEF THEN
			busy <= 'Z';
			uartout <= (others => 'Z');
			uartTx <= 'Z';
			uartRd <= 'Z';
			
			csel 	<= AIN1;
			rsel	<= RANGEHIG;
			strb	<= '0';
			cnt	<= (OTHERS => '0');

			state <= IDLE;
		ELSIF rising_edge(clk) THEN
			IF state = IDLE AND uartRx = '1' THEN
				IF uartin(7 DOWNTO 4) = DEVICEID AND busy /= '1' THEN
					busy <= '1';
					uartRd <= '1';
					dataIN <= uartin;
					state <= READSENDOK;
					
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
					state <= EXECMD;
				END IF;
			ELSIF state = EXECMD THEN
				-- BEGIN handle command
				IF blockCMDs='0' THEN
					CASE dataIN(3 DOWNTO 0) IS
						WHEN X"0" =>
							readADwriteUART;
						WHEN X"3" =>
							csel <= AIN1;
						WHEN X"4" =>
							csel <= AIN2;
						WHEN X"5" =>
							rsel <= RANGEHIG;
						WHEN X"6" =>
							rsel <= RANGELOW;
						WHEN others =>
							state <= ENDCOM;
					END CASE;
					state <= ENDCOM;
				END IF;
				-- END handle command
			ELSIF state = ENDCOM THEN
				uartout <= (others => 'Z');
				uartTx <= 'Z';
				uartRd <= 'Z';
				busy <= 'Z';
				state <= IDLE;
				
				cnt	<= (OTHERS => '0');
			END IF;
		END IF;
	END PROCESS;

END behaviour;