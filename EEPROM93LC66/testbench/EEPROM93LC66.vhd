LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_signed.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY EEPROM93LC66 IS
	PORT(sclk:		IN std_logic;
			 cs:			IN std_logic;
			 di:			IN std_logic;
			 do:			OUT std_logic;
			 org:			IN std_logic);
END EEPROM93LC66;

ARCHITECTURE simulation OF EEPROM93LC66 IS
  type      memory_array  is array(0 to 4095) of std_logic_vector(7 downto 0);
  type			tstate IS (IDLE, RXSB, RXOP, RXOP2, RXADDR, RXDIN, TXDOUT, MEMBUSY);
  type			tcmd IS (NONE, ERASE, RE4D, WR1TE, WRAL);
	
	signal MEM_DATA			: memory_array <=(others '1');

	signal writeProtect : std_logic <= '1'; -- write protection, activ high
	signal state				: tstate <= IDLE;
	signal cmd					: tcmd <= NONE;
	signal serialInR		: std_logic_vector(15 DOWNTO 0);
	signal serialOutR		: std_logic_vector(15 DOWNTO 0);
	signal address			: std_logic_vector(8 DOWNTO 0);

BEGIN

	chipSelect: PROCESS(cs) IS

	BEGIN
		IF rising_edge(cs) THEN
			IF state = IDLE THEN
				state = RXSB;
			END IF;

		END IF;

	END PROCESS;

	serialInPro: PROCESS(sclk) IS

		VARIABLE cnt: integer;

	BEGIN
		IF rising_edge(sclk) AND cs = '1' THEN
			CASE state IS
				WHEN RXSB =>
					IF di = '1' THEN
						state <= RXOP;
					END IF;
				WHEN RXOP =>
					serialInR <= serialInR(14 DOWNTO 0) & di;
					cnt := cnt + 1;
					IF cnt >= 2 THEN
						IF serialInR(1 DOWNTO 0) = "00" THEN
							state <= RXOP2;
						ELSIF serialInR(1 DOWNTO 0) = "11" THEN
							cmd <= ERASE;
							state <= RXADDR;
						ELSIF serialInR(1 DOWNTO 0) = "10" THEN
							cmd <= RE4D;
							state <= RXADDR;
						ELSIF serialInR(1 DOWNTO 0) = "01" THEN
							cmd <= WR1TE;
							state <= RXADDR;
						END IF;
						serialInR <= (others '0');
						cnt := 0;
					END IF;
				WHEN RXOP2 =>
					serialInR <= serialInR(14 DOWNTO 0) & di;
					cnt := cnt + 1;
					IF (org = '1' AND cnt = 8) OR (org = '0' AND cnt = 9) THEN
						IF cnt = 8 THEN
							-- shift in a extra bit
							serialInR <= serialInR(14 DOWNTO 0) & '0';
						END IF;
						CASE serialInR(8 DOWNTO 7) IS
							WHEN "10" =>
								-- ERAL
								memory_array <= (others '1');
								state <= MEMBUSY;
							WHEN "00" =>
								-- EWDS
								writeProtect <= '1';
								state <= IDLE;
							WHEN "11" =>
								-- EWEN
								writeProtect <= '0';
								state <= IDLE;
							WHEN "01" =>
								-- WRAL
								cmd <= WRAL;
								state <= RXDIN;
						END CASE;
						cnt := 0;
						serialInR <= (others '0')
					END IF;
				WHEN RXADDR =>
					serialInR <= serialInR(14 DOWNTO 0) & di;
					cnt := cnt + 1;
					IF (org = '1' AND cnt = 8) OR (org = '0' and cnt = 9) THEN
						address <= serialInR(8 DOWNTO 0);
						IF cmd = ERASE THEN
							IF cnt = 8 THEN
								memory_array(address * 2) <= (others '1');
								memory_array((address * 2) + 1) <= (others '1');
							ELSE
								memory_array(address) <= (others '1');
							END IF;
							cmd <= NONE;
							state <= MEMBUSY;
							cnt := 0;
						ELSIF cmd = RE4D THEN
							-- DO = 0 at A0 missing!!
							IF cnt = 8 THEN
								serialOutR <= memory_array(address*2) & 
															memory_array((address*2) + 1);
							ELSE
								serialOutR(15 DOWNTO 8) <= memory_array(address);
							END IF;
							state <= TXDOUT;
							cnt = 0;
						ELSIF cmd = WR1TE THEN
							state <= RXDIN
							cnt = 0;
						END IF;
					END IF;
				WHEN RXDIN =>
					serialInR <= serialInR(14 DOWNTO 0) & di;
					cnt := cnt + 1;
					IF (org = '1' AND cnt = 16) OR (org = '0' and cnt = 8) THEN
						IF cmd = WR1TE THEN
							IF cnt = 8 THEN
								memory_array(address) <= serialInR(7 DOWNTO 0);
							ELSE
								memory_array(address*2) <= serialInR(15 DOWNTO 8);
								memory_array((address*2)+1) <= serialInR(7 DOWNTO 0);
							END IF;
							cnt := 0;
							cmd <= NONE;
							state <= MEMBUSY;
						ELSIF cmd = WRAL THEN
							IF cnt = 8 THEN
								memory_array <= serialInR(7 DOWNTO 0);
							ELSE
								for i in 0 to 2047 LOOP
									memory_array(i*2) <= serialInR(15 DOWNTO 8);
									memory_array((i*2)+1) <= serialInR(7 DOWNTO 0);
								END LOOP;
							END IF;
							cnt := 0;
							cmd <= NONE;
							state <= MEMBUSY;
						END IF;
					END IF;
			END CASE;
		END IF;
	END PROCESS;

END simulation;