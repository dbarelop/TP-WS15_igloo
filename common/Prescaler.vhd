LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY Prescaler IS
    GENERIC(RSTDEF: std_logic := '1');
	PORT(	rst:		IN	std_logic;
            swrst:      IN  std_logic;
			clkin:		IN	std_logic;
            en:         IN  std_logic;
			clkout:   OUT std_logic 
	);

END Prescaler;

ARCHITECTURE behaviour OF Prescaler IS
    SIGNAL counter: integer range 0 to 19;
    SIGNAL temp: std_logic;
BEGIN

    PROCESS(clk, rst) IS
    BEGIN
        IF rst = RSTDEF THEN
            counter <= 0;
            temp <= '0';
        ELSIF rising_edge(clk) THEN
            IF en = '1' THEN
                IF counter = 19 THEN
                    counter <= 0;
                    temp <= NOT temp;
                ELSE
                    counter <= counter + 1;
                END IF;
            END IF;
            IF swrst = RSTDEF THEN
                counter <= 0;
                temp <= '0';
            END IF;
        END IF;
    END PROCESS;

clkout <= temp;

END behaviour;