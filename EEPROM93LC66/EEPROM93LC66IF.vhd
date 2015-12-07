LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_signed.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY EEPROM93LC66IF IS
	GENERIC(RSTDEF: std_logic := '1');
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
END EEPROM93LC66IF;

-- comands:
-- X001		WRITE address
-- X010		READ  address
-- X011		ERASE address
-- X100		ERASE all
-- X101		WRITE all
-- X110		EWEN
-- X111		EWDS
-- X 		org =1 16bit / =0 8bit

ARCHITECTURE behaviour OF EEPROM93LC66IF IS

   	TYPE tstate IS (IDLE, BUSY, WAITEEPROM);

   	SIGNAL state:		tstate;
	SIGNAL serialOut: 	std_logic_vector(26 DOWNTO 0);
	SIGNAL serialIn:	std_logic_vector(15 DOWNTO 0);
	SIGNAL serClk:		std_logic;
	SIGNAL busyS:		std_logic;

	SIGNAL outCnt:		integer RANGE 0 TO 27;
	SIGNAL MemAccess:	std_logic;

BEGIN

	main: PROCESS(rst, clk) IS
		

	BEGIN
		IF rst = RSTDEF THEN
			dout <= (others => '0');
			busyS <= '0';

			cs <= '0';
			org <= '0';
			serialOut <= (others => '0');
			serialIn <= (others => '0');

			state <= IDLE;
			serClk <= '0';

			outCnt <= 0;
			MemAccess <= '0';
		ELSIF rising_edge(clk) THEN
			CASE state IS
				WHEN IDLE =>
					IF strb = '1' THEN
						cs <= '1';
						CASE cmd IS
							--16bit
							WHEN "1001" => --16bit write
								serialOut <= "101" & adrin(7 DOWNTO 0) & din;
								outCnt <= 27;
								MemAccess <= '1';
							WHEN "1010" => --16bit read
								serialOut <= "110" & adrin(7 DOWNTO 0) & "0000000000000000";
								outCnt <= 27;
							WHEN "1011" => --16bit erase
								serialOut <= "111" & adrin(7 DOWNTO 0) & "0000000000000000";
								outCnt <= 11;
								MemAccess <= '1';
							WHEN "1100" => --16bit eral
								serialOut <= "10010000000" & "0000000000000000";
								outCnt <= 11;
								MemAccess <= '1';
							WHEN "1101" => --16bit wral
								serialOut <= "10001000000" & din;
								outCnt <= 27;
								MemAccess <= '1';
							WHEN "1110" => --16bit EWEN
								serialOut <= "10011000000" & "0000000000000000";
								outCnt <= 11;
							WHEN "1111" => --16bit EWDS
								serialOut <= "10000000000" & "0000000000000000";
								outCnt <= 11;
							--8bit
							WHEN "0001" => --8bit write
								serialOut <= "101" & adrin(8 DOWNTO 0) & din(7 DOWNTO 0) & "0000000";
								outCnt <= 20;
								MemAccess <= '1';
							WHEN "0010" => --8bit read
								serialOut <= "110" & adrin(8 DOWNTO 0) & "000000000000000";
								outCnt <= 20;
							WHEN "0011" => --8bit erase
								serialOut <= "111" & adrin(8 DOWNTO 0) & "000000000000000";
								outCnt <= 12;
								MemAccess <= '1';
							WHEN "0100" => --8bit eral
								serialOut <= "10010000000" & "0000000000000000";
								outCnt <= 12;
								MemAccess <= '1';
							WHEN "0101" => --8bit wral
								serialOut <= "100010000000" & din(7 DOWNTO 0) & "0000000";
								outCnt <= 20;
								MemAccess <= '1';
							WHEN "0110" => --8bit EWEN
								serialOut <= "10011000000" & "0000000000000000";
								outCnt <= 12;
							WHEN "0111" => --8bit EWDS
								serialOut <= "10000000000" & "0000000000000000";
								outCnt <= 12;
							WHEN others =>

						END CASE;
						busyS<= '1';
						org <= cmd(3);
						state <= BUSY;
					END IF;
				WHEN BUSY =>
					IF serClk = '0' THEN
						outCnt <= outCnt - 1;
						serialIn <= serialIn(serialIn'LEFT-1 DOWNTO serialIn'RIGHT) & miso;
						serClk <= '1';
					ELSE
						serialOut <= serialOut(serialOut'LEFT-1 DOWNTO serialOut'RIGHT) & '0';
						IF(outCnt = 0) THEN
							IF MemAccess = '1' THEN
								state <= WAITEEPROM;
								outCnt <= 2;
								MemAccess <= '0';
							ELSE
								busyS<= '0';
								state <= IDLE;
							END IF;
							dout <= serialIn;
							cs <= '0';
						END IF;
						serClk <= '0';
					END IF;
				WHEN WAITEEPROM =>
					IF outCnt /= 0 THEN
						outCnt <= outCnt -1;
					ELSE
						cs <= '1';
						IF miso = '1' THEN
							cs <= '0';
							state <= IDLE;
							busyS<= '0';
						END IF;
					END IF;
			END CASE;
		END IF;

	END PROCESS;

   mosi <= serialOut(serialOut'LEFT);
   sclk <= serClk;
   busyout <= busyS;


END behaviour;