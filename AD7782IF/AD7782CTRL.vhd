LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY AD7782CTRL IS
	GENERIC(RSTDEF: std_logic := '1';
			DEVICEID: std_logic_vector(3 DOWNTO 0) := "0000");
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

	SIGNAL dataIN: std_logic_vector(7 DOWNTO 0);
	
	SIGNAL strb:	std_logic;									-- Inicial new AD Calculation
	SIGNAL csel:	std_logic;									-- select wich chanel is used AIN1(0), AIN2(1)
	SIGNAL rsel: 	std_logic;									-- select wich range is used 2.56V(1), 160mV(0)
	SIGNAL done:	std_logic;									-- get done if datas are valid on ch1/2 output (High Active)
	SIGNAL ch1:		std_logic_vector(24-1 DOWNTO 0);
	SIGNAL ch2:		std_logic_vector(24-1 DOWNTO 0);

	TYPE tstate IS (IDLE, READSENDOK, WAITSENDOK, DELAY, EXECMD, ENDCOM);
	SIGNAL state: tstate;
	
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
					WHEN "0000" =>
						uartout <= x"02";
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
		END IF;
	END PROCESS;

END behaviour;