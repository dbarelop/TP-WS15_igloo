LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY EEPROM93LC66CTRL_tb IS
   -- empty
END EEPROM93LC66CTRL_tb;

ARCHITECTURE verhalten OF EEPROM93LC66CTRL_tb IS

   CONSTANT RSTDEF: std_logic := '0';
   CONSTANT FRQDEF: natural   := 4e6;
   CONSTANT tcyc:   time      := 1 sec / FRQDEF;

   CONSTANT cmd_wr: std_logic_vector := "001";

   COMPONENT EEPROMCTRL
    GENERIC(RSTDEF: std_logic ;
			DEVICEID: std_logic_vector);
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
   END COMPONENT;

   COMPONENT EEPROM93LC66
   PORT(sclk:		IN std_logic;
			 cs:			IN std_logic;
			 din:			IN std_logic;
			 dout:			OUT std_logic;
			 org:			IN std_logic);
   END COMPONENT;



   SIGNAL rst:  std_logic := RSTDEF;
   SIGNAL clk:  std_logic := '0';
   SIGNAL sclk: std_logic := '0';
   SIGNAL cs:	std_logic := '0';
   SIGNAL mosi: std_logic := '0';
   SIGNAL miso: std_logic := '0';
   SIGNAL org: 	std_logic := '0';

   SIGNAL uartin:std_logic_vector(7 DOWNTO 0) := (others => '0');
   SIGNAL uartRx:std_logic:= '0';
   SIGNAL uartRd:std_logic:= '0';
   SIGNAL uartout:std_logic_vector(7 DOWNTO 0) := (others => '0');
   SIGNAL uartTxReady:std_logic :='0';
   SIGNAL uartTx: std_logic:='0';
   SIGNAL busy:	std_logic := '0';

BEGIN

	clk <= NOT clk AFTER tcyc/2;

   u1: EEPROM93LC66
   PORT MAP(sclk => sclk,
            cs   => cs,
            din  => mosi,
            dout => miso,
	    org => org);

   u2: EEPROMCTRL
   GENERIC MAP(RSTDEF => RSTDEF,
   				DEVICEID => "0001")
   PORT MAP(rst		=>	rst,	
			clk		=>	clk,
			uartin	=>	uartin,
			uartRx	=>	uartRx,
			uartRd	=>	uartRd,
			uartout	=>  uartout,
			uartTxReady	=>	uartTxReady,
			uartTx	=>	uartTx,
			busy	=>	busy,
			sclk	=>	sclk,
			cs		=>	cs,	
			mosi	=>	mosi,
			miso	=>	miso,
			org		=>	org
	);



	p1: PROCESS
		VARIABLE n_bytes: integer;

		PROCEDURE uartSendN (dataIn: std_logic_vector((n_bytes*8)-1 DOWNTO 0); result: std_logic_vector) IS
			VARIABLE dataInLength: INTEGER := dataIn'LENGTH-1;
		BEGIN
			uartin <= dataIn(dataInLength DOWNTO dataInLength-7);
			uartRx <= '1';
			WAIT UNTIL uartRd = '1';
			uartRx <= '0';
			WAIT UNTIL uartTx = '1';
			assert uartout = x"AA" report "OK message failed";
			uartTxReady <= '1';
			WAIT UNTIL uartTx = '0';
			FOR i in 1 to n_bytes-1 LOOP
				uartin <= dataIn(dataInLength-8*i DOWNTO dataInLength-15*i);
				uartRx <= '1';
				WAIT UNTIL uartRd = '1';
				uartRx <= '0';
				WAIT UNTIL uartRd = '0';
			END LOOP;
			IF result'LENGTH = 8 THEN
				WAIT UNTIL uartTx = '1';
				assert uartout = result report "wrong result";
			END IF;

		END PROCEDURE;
		
	BEGIN
   		WAIT FOR 1 us;
   		rst <= NOT RSTDEF;
   		
   		--uartSend("00010000", "11111111");
		--uartSendNoResult("00010001");
   		--uartSend("00010000", x"BB");
		--uartSendNoResult("00010010");
		--uartSend("00010000", x"FF");
		n_bytes:= 2;
		uartSendN("00010000"&"00000000", "11111111");
		n_bytes:= 1;
		uartSendN("00010001", "0");
		n_bytes:= 2;
		uartSendN("00010000"&"00000000", x"BB");

      	REPORT "all tests done..." SEVERITY note;
	WAIT;

	END PROCESS;

END verhalten;