LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY AD7782IF_tb IS
   -- empty
END AD7782IF_tb;

ARCHITECTURE verhalten OF AD7782IF_tb IS

   CONSTANT RSTDEF: std_logic := '0';
   CONSTANT FRQDEF: natural   := 1e6;
   CONSTANT tcyc:   time      := 1 sec / FRQDEF;
   CONSTANT ref:    real      := 2.5;
    
   COMPONENT AD7782
      GENERIC(ref: real);
      PORT(ain1: IN  real;        -- analog input: +/- Ref
           ain2: IN  real;        -- analog input: +/- Ref
           rng:  IN  std_logic;   -- logic input which configures the input range on the internal PGA
           sel:  IN  std_logic;   -- logic input which selects the active channel AIN1 oo ANI2
           mode: IN  std_logic;   -- logic input which selects master (=0) or slave (=1) mode of operation
           sclk: IN  std_logic;   -- serial clock output
           cs:   IN  std_logic;   -- chip select, low active
           dout: OUT std_logic);  -- serial data output
   END COMPONENT;

   COMPONENT AD7782IF
      GENERIC(RSTDEF: std_logic);
      PORT(rst:  IN  std_logic;  -- reset RSTDEF active
           clk:  IN  std_logic;  -- rising edge active, 1 MHz
           strb: IN  std_logic;  -- strobe, high active
           rng:  OUT std_logic;  -- logic output which configures the input range on the internal PGA
           sel:  OUT std_logic;  -- logic output which selects the active channel AIN1 (=0) or ANI2 (=1)
           mode: OUT std_logic;  -- logic output which selects master (=0) or slave (=1) mode of operation
           cs:   OUT std_logic;  -- chip select, low active
           sclk: OUT std_logic;  -- serial clock output
           din:  IN  std_logic;  -- serial data input
           ch1:  OUT std_logic_vector(15 DOWNTO 0);
           ch2:  OUT std_logic_vector(15 DOWNTO 0));
   END COMPONENT;


   SIGNAL rst:  std_logic := RSTDEF;
   SIGNAL clk:  std_logic := '0';
   -- IO For AD7782
   SIGNAL ain1: real      := 0.0;
   SIGNAL ain2: real      := 0.0;
   SIGNAL rng:  std_logic := '0';
   SIGNAL sel:  std_logic := '0';
   SIGNAL mode: std_logic := '1';
   SIGNAL sclk: std_logic := '1';
   SIGNAL cs:   std_logic := '1';

   SIGNAL adot: std_logic := '1';
   -- IO For AD7782IF
   SIGNAL strb: std_logic := '0';
   SIGNAL csel: std_logic := '0';
   SIGNAL ena:  std_logic := '1';
   SIGNAL ch1:  std_logic_vector(15 DOWNTO 0) := (OTHERS => '0');
   SIGNAL ch2:  std_logic_vector(15 DOWNTO 0) := (OTHERS => '0');


BEGIN

   adot <= 'H';
   
   rst  <= RSTDEF, NOT RSTDEF AFTER 50 ns;
   clk  <= NOT clk AFTER tcyc/2;

   u1: AD7782
   GENERIC MAP(ref => ref)
   PORT MAP(ain1 => ain1,
            ain2 => ain2,
            rng  => rng,
            sel  => sel,
            mode => mode,
            sclk => sclk,
            cs   => cs,
            dout => adot);

   u2: AD7782IF
   GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst   => rst,
             clk   => clk,
             strb  => strb,
             csel  => csel,
             din   => adot,
             rng   => rng,
             sel   => sel,
             mode  => mode,
             cs    => cs,
             sclk  => sclk,
             ch1   => ch1,
             ch2   => ch2);

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

   ain1 <= 2.49;
   ain2 <= 3.01;
   
END verhalten;