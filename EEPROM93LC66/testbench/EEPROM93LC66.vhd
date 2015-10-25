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
  type      memory_array  is array(0 to 2047) of std_logic_vector(15 downto 0);
  type			tstate IS (IDLE, RXSB, RXOP, RXOP2, RXADDR, RXDIN, TXDOUT, MEMBUSY)
  type			tcmd IS (NONE, ERASE, ERAL, EWDS, EWEN, RE4D, WR1TE, WRAL)
	
	signal MEM_DATA			: memory_array <=(others '1');

	signal writeProtect : std_logic <= '1'; -- write protection, activ high
	signal state				: tstate <= IDLE;
	signal cmd					: tcmd <= NONE;
	signal serialInR		: std_logic_vector(15 DOWNTO 0);

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
						cnt := 0;
					END IF;
				WHEN RXOP2 =>

			END CASE;
		END IF;
	END PROCESS;

END simulation;