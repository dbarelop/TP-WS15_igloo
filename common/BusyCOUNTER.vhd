LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY BUSYCOUNTER IS
    GENERIC(RSTDEF: std_logic := '1';
            LENGTH: NATURAL := 17);
	PORT(	rst:		IN	std_logic;
            swrst:      IN  std_logic;
			clk:		IN	std_logic;
            en:         IN  std_logic;
			delayOut:   OUT std_logic 
	);

END BUSYCOUNTER;

ARCHITECTURE behaviour OF BUSYCOUNTER IS
    TYPE tstate IS (IDLE, RUNNING);

    SIGNAL state: tstate;
    SIGNAL counter: std_logic_vector(LENGTH + 1 DOWNTO 0);
BEGIN

    PROCESS(clk, rst) IS
        PROCEDURE reset IS
        BEGIN
            counter <= (others => '0');
            state <= IDLE;
            delayOut <= '0';
        END PROCEDURE;
    BEGIN
        IF rst = RSTDEF THEN
            reset;
        ELSIF rising_edge(clk) THEN
            IF state = IDLE AND en = '1' THEN
                delayOut <= '1';
            ELSIF state = RUNNING THEN
                counter <= counter + 1;
                IF counter(counter'LEFT) = '1' THEN
                    reset;
                END IF;
            END IF;
            IF swrst = RSTDEF THEN
                reset;
            END IF;
        END IF;
    END PROCESS;


END behaviour;