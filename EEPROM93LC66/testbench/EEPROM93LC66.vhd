LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

ENTITY EEPROM93LC66 IS
	PORT(sclk:		IN std_logic;
			 cs:			IN std_logic;
			 din:			IN std_logic;
			 dout:			OUT std_logic;
			 org:			IN std_logic);
END EEPROM93LC66;

ARCHITECTURE simulation OF EEPROM93LC66 IS
  type      memory_array  is array(0 to 4095) of std_logic_vector(7 downto 0) ;
  type			tstate IS (IDLE, RXSB, RXOP, RXOP2, RXADDR, WAITFORCS, RXDIN, TXDOUT);
  type			tcmd IS (NONE, ERASE, ERAL, RE4D, WR1TE, WRAL);
  type			t2state IS (IDLE, BUSY);

	
	signal MEM_DATA			: memory_array := ((others=> (others=>'1')));

	signal writeProtect : std_logic := '1'; -- write protection, activ high
	signal state				: tstate := IDLE;
	signal cmd					: tcmd := NONE;
	signal mstate				: t2state := IDLE;
	signal txstate			: t2state := IDLE;
	signal serialInR		: std_logic_vector(15 DOWNTO 0) := (others => '0');
	signal serialOutR		: std_logic_vector(15 DOWNTO 0);
	signal address			: std_logic_vector(8 DOWNTO 0);

