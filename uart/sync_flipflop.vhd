
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY sync_flipflop IS
   GENERIC(RSTDEF: std_logic := '0';
           INIVAL: std_logic := '1');
   PORT(rst:  IN  std_logic;  -- reset, high active
        clk:  IN  std_logic;  -- clock, rising edge active
        din:  IN  std_logic;  -- data input
        dout: OUT std_logic); -- data output
END sync_flipflop;

ARCHITECTURE structure OF sync_flipflop IS
   SIGNAL tmp: std_logic;
BEGIN

   PROCESS (rst, clk) IS
   BEGIN
      IF rst=RSTDEF THEN
         dout <= INIVAL;
         tmp  <= INIVAL;
      ELSIF rising_edge(clk) THEN
         tmp  <= din;
         dout <= tmp;
      END IF;
   END PROCESS;

END structure;