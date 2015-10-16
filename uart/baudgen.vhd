LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY baudgen IS
   GENERIC(RSTDEF:  std_logic := '1';
           BAUDEF:  real      := 19.2e3;
           FRQDEF:  real      := 1.0e6);
   PORT(rst:   IN  std_logic;  -- reset RSTDEF active
        clk:   IN  std_logic;  -- rising edge active
        swrst: IN  std_logic;  -- software reset,  RSTDEF active        
        ena:   IN  std_logic;  -- enable, high active
        strb:  OUT std_logic); -- strobe, high active
END baudgen;

ARCHITECTURE behaviour OF baudgen IS

   CONSTANT LENDEF: natural := 16;
   CONSTANT MAXVAL: std_logic_vector(LENDEF-1 DOWNTO 0) := (LENDEF-1 => '1', OTHERS => '0');

   FUNCTION conv_std_logic_vector(arg: real; size: natural) RETURN std_logic_vector IS
      VARIABLE tmp1: real;
      VARIABLE tmp2: integer;
   BEGIN
      tmp1 := arg * 2.0**size;
      tmp2 := integer(tmp1);
      RETURN conv_std_logic_vector(tmp2, size);
   END FUNCTION;

   SIGNAL cnt: std_logic_vector(LENDEF-1 DOWNTO 0);

BEGIN

   p1: PROCESS (rst, clk) IS
      CONSTANT TEILER: std_logic_vector := conv_std_logic_vector((BAUDEF*16.0) / FRQDEF, LENDEF-1);
   BEGIN
      IF rst=RSTDEF THEN
         strb <= '0';
         cnt  <= (OTHERS => '0');
      ELSIF rising_edge(clk) THEN
         IF ena='1' THEN
            IF cnt(LENDEF-1) = '1' THEN
               strb <= '1';
               cnt  <= (cnt - MAXVAL) + TEILER;
            ELSE
               strb <= '0';
               cnt  <= cnt + TEILER;
            END IF;  
         END IF;
         IF swrst=RSTDEF THEN
            strb <= '0';           
            cnt  <= (OTHERS => '0');
         END IF;
      END IF;
   END PROCESS;

END behaviour;
