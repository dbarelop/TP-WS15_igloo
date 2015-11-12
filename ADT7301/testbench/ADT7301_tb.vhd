LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY ADT7301_tb IS
   -- empty
END ADT7301_tb;

ARCHITECTURE verhalten OF ADT7301_tb IS

   CONSTANT RSTDEF: std_logic := '0';
   CONSTANT FRQDEF: natural   := 1e6;
   CONSTANT tcyc:   time      := 1 sec / FRQDEF;

   COMPONENT ADT7301
      PORT(sclk: IN  std_logic;  -- serial clock input
           cs:   IN  std_logic;  -- chip select, low active
           din:  IN  std_logic;  -- serial data input
           dout: OUT std_logic); -- serial data output
   END COMPONENT;

   SIGNAL rst:  std_logic := RSTDEF;
   SIGNAL clk:  std_logic := '0';
   SIGNAL cs:   std_logic := '1';
   SIGNAL sclk: std_logic := '1';
   SIGNAL miso: std_logic := '0';
   SIGNAL mosi: std_logic := '0';
   
   SIGNAL reg:  std_logic_vector(15 DOWNTO 0);

BEGIN

   rst <= RSTDEF, NOT RSTDEF AFTER 5 us;
--   clk <= NOT clk AFTER tcyc/2;

   u1: ADT7301
   PORT MAP(sclk => sclk,
            cs   => cs,
            din  => mosi,
            dout => miso);

   p1: PROCESS
      CONSTANT NUM_CHECKS: integer := 6079;

      PROCEDURE read_temp IS
      BEGIN
         FOR i IN 15 DOWNTO 0 LOOP
            sclk <= '0';
            WAIT FOR tcyc;
            reg(i) <= miso;
            sclk <= '1';
            WAIT FOR tcyc;
         END LOOP;
      END PROCEDURE;

      -- Returns TRUE only when the given value belongs to the range [0x0000,0x12C0]U[0x3B00,0x3FFF]
      FUNCTION valid_temp_value(val: std_logic_vector)
         RETURN boolean IS
      BEGIN
         RETURN val >= X"0000" AND (val <= X"12C0" OR val >= X"3B00") AND val <= X"3FFF";
      END FUNCTION;

   BEGIN
      ASSERT FALSE REPORT "starting test for ADT7301..." SEVERITY note;
      reg <= (OTHERS => '0');
      FOR i IN NUM_CHECKS DOWNTO 0 LOOP
         cs <= '1';
         mosi <= '1';
         WAIT FOR 100 ms;
         cs <= '0';
         WAIT FOR tcyc;
         mosi <= '0';
         read_temp;
         ASSERT valid_temp_value(reg) REPORT "read incorrect value" SEVERITY error;
      END LOOP;
      ASSERT FALSE REPORT "test completed" SEVERITY note;
      WAIT;
   END PROCESS;

END verhalten;