LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_signed.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY echoUart IS
	PORT(    rst:		IN	std_logic;
			 clk:		IN	std_logic;
			 rxd:		IN 	std_logic;
			 txd:   	OUT  std_logic;

			 busy:		OUT	std_logic			-- busy bit indicates working eeprom, dout not valid
	);

END echoUart;

ARCHITECTURE behaviour OF echoUart IS

	CONSTANT RSTDEF: std_logic :='0';

	COMPONENT uart IS
	   GENERIC(RSTDEF: std_logic;
			   BAUDEF: real;  -- baud rate
			   FRQDEF: real);  -- clock frequency
	   PORT(rst:   IN  std_logic;  -- reset RSTDEF active
			clk:   IN  std_logic;  -- clock, rising edge active
			swrst: IN  std_logic;  -- software reset,  RSTDEF active
			ena:   IN  std_logic;  -- enable,          high active

			rxd:   IN  std_logic;  -- receive data
			rden:  IN  std_logic;  -- read enable,     high active
			dout:  OUT std_logic_vector(7 DOWNTO 0);
			rhrf:  OUT std_logic;  -- RHR full,        high active
			ovre:  OUT std_logic;  -- overrun error,   high active
			frme:  OUT std_logic;  -- framing error,   high active

			txd:   OUT std_logic;  -- transmit data output, high active
			wren:  IN  std_logic;  -- write enable, high active
			din:   IN  std_logic_vector(7 DOWNTO 0); -- data input
			tsre:  OUT std_logic;  -- transmit shift   register empty, high active
			thre:  OUT std_logic); -- transmit holding register empty, high active
	END COMPONENT;

	SIGNAL din: std_logic_vector(7 DOWNTO 0);
	SIGNAL dout:std_logic_vector(7 DOWNTO 0);
	
	SIGNAL rxNewByte: std_logic;
	SIGNAL rxNewByteRead: std_logic;
	SIGNAL txWriteByte: std_logic;
	SIGNAL tsre: std_logic;
	SIGNAL thre: std_logic;
	SIGNAL sbusy: std_logic;

BEGIN

	u1: uart
	GENERIC MAP(RSTDEF => RSTDEF,
				BAUDEF => 9.6e3,
				FRQDEF => 1.0e6)
	PORT MAP(rst => rst,
			clk => clk,
			swrst => NOT RSTDEF,
			ena => '1',

			rxd => rxd,
			rden => rxNewByteRead,
			dout => dout,
			rhrf => rxNewByte,
			--ovre:  OUT std_logic;  -- overrun error,   high active
			--frme:  OUT std_logic;  -- framing error,   high active

			txd => txd,
			wren=> txWriteByte,
			din => din,
			tsre => tsre,  -- transmit shift   register empty, high active
			thre => thre -- transmit holding register empty, high active
			);
			
	main: PROCESS(rst, clk) IS
	
	BEGIN
		IF rst = RSTDEF THEN
			din <= (others => '0');
			
			rxNewByteRead <= '0';
			txWriteByte	<= '0';
			
			sbusy <= '0';
		ELSIF rising_edge(clk) THEN
			IF rxNewByte = '1' AND rxNewByteRead = '0' THEN
				rxNewByteRead <= '1';
				din <= dout;
				txWriteByte <= '1';
				sbusy <= NOT sbusy;
			ELSE
				txWriteByte <= '0';
				rxNewByteRead <= '0';
			END IF;
		END IF;
		
	busy <= sbusy;
	
	END PROCESS;

END behaviour;