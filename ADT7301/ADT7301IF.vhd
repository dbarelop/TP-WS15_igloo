
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_signed.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY ADT7301IF IS
   GENERIC(RSTDEF: std_logic := '1');
   PORT(rst:  IN  std_logic;  -- reset RSTDEF active
        clk:  IN  std_logic;  -- rising edge active, 1 MHz
        strb: IN  std_logic;  -- strobe, high active
        dout: OUT std_logic_vector(13 DOWNTO 0);

        sclk: OUT std_logic;  -- serial clock input
        cs:   OUT std_logic;  -- chip select, low active
        mosi: OUT std_logic;  -- serial data output
        miso: IN  std_logic); -- serial data input
END ADT7301IF;

ARCHITECTURE behaviour OF ADT7301IF IS

   CONSTANT CPOL: std_logic := '1';

   TYPE tstate IS (S0, S1, S2, S3);

   SIGNAL state: tstate;
   SIGNAL reg:   std_logic_vector(15 DOWNTO 0); -- shift register

BEGIN

   p1: PROCESS (rst, clk) IS
      CONSTANT MAXCNT: natural := reg'LENGTH;
      VARIABLE cnt: integer RANGE 0 TO MAXCNT-1;
   BEGIN
      IF rst=RSTDEF THEN
         dout  <= (OTHERS => '0');
         reg   <= (OTHERS => '0');
         cs    <= '1';
         sclk  <= CPOL;
         cnt   := 0;
         state <= S0;
      ELSIF rising_edge(clk) THEN
         CASE state IS
            WHEN S0 =>
               IF strb='1' THEN
                  reg   <= (OTHERS => '0');
                  cs    <= '0';
                  cnt   := 0;
                  state <= S1;
               END IF;
            WHEN S1 =>
               sclk  <= '0';
               state <= S2;
            WHEN S2 =>
               reg <= reg(reg'LEFT-1 DOWNTO reg'RIGHT) & miso;
               sclk  <= '1';
               IF cnt=MAXCNT-1 THEN
                  state <= S3;
               ELSE
                  state <= S1;
                  cnt   := cnt + 1;
               END IF;
            WHEN S3 =>
               cs    <= '1';
               dout  <= reg(dout'RANGE);
               state <= S0;
         END CASE;
      END IF;
   END PROCESS;

   mosi <= reg(reg'LEFT);

END behaviour;
