LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_signed.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY EEPROM93LC66CTRL IS
	GENERIC(RSTDEF: std_logic := '1',
			DEVICE_ID: std_logic_vector(3 DOWNTO 0) := "0000";
	PORT(    rst:		IN	std_logic;
			 clk:		IN	std_logic;
			 uartin:	IN 	std_logic_vector(7 DOWNTO 0);
			 uartout:   IN  std_logic_vector(7 DOWNTO 0);
			 dout:		OUT std_logic_vector(15 DOWNTO 0);
			 busy:		OUT	std_logic;			-- busy bit indicates working eeprom, dout not valid
	);

END EEPROM93LC66CTRL;
ARCHITECTURE verhalten OF EEPROM93LC66CTRL IS

signal param		: std_logic_vector(7 DOWNTO 0); -- arrayyyy

TState (READING, WRITING, ERASING, IDLE, PARAM)

UState (IDLE, PARAM, DONE);
EState (READING, WRITING, ERASING);
signal nofparams: integer range 0 to 2:= 0;


BEGIN
uart: process(uart, rst)
	IF rst = RSTDEF THEN
		state <= IDLE;
	ELSE
		CASE state IS
		WHEN IDLE =>
			IF busy = '0' AND uartin(7 DOWNTO 4) = DEVICE_ID THEN
				busy <= '1';
				CASE uartin(3 DOWNTO 0) IS
					WHEN READ =>
						ustate <= PARAM;
						estate <= READING;
						nofparams <= 1;
					WHEN WRITE =>
						ustate <= PARAM;
						ustate <= WRITING;
						nofparams <= 3;
					WHEN ERASE => 
						ustate <= DONE;
						estate <= ERASING;
					WHEN OTHERS => busy <= '0';
				END CASE;
			END IF;
		WHEN PARAM =>
			IF nofparams /= 0 THEN
				param(nofparams -1) <= uartin;
				nofparams <= nofparams - 1;
			ELSE
				ustate <= DONE;
			END IF;
		WHEN DONE => 
			
			;
			
	 <= rdy or done;
	
	PROCESS(start) IS
	BEGIN
	IF rising_edge(start) THEN
	CASE estate IS
	WHEN WRITING =>
		ustate <= PARAM;
		nofparams <= 1; 
		params(2)--;
		next <= '1';
		--start filling buffer
		-- write next byte to eeprom
	WHEN READING =>
		-- read next from 
	
	
	PROCESS(next) IS
	BEGIN
	IF rising_edge(next) THEN
	CASE estate IS
	WHEN WRITING =>
		IF last byte THEN
			busy <= '0'
			ustate <= IDLE;
			uartout <= DONE;
			uartwr <= '1';
		ELSE		
			--write next byte
		END IF;
	WHEN READING =>
		uartout <= ifin;
		uartwe <= '1';
		IF last byte THEN
			busy <= '0'
			ustate <= IDLE;-- read next byte
		ELSE
			--read next byte
		END IF;
	WHEN ERASING =>
		busy <= '0'
		ustate <= IDLE;
		uartout <= DONE;
		suartwr <= '1';
	END CASE;	
	END PROCESS;
		
	
	
	
	IF  AND  THEN
		IF uart = myCOMMAND ELSIF ETC...
	END IF;


CASE state IS
WHEN IDLE =>

	IF

	END IF;

		--
IF  T

IF CMD = READ THEN

ELSIF CMD = WRITE THEN

ELSIF CMD = ERASE THEN

END IF;

-- so far, only 8bit commands possible, ORG = 0
-- comands:
-- 011		ERASE address
-- 010		READ	address
-- 001		WRITE address
-- 110		ERASE all
-- 101		WRITE all

-- lesen mit startadresse mit bytes
-- schreiben
-- adress leitung
-- daten leitung
-- busy
-- ready


-- addresse 7 oder 8 bit (8 oder 9?)
-- kommando (lesen, schreiben, löschen)
-- daten


-- eeprom schreiben, 8 byte
-- 8 mal schreiben,
-- we need a buffer limit
-- wenn controller buffer geleert hat, ready message an pc client
-- controller sagt nur lesen, schreiben, löschen