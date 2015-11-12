LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_signed.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY EEPROM93LC66IF IS
	GENERIC(RSTDEF: std_logic := '1');
	PORT(rst:		IN	std_logic;
			 clk:		IN	std_logic;
			 cmd:		IN 	std_logic_vector(2 DOWNTO 0);
			 strb:	IN	std_logic;			-- executes the given command with the given address 
			 dout:	OUT std_logic_vector(15 DOWNTO 0);
			 busy:	OUT	std_logic;			-- busy bit indicates working eeprom, dout not valid

			 sclk:	OUT std_logic;			-- serial clock to EEPROM
			 cs:		OUT std_logic;			-- chip select, HIGH active
			 mosi:	OUT std_logic;
			 miso:	OUT std_logic;

			 ORG:		OUT std_logic);			-- memory-config =1 16 bit / =0 8 bit wordlength
	
END EEPROM93LC66IF;

-- so far, only 8bit commands possible, ORG = 0
-- comands:
-- 011		ERASE address
-- 010		READ	address
-- 001		WRITE address
-- 110		ERASE all
-- 101		WRITE all