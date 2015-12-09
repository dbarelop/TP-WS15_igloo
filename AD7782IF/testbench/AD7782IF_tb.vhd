LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY AD7782IF_tb IS
   -- empty
END AD7782IF_tb;

ARCHITECTURE verhalten OF AD7782IF_tb IS

   CONSTANT RSTDEF: std_logic := '0';
   CONSTANT FRQDEF: natural   := 1e6;
   CONSTANT LENDEF: natural   := 24;
   CONSTANT tcyc:   time      := 1 sec / FRQDEF;
   CONSTANT ref:    real      := 2.5;
    
   COMPONENT AD7782
      GENERIC(ref: real);
      PORT( ain1: IN  real;        -- analog input: +/- Ref
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
      PORT( rst:  IN  std_logic;  -- reset RSTDEF active
         clk:  IN  std_logic;  -- rising edge active, 1 MHz
         strb: IN  std_logic;  -- strobe, high active
         csel: IN  std_logic;  -- select wich chanel is used AIN1(0), AIN2(1)
         rsel: IN  std_logic;  -- select wich range is used 2.56V(1), 160mV(0)
         din:  IN  std_logic;  -- serial data input
         rng:  OUT std_logic;  -- logic output which configures the input range on the internal PGA
         sel:  OUT std_logic;  -- logic output which selects the active channel AIN1 (=0) or ANI2 (=1)
         mode: OUT std_logic;  -- logic output which selects master (=0) or slave (=1) mode of operation
         cs:   OUT std_logic;  -- chip select, low active
         sclk: OUT std_logic;  -- serial clock output
         done: OUT std_logic;  -- set done if datas are valid on ch1/2 output (High Active)
         ch1:  OUT std_logic_vector(LENDEF-1 DOWNTO 0);
         ch2:  OUT std_logic_vector(LENDEF-1 DOWNTO 0));
   END COMPONENT;


   SIGNAL rst:  std_logic := RSTDEF;
   SIGNAL clk:  std_logic := '0';
   SIGNAL ena:  std_logic := '1';
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
   SIGNAL rsel: std_logic := '1';
   SIGNAL done: std_logic;
   SIGNAL ch1:  std_logic_vector(LENDEF-1 DOWNTO 0) := (OTHERS => '0');
   SIGNAL ch2:  std_logic_vector(LENDEF-1 DOWNTO 0) := (OTHERS => '0');


   -- Procedure
   PROCEDURE getAD_velue (
      SIGNAL ain        : IN real;                                   -- Analog input for selected Chanel
      SIGNAL rngi       : IN std_logic;                              -- Range input for ADC-IF and from TB (srng)
      SIGNAL schi       : IN std_logic;
      SIGNAL cho1       : IN std_logic_vector(LENDEF-1 DOWNTO 0);    -- AD7782-IF Data-Input CH1
      SIGNAL cho2       : IN std_logic_vector(LENDEF-1 DOWNTO 0);    -- AD7782-IF Data-Input CH2

      SIGNAL rngo       : OUT std_logic;                             -- Range output to ADC
      SIGNAL scho       : OUT std_logic;                             -- Chanel select to ADC
      SIGNAL ain1       : OUT real;                                  -- Analog input for ADC
      SIGNAL ain2       : OUT real;                                  -- Analog input for ADC
      SIGNAL strb       : OUT std_logic;                             -- Strobe output to ADC

      SIGNAL myOut      : OUT std_logic_vector(LENDEF-1 DOWNTO 0)    -- Procedure output Result
      ) IS
   BEGIN
      WAIT UNTIL rising_edge(clk);
      
      rngo     <= rngi;
      scho     <= schi;
      IF schi='0' THEN
         ain1  <= ain;
      ELSE
         ain2  <= ain;
      END IF;

      strb     <= '1';

      WAIT UNTIL done = '1';
      IF schi='0' THEN
         myOut <= cho1;
      ELSE
         myOut <= cho2;
      END IF;
      
      strb     <= '0';

   END getAD_velue;


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
            rsel  => rsel,
            din   => adot,
            rng   => rng,
            sel   => sel,
            mode  => mode,
            cs    => cs,
            sclk  => sclk,
            done  => done,
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

END verhalten;