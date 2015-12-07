LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY EEPROM93LC66IF_tb IS
   -- empty
END EEPROM93LC66IF_tb;

ARCHITECTURE verhalten OF EEPROM93LC66IF_tb IS

   CONSTANT RSTDEF: std_logic := '0';
   CONSTANT FRQDEF: natural   := 4e6;
   CONSTANT tcyc:   time      := 1 sec / FRQDEF;

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

   COMPONENT EEPROM93LC66
   PORT(sclk:		IN std_logic;
			 cs:			IN std_logic;
			 din:			IN std_logic;
			 dout:			OUT std_logic;
			 org:			IN std_logic);
   END COMPONENT;



   SIGNAL rst:  std_logic := RSTDEF;
   SIGNAL clk:  std_logic := '0';
   SIGNAL cmd:	std_logic_vector (3 DOWNTO 0) := (others => '0');
   SIGNAL strb: std_logic := '0';
   SIGNAL dout: std_logic_vector(15 DOWNTO 0) := (others =>'0');
   SIGNAL din: 	std_logic_vector(15 DOWNTO 0) := (others => '0');
   SIGNAL adrin:std_logic_vector(8 DOWNTO 0) := (others =>'0');
   SIGNAL busyout: std_logic := '0';

   SIGNAL sclk:	std_logic := '0';
   SIGNAL cs:	std_logic := '0';
   SIGNAL mosi:	std_logic := '0';
   SIGNAL miso:	std_logic := '0';
   SIGNAL org:	std_logic := '0';

BEGIN

	clk <= NOT clk AFTER tcyc/2;

   u1: EEPROM93LC66
   PORT MAP(sclk => sclk,
            cs   => cs,
            din  => mosi,
            dout => miso,
			org => org);

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

	p1: PROCESS
		PROCEDURE eeprom_com (cmdTest: std_logic_vector; address: std_logic_vector;
							dataIn: std_logic_vector) IS
			
		BEGIN
			cmd <= cmdTest;
			adrin <= address;
			din <= dataIn;

			WAIT UNTIL clk = '0';
			strb <= '1';
			WAIT UNTIL clk = '1';
			strb <= '0';
			WAIT UNTIL busyout = '0';

			
		END PROCEDURE;
		
	BEGIN
   		WAIT FOR 1 us;
   		rst <= NOT RSTDEF;

   		eeprom_com("1110", "000000000", "0000000000000000");
      
      	REPORT "all tests done..." SEVERITY note;
		WAIT;


	END PROCESS;

END verhalten;