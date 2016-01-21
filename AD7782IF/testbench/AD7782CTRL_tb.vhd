LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY AD7782CTRL_tb IS
	-- empty
END AD7782CTRL_tb;

ARCHITECTURE behaviour OF AD7782CTRL_tb IS

	COMPONENT AD7782CTRL IS
		GENERIC(RSTDEF: std_logic := '1';
				DEVICEID: std_logic_vector(3 DOWNTO 0) := "0010");
		PORT(	rst:		IN	std_logic;
				swrst:	IN std_logic;
				clk:		IN	std_logic;
				busyLED:	OUT std_logic;
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
	END COMPONENT;

   COMPONENT AD7782
      GENERIC(ref: real);
      PORT( ain1: IN  real;        -- analog input: +/- Ref
            ain2: IN  real;        -- analog input: +/- Ref
            rng:  IN  std_logic;   -- logic input which configures the input range on the internal PGA
            sel:  IN  std_logic;   -- logic input which selects the active channel AIN1 oo ANI2
            mode: IN  std_logic;   -- logic input which selects master (=0) or slave (=1) mode of operation
            sclk: IN  std_logic;   -- serial clock output
            cs:   IN  std_logic;   -- chip select, low active
            dout: OUT std_logic);  -- serial data output
   END COMPONENT;
	
	CONSTANT RSTDEF: 	std_logic 	:= '0';
	CONSTANT FRQDEF: 	natural		:= 4e6;
	CONSTANT tcyc:		time		:= 1 sec / FRQDEF;

	SIGNAL clk:				std_logic := '0';
	SIGNAL rst:				std_logic := RSTDEF;
	
	SIGNAL uartin:			std_logic_vector(7 DOWNTO 0) := (others => '0');
	SIGNAL uartout:		std_logic_vector(7 DOWNTO 0) := (others => '0');
	SIGNAL uartRx:			std_logic := '0';
	SIGNAL uartRd:			std_logic := '0';
	SIGNAL uartTxReady:	std_logic := '1';
	SIGNAL uartTx:			std_logic := '0';
	
	SIGNAL ADCdin:			std_logic;
	SIGNAL ADCrng:			std_logic;
	SIGNAL ADCsel: 		std_logic;
	SIGNAL ADCcs:			std_logic;
	SIGNAL ADCsclk:		std_logic;
	SIGNAL ADCmode:		std_logic;

	SIGNAL busy:		std_logic := '0';
	SIGNAL swrst:		std_logic := NOT RSTDEF;
	SIGNAL busyLED:	std_logic := '0';
	SIGNAL serOut:		std_logic_vector(7 DOWNTO 0) := (others => '0');

   SIGNAL ain1    : real := 0.0;
   SIGNAL ain2    : real := 0.0;
	
BEGIN
	clk <= NOT clk AFTER tcyc/2;

	ctrl: AD7782CTRL
	GENERIC MAP(RSTDEF	=>	RSTDEF,
			DEVICEID	=>	"0010")
	PORT MAP(rst	=> rst,
				swrst => swrst,
				clk	=> clk,
				busy	=> busy,								-- busy bit indicates working component
				busyLED => busyLED,

				uartin			=> uartin,
				uartout			=> uartout,
				uartRd			=> uartRd,				-- indicates value was read from controller
				uartTx			=> uartTx,				-- starts transmission of new byte
				uartRx			=> uartRx,				-- indicates new byte is available to read
				uartTxReady		=> uartTxReady,		-- indicates new byte can be send
				
				ADCdin			=> ADCdin,
				ADCrng			=> ADCrng,
				ADCsel			=> ADCsel,				-- logic output which selects the active channel AIN1 (=0) or ANI2 (=1)
				ADCmode			=> ADCmode,				-- logic output which selects master (=0) or slave (=1) mode of operation
				ADCcs				=> ADCcs,				-- chip select, low active
				ADCsclk			=> ADCsclk);			-- serial clock output

	adc: AD7782
   GENERIC MAP(ref => 2.5)
   PORT MAP(ain1 => ain1,
            ain2 => ain2,
            rng  => ADCrng,
            sel  => ADCsel,
            mode => ADCmode,
            sclk => ADCsclk,
            cs   => ADCcs,
            dout => ADCdin);
				
	test: PROCESS IS

		VARIABLE n_rxbytes: integer;
		VARIABLE n_txbytes: integer;

		PROCEDURE setNBytes(rxBytes: integer; txBytes: integer) IS
		BEGIN
			n_rxbytes := rxBytes;
			n_txbytes := txBytes;
		END PROCEDURE;

		PROCEDURE uartSendN (dataIn: std_logic_vector((n_rxbytes*8)-1 DOWNTO 0); result: std_logic_vector((n_txbytes*8)-1 DOWNTO 0); ain: real) IS
			VARIABLE dataInLength: INTEGER := dataIn'LENGTH-1;
			VARIABLE dataOutLength: INTEGER := result'LENGTH-1;
		BEGIN
			ain1 <= ain;
			ain2 <= ain;
			WAIT UNTIL rising_edge(clk);
			
			uartin <= dataIn(dataInLength DOWNTO dataInLength-7);
			uartRx <= '1';
			WAIT UNTIL uartRd = '1';
			uartRx <= '0';
			WAIT UNTIL uartTx = '1';
			assert uartout = x"AA" report "OK message failed";
			uartTxReady <= '0';
			WAIT FOR 1 us;
			uartTxReady <= '1';
			IF uartTx /= '0' THEN
				WAIT UNTIL uartTx = '0';
			END IF;
			FOR i in 1 to n_rxbytes-1 LOOP
				uartin <= dataIn(dataInLength-8*i DOWNTO dataInLength-8*i-7);
				uartRx <= '1';
				IF uartRd = '0' THEN
					WAIT UNTIL uartRd = '1';
				END IF;
				uartRx <= '0';
				IF uartRd = '1' THEN
					WAIT UNTIL uartRd = '0';
				END IF;
			END LOOP;
			IF result'LENGTH >= 8 THEN
				FOR i in 0 to n_txbytes-1 LOOP
					WAIT UNTIL uartTx = '1';
					assert uartout = result(dataOutLength-8*i DOWNTO dataOutLength-8*i-7) report "wrong result at AIN := " & real'image(ain);
					uartTxReady <= '0';
					WAIT FOR 1 us;
					uartTxReady <= '1';
					IF uartTx = '1' THEN
						WAIT UNTIL uartTx = '0';
					END IF;
				END LOOP;
			END IF;

		END PROCEDURE;
	BEGIN
		WAIT FOR 1 us;
		rst <= NOT RSTDEF;

		setNBytes(1,0);
		uartSendN(X"23", X"", 0.0);			-- ch1
		uartSendN(X"25", X"", 0.0);			-- rng1	(2.56V)
		
		setNBytes(1, 3);
		uartSendN(X"20", X"350000", -1.5);
		uartSendN(X"20", X"670000", -0.5);
		uartSendN(X"20", X"800000", 0.0);
		uartSendN(X"20", X"990000", 0.5);
		uartSendN(X"20", X"CB0000", 1.5);
		uartSendN(X"20", X"FD0000", 2.5);

		setNBytes(1,0);
		uartSendN(X"24", X"", 0.0);			-- ch2
		uartSendN(X"26", X"", 0.0);			-- rng2 	(0.16V)
		
		setNBytes(1,3);
		uartSendN(X"20", X"FFFFFF", 5.0);
		uartSendN(X"20", X"FFFFFF", 0.16);
		uartSendN(X"20", X"980000", 0.03);
		uartSendN(X"20", X"800000", 0.0);
		uartSendN(X"20", X"680000", -0.03);
		uartSendN(X"20", X"000000", -0.16);
		uartSendN(X"20", X"000000", -5.0);
		
		setNBytes(1,0);
		uartSendN(X"25", X"", 0.0);			-- rng1	(2.56V)
		
		setNBytes(1,3);
		uartSendN(X"20", X"FD0000", 2.5);
		uartSendN(X"20", X"030000", -2.5);
		
		
		REPORT "all tests done..." SEVERITY note;
		WAIT;

	END PROCESS;

END behaviour;