BEGIN

	memory_writePro: PROCESS(cs) IS

	BEGIN

		IF falling_edge(cs) AND state = WAITFORCS THEN
			mstate <= BUSY;
			IF cmd = ERASE THEN
				IF writeProtect = '0' THEN
					IF org = '1' THEN
						-- multiply by 2
						MEM_DATA(TO_INTEGER(unsigned(address(7 DOWNTO 0) & '0'))) <= (others => '1');
						MEM_DATA(TO_INTEGER(unsigned(address(7 DOWNTO 0) & '1'))) <= (others => '1');
					ELSE
						MEM_DATA(TO_INTEGER(unsigned(address))) <= (others => '1');
					END IF;
					--WAIT FOR 2 ms;
				END IF;
			ELSIF cmd = ERAL THEN
				IF writeProtect = '0' THEN
					MEM_DATA <= ((others=> (others=>'1')));
				END IF;
				--WAIT FOR 6 ms;
			ELSIF cmd = WR1TE THEN
				IF writeProtect = '0' THEN
					IF org = '1' THEN
						MEM_DATA(TO_INTEGER(unsigned(address(7 DOWNTO 0) & '0'))) <= serialInR(15 DOWNTO 8);
						MEM_DATA(TO_INTEGER(unsigned(address(7 DOWNTO 0) & '1'))) <= serialInR(7 DOWNTO 0);
					ELSE
						MEM_DATA(TO_INTEGER(unsigned(address))) <= serialInR(7 DOWNTO 0);
					END IF;
					--WAIT FOR 2 ms;
				END IF;
			ELSIF cmd = WRAL THEN
				IF writeProtect = '0' THEN
					IF org = '1' THEN
						for i in 0 to 2047 LOOP
							MEM_DATA(i*2) <= serialInR(15 DOWNTO 8);
							MEM_DATA((i*2)+1) <= serialInR(7 DOWNTO 0);
						END LOOP;
					ELSE
						MEM_DATA <= (others => (serialInR(7 DOWNTO 0)));
					END IF;
					--WAIT FOR 15 ms;
				END IF;
			END IF;
			mstate <= IDLE;
		END IF;

	END PROCESS;

	serialInPro: PROCESS(sclk, cs) IS

		VARIABLE cnt: integer := 0;
		VARIABLE tmpSerialIn: std_logic_vector(15 DOWNTO 0) := (others => '0');

	BEGIN
		IF rising_edge(sclk) AND cs = '1' THEN
			IF state = RXSB THEN
				IF din = '1' THEN
					state <= RXOP;
				END IF;
			ELSIF state = RXOP THEN
				tmpSerialIn := tmpSerialIn(14 DOWNTO 0) & din;
				cnt := cnt + 1;
				IF cnt >= 2 THEN
					IF tmpSerialIn(1 DOWNTO 0) = "00" THEN
						state <= RXOP2;
					ELSIF tmpSerialIn(1 DOWNTO 0) = "11" THEN
						cmd <= ERASE;
						state <= RXADDR;
					ELSIF tmpSerialIn(1 DOWNTO 0) = "10" THEN
						cmd <= RE4D;
						state <= RXADDR;
					ELSIF tmpSerialIn(1 DOWNTO 0) = "01" THEN
						cmd <= WR1TE;
						state <= RXADDR;
					END IF;
					tmpSerialIn := (others => '0');
					cnt := 0;
				END IF;
			ELSIF state = RXOP2 THEN
				tmpSerialIn := tmpSerialIn(14 DOWNTO 0) & din;
				cnt := cnt + 1;
				IF (org = '1' AND cnt = 8) OR (org = '0' AND cnt = 9) THEN
					IF cnt = 8 THEN
						-- shift in a extra bit
						tmpSerialIn := tmpSerialIn(14 DOWNTO 0) & '0';
					END IF;
					IF tmpSerialIn(8 DOWNTO 7) = "10" THEN
						-- ERAL
						cmd <= ERAL;
						state <= WAITFORCS;
					ELSIF tmpSerialIn(8 DOWNTO 7) = "00" THEN
						-- EWDS
						writeProtect <= '1';
						state <= IDLE;
					ELSIF tmpSerialIn(8 DOWNTO 7) = "11" THEN
						-- EWEN
						writeProtect <= '0';
						state <= IDLE;
					ELSIF tmpSerialIn(8 DOWNTO 7) = "01" THEN
						-- WRAL
						cmd <= WRAL;
						state <= RXDIN;
					END IF;
					cnt := 0;
					tmpSerialIn := (others => '0');
				END IF;
			ELSIF state = RXADDR THEN
				tmpSerialIn := tmpSerialIn(14 DOWNTO 0) & din;
				cnt := cnt + 1;
				IF (org = '1' AND cnt = 8) OR (org = '0' AND cnt = 9) THEN
					address <= tmpSerialIn(8 DOWNTO 0);
					IF cmd = ERASE THEN
						-- wait for falling edge in CS
						state <= WAITFORCS;							
					ELSIF cmd = RE4D THEN
						-- DOUT = 0 at A0 missing!!
						state <= TXDOUT;
					ELSIF cmd = WR1TE THEN
						state <= RXDIN;
					END IF;
					cnt := 0;
					tmpSerialIn := (others => '0');
				END IF;
			ELSIF state = RXDIN THEN
				tmpSerialIn := tmpSerialIn(14 DOWNTO 0) & din;
				cnt := cnt + 1;
				IF (org = '1' AND cnt = 16) OR (org = '0' AND cnt = 8) THEN
					serialInR <= tmpSerialIn;
					IF cmd = WR1TE THEN
						state <= WAITFORCS;
					ELSIF cmd = WRAL THEN
						state <= WAITFORCS;
					END IF;
					cnt := 0;
				END IF;
			ELSIF state = TXDOUT AND txstate = IDLE THEN
				state <= IDLE;
			END IF;
		ELSIF rising_edge(cs) THEN
			IF mstate = IDLE THEN
				state <= RXSB;
				cmd <= NONE;
			END IF;
			IF state = IDLE THEN
				state <= RXSB;
			END IF;
		ELSIF falling_edge(cs) AND state = TXDOUT THEN
			state <= IDLE;
			cmd <= NONE;
		END IF;
	END PROCESS;

	serialOutPro: PROCESS (sclk, cs, mstate) IS
		VARIABLE cnt: integer := 0;
		VARIABLE TXtmpSerOut: std_logic_vector(15 DOWNTO 0);
		VARIABLE addressOffset: integer := 0;
	BEGIN

		IF falling_edge(sclk) AND cs = '1' AND state = TXDOUT THEN
			IF txstate = IDLE THEN
				cnt := 0;
				addressOffset := 0;
				txstate <= BUSY;
			END IF;
			IF cnt = 0 THEN
				IF org = '1' THEN
					TXtmpSerOut := MEM_DATA(TO_INTEGER(unsigned(address(7 DOWNTO 0) & '0'))+addressOffset) & 
							MEM_DATA(TO_INTEGER(unsigned(address(7 DOWNTO 0) & '1'))+addressOffset);
				ELSE
					TXtmpSerOut(15 DOWNTO 8) := MEM_DATA(TO_INTEGER(unsigned(address))+addressOffset);			
				END IF;
			END IF;
			dout <= TXtmpSerOut(15);
			TXtmpSerOut := TXtmpSerOut(14 DOWNTO 0) & '0';
			cnt := cnt + 1;
			IF (org = '1' AND cnt = 16) OR (org = '0' AND cnt = 8) THEN
				--continious reading
				IF org = '1' THEN
					addressOffset := addressOffset + 2;
				ELSE
					addressOffset := addressOffset + 1;
				END IF;
				cnt := 0;
			END IF;			
		ELSIF rising_edge(cs) AND mstate = BUSY THEN
			dout <= '0';
		ELSIF mstate = IDLE AND cs = '1' AND state /= TXDOUT THEN
			dout <= '1';
		ELSIF state /= TXDOUT THEN
			dout <= 'Z';
		ELSIF falling_edge(cs) THEN
			txstate <= IDLE;
		END IF;
	END PROCESS;

END simulation;