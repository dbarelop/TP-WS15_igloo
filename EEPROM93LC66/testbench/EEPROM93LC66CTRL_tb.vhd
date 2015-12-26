LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

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
		PROCEDURE uartTX (dataIn: std_logic_vector) IS
			
		BEGIN
			uartin <= dataIn;
			uartRx <= '1';
			WAIT UNTIL uartRd = '1';

			
		END PROCEDURE;
		
	BEGIN
   		WAIT FOR 1 us;
   		rst <= NOT RSTDEF;

   		


      	REPORT "all tests done..." SEVERITY note;
		WAIT;


	END PROCESS;

END verhalten;