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
  type			tstate IS (IDLE, RXSB, RXOP, RXOP2, RXADDR, WAITFORCS, RXDIN, TXDOUT, MEMBUSY);
  type			tcmd IS (NONE, ERASE, ERAL, RE4D, WR1TE, WRAL);
	
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
			ELSIF state = MEMBUSY THEN
				do <= '0';
			END IF;
		ELSIF falling_edge(cs) AND state = WAITFORCS THEN
			IF cmd = ERASE THEN
				IF NOT writeProtect THEN
					IF org = '1' THEN
						MEM_DATA(address * 2) <= (others '1');
						MEM_DATA((address * 2) + 1) <= (others '1');
					ELSE
						MEM_DATA(address) <= (others '1');
					END IF;
				END IF;
				address <= (others '0');
			ELSIF cmd = ERAL THEN
				IF NOT writeProtect THEN
					MEM_DATA <= (others '1');
				END IF;
			ELSIF cmd = WR1TE THEN
				IF NOT writeProtect THEN
					IF org = '1' THEN
						MEM_DATA(address*2) <= serialInR(15 DOWNTO 8);
						MEM_DATA((address*2)+1) <= serialInR(7 DOWNTO 0);
					ELSE
						MEM_DATA(address) <= serialInR(7 DOWNTO 0);
					END IF;
				END IF;
				address <= (others '0');
			ELSIF cmd = WRAL THEN
				IF NOT writeProtect THEN
					IF org = '1' THEN
						for i in 0 to 2047 LOOP
							MEM_DATA(i*2) <= serialInR(15 DOWNTO 8);
							MEM_DATA((i*2)+1) <= serialInR(7 DOWNTO 0);
						END LOOP;
					ELSE
						MEM_DATA <= serialInR(7 DOWNTO 0);
					END IF;
				END IF;				
			END IF;
			state <= MEMBUSY;
		END IF;

	END PROCESS;

	busyState: PROCESS(state) IS
	BEGIN
		IF state = MEMBUSY THEN
			IF cmd = ERASE THEN
				state <= IDLE AFTER 6 ms;
			ELSIF cmd = ERAL THEN
				state <= IDLE AFTER 6 ms;
			ELSIF cmd = WRAL THEN
				state <= IDLE AFTER 15 ms;
			END IF;
			cmd <= NONE;
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
								cmd <= ERAL;
								state <= WAITFORCS;
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
					IF (org = '1' AND cnt = 8) OR (org = '0' AND cnt = 9) THEN
						address <= serialInR(8 DOWNTO 0);
						IF cmd = ERASE THEN
							-- wait for falling edge in CS
							state <= WAITFORCS;							
						ELSIF cmd = RE4D THEN
							-- DO = 0 at A0 missing!!
							IF cnt = 8 THEN
								serialOutR <= MEM_DATA(address*2) & 
															MEM_DATA((address*2) + 1);
							ELSE
								serialOutR(15 DOWNTO 8) <= MEM_DATA(address);
							END IF;
							address <= (others '0');
							state <= TXDOUT;
						ELSIF cmd = WR1TE THEN
							state <= RXDIN
						END IF;
						cnt := 0;
					END IF;
				WHEN RXDIN =>
					serialInR <= serialInR(14 DOWNTO 0) & di;
					cnt := cnt + 1;
					IF (org = '1' AND cnt = 16) OR (org = '0' AND cnt = 8) THEN
						IF cmd = WR1TE THEN
							state <= WAITFORCS;
						ELSIF cmd = WRAL THEN
							state <= WAITFORCS;
						END IF;
						cnt := 0;
					END IF;
			END CASE;
		END IF;
	END PROCESS;

	serialOutPro: PROCESS (sclk) IS
		VARIABLE cnt: integer := 0;

	BEGIN

		IF falling_edge(sclk) AND cs = '1' AND state = TXDOUT THEN
			do <= serialOutR(15);
			serialOutR <= serialOutR(14 DOWNTO 0) & '0';
			cnt := cnt + 1;
			IF (org = '1' AND cnt = 16) OR (org = '0' AND cnt = 8) THEN
				cnt := 0;
				state <= IDLE;
			END IF;
		END IF;
	END PROCESS;

END simulation;