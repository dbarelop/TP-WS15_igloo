LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY ADT7301IF_tb IS
   -- empty
END ADT7301IF_tb;

ARCHITECTURE verhalten OF ADT7301IF_tb IS

   CONSTANT RSTDEF: std_logic := '0';
   CONSTANT FRQDEF: natural   := 1e6;
   CONSTANT tcyc:   time      := 1 sec / FRQDEF;

   COMPONENT ADT7301
      PORT(sclk: IN  std_logic;  -- serial clock input
           cs:   IN  std_logic;  -- chip select, low active
           din:  IN  std_logic;  -- serial data input
           dout: OUT std_logic); -- serial data output
   END COMPONENT;

   COMPONENT ADT7301IF
      GENERIC(RSTDEF: std_logic);
      PORT(rst:  IN  std_logic;  -- reset RSTDEF active
           clk:  IN  std_logic;  -- rising edge active, 1 MHz
           strb: IN  std_logic;  -- strobe, high active
           dout: OUT std_logic_vector(13 DOWNTO 0);
   
           sclk: OUT std_logic;  -- serial clock input
           cs:   OUT std_logic;  -- chip select, low active
           mosi: OUT std_logic;  -- serial data output
           miso: IN  std_logic); -- serial data input
   END COMPONENT;

   SIGNAL rst:  std_logic := RSTDEF;
   SIGNAL clk:  std_logic := '0';
   SIGNAL cs:   std_logic := '1';
   SIGNAL sclk: std_logic := '1';
   SIGNAL miso: std_logic := '0';
   SIGNAL mosi: std_logic := '0';
   SIGNAL ena:  std_logic := '1';
   SIGNAL strb: std_logic := '0';

   SIGNAL reg:  std_logic_vector(13 DOWNTO 0);

BEGIN

   rst <= RSTDEF, NOT RSTDEF AFTER 5 us;
   clk <= NOT clk AFTER tcyc/2;

   u1: ADT7301
   PORT MAP(sclk => sclk,
            cs   => cs,
            din  => mosi,
            dout => miso);

   u2: ADT7301IF
   GENERIC MAP(RSTDEF => RSTDEF)
   PORT MAP(rst  => rst,
            clk  => clk,
            strb => strb,
            dout => reg,
            sclk => sclk,
            cs   => cs,
            mosi => mosi,
            miso => miso);

   p1: PROCESS (rst, clk) IS
      CONSTANT CNTMAX: natural := 2**21;
      VARIABLE cnt: integer RANGE 0 TO CNTMAX-1;
   BEGIN
      IF rst=RSTDEF THEN
         strb <= '0';
         cnt  := 0;
      ELSIF rising_edge(clk) THEN
         strb <= '0';
         IF ena='1' THEN
            IF cnt=2e4-1 THEN
               cnt  := 0;
               strb <= '1';
            ELSE
               cnt := cnt + 1;
            END IF;
         END IF;
      END IF;
   END PROCESS;
   
END verhalten;