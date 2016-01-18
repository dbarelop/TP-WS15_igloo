LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY COUNTER IS
    GENERIC(RSTDEF: std_logic := '1';
            LENGTH: NATURAL := 17);
	PORT(	rst:		IN	std_logic;
            swrst:      IN  std_logic;
			clk:		IN	std_logic;
            en:         IN  std_logic;
			overflow:   OUT std_logic 
	);

END COUNTER;

ARCHITECTURE behaviour OF COUNTER IS
    SIGNAL counter: std_logic_vector(LENGTH + 1 DOWNTO 0);
BEGIN

    PROCESS(clk, rst) IS
    BEGIN
        IF rst = RSTDEF THEN
            counter <= (others => '0');
            overflow <= '0';
        ELSIF rising_edge(clk) THEN
            IF en = '1' THEN
                IF counter(counter'LEFT) = '1' THEN
                    counter(counter'LEFT) <= '0';
                    overflow <= '1';
                ELSE
                    counter <= counter + 1;
                    overflow <= '0';
                END IF;
            ELSE    
                overflow <= '0';
                counter <= (others => '0');
            END IF;
            IF swrst = RSTDEF THEN
                counter <= (others => '0');
		overflow <= '0';
            END IF;
        END IF;
    END PROCESS;

END behaviour;