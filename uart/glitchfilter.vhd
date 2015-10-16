LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY glitchfilter IS
   GENERIC(RSTDEF: std_logic := '0';
           INIVAL: std_logic := '1');
   PORT(rst:   IN  std_logic;  -- reset,           RSTDEF active
        clk:   IN  std_logic;  -- clock,           rising edge
        swrst: IN  std_logic;  -- software reset,  RSTDEF active
        ena:   IN  std_logic;  -- enable input,    high active
        din:   IN  std_logic;  -- data input,      idle high active
        dout:  OUT std_logic); -- data output,     idle high active
END glitchfilter;

ARCHITECTURE behaviour OF glitchfilter IS

   SIGNAL reg: std_logic_vector(1 TO 5);
   SIGNAL tmp: std_logic;

BEGIN

   PROCESS (rst, clk) IS
   BEGIN
      IF rst=RSTDEF THEN
         reg  <= (OTHERS => INIVAL);
         dout <= INIVAL;
      ELSIF rising_edge(clk) THEN
         dout <= tmp;
         IF ena='1' THEN
            reg <= din & reg(1 TO 4);
         END IF;
         IF swrst=RSTDEF THEN
            reg  <= (OTHERS => INIVAL);
            dout <= INIVAL;
         END IF;
      END IF;
   END PROCESS;

   WITH reg SELECT
   tmp <= '0' WHEN "00000",
          '0' WHEN "00001" | "00010" | "00100" | "01000" | "10000",
          '0' WHEN "00011" | "00110" | "01100" | "11000",
          '0' WHEN "00101" | "01010" | "10100",
          '0' WHEN "01001" | "10010",
          '0' WHEN "10001",
          '1' WHEN OTHERS;

END behaviour;