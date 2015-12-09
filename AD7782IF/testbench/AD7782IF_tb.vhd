LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY AD7782IF_tb IS
   -- empty
END AD7782IF_tb;

ARCHITECTURE verhalten OF AD7782IF_tb IS

   CONSTANT RSTDEF: std_logic := '1';
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

   SIGNAL a:   real;
   SIGNAL r:   std_logic;
   SIGNAL c:   std_logic;

   SIGNAL rst:  std_logic := RSTDEF;
   SIGNAL clk:  std_logic := '0';
   SIGNAL ena:  std_logic := '1';
   SIGNAL result: std_logic_vector (LENDEF-1 DOWNTO 0) := (OTHERS => '0');
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
   SIGNAL done: std_logic := '0';
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
      SIGNAL mystrb     : OUT std_logic;                             -- Strobe output to ADC

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

      mystrb     <= '1';
      WAIT UNTIL rising_edge(clk);
      mystrb     <= '0';

      WAIT UNTIL done = '1';
      IF schi='0' THEN
         myOut <= cho1;
      ELSE
         myOut <= cho2;
      END IF;
      
      WAIT UNTIL rising_edge(clk);

   END getAD_velue;


BEGIN
   rst  <= RSTDEF, not RSTDEF after 50 us;
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

   t1: PROCESS
   BEGIN
      wait for 1 ms;
      WAIT UNTIL rising_edge(clk);

      a <= -2.5;
      r <= '1';
      c <= '0';
      getAD_velue(a, r, c, ch1, ch2, rsel, csel, ain1, ain2, strb, result);
      ASSERT (result = X"030000") REPORT "fail 1" SEVERITY ERROR;

      WAIT FOR 2 us;

      a <= -1.5;
      r <= '1';
      c <= '0';
      getAD_velue(a, r, c, ch1, ch2, rsel, csel, ain1, ain2, strb, result);
      ASSERT (result = X"350000") REPORT "fail 2" SEVERITY ERROR;

      WAIT FOR 2 us;

      a <= -0.5;
      r <= '1';
      c <= '0';
      getAD_velue(a, r, c, ch1, ch2, rsel, csel, ain1, ain2, strb, result);
      ASSERT (result = X"670000") REPORT "fail 3" SEVERITY ERROR;

      WAIT FOR 2 us;

      a <= 0.0;
      r <= '1';
      c <= '0';
      getAD_velue(a, r, c, ch1, ch2, rsel, csel, ain1, ain2, strb, result);
      ASSERT (result = X"800000") REPORT "fail 4" SEVERITY ERROR;

      WAIT FOR 2 us;

      a <= 0.5;
      r <= '1';
      c <= '0';
      getAD_velue(a, r, c, ch1, ch2, rsel, csel, ain1, ain2, strb, result);
      ASSERT (result = X"990000") REPORT "fail 5" SEVERITY ERROR;

      WAIT FOR 2 us;

      a <= 1.5;
      r <= '1';
      c <= '0';
      getAD_velue(a, r, c, ch1, ch2, rsel, csel, ain1, ain2, strb, result);
      ASSERT (result = X"CB0000") REPORT "fail 6" SEVERITY ERROR;

      WAIT FOR 2 us;

      a <= 2.5;
      r <= '1';
      c <= '0';
      getAD_velue(a, r, c, ch1, ch2, rsel, csel, ain1, ain2, strb, result);
      ASSERT (result = X"FD0000") REPORT "fail 7" SEVERITY ERROR;

--
---------------------start---rage---test-----------------------------------------------
--

      WAIT FOR 2 us;

      a <= 5.0;
      r <= '0';
      c <= '0';
      getAD_velue(a, r, c, ch1, ch2, rsel, csel, ain1, ain2, strb, result);
      ASSERT (result = X"FFFFFF") REPORT "fail r1" SEVERITY ERROR;

      WAIT FOR 2 us;

      a <= 0.16;
      r <= '0';
      c <= '0';
      getAD_velue(a, r, c, ch1, ch2, rsel, csel, ain1, ain2, strb, result);
      ASSERT (result = X"FFFFFF") REPORT "fail r2" SEVERITY ERROR;

      WAIT FOR 2 us;

      a <= 0.03;
      r <= '0';
      c <= '0';
      getAD_velue(a, r, c, ch1, ch2, rsel, csel, ain1, ain2, strb, result);
      ASSERT (result = X"980000") REPORT "fail r3" SEVERITY ERROR;

      WAIT FOR 2 us;

      a <= 0.0;
      r <= '0';
      c <= '0';
      getAD_velue(a, r, c, ch1, ch2, rsel, csel, ain1, ain2, strb, result);
      ASSERT (result = X"800000") REPORT "fail r4" SEVERITY ERROR;

      WAIT FOR 2 us;

      a <= -0.03;
      r <= '0';
      c <= '0';
      getAD_velue(a, r, c, ch1, ch2, rsel, csel, ain1, ain2, strb, result);
      ASSERT (result = X"680000") REPORT "fail r5" SEVERITY ERROR;

      WAIT FOR 2 us;

      a <= -0.16;
      r <= '0';
      c <= '0';
      getAD_velue(a, r, c, ch1, ch2, rsel, csel, ain1, ain2, strb, result);
      ASSERT (result = X"000000") REPORT "fail r6" SEVERITY ERROR;      -- sould it be FFFFFF???

      WAIT FOR 2 us;

      a <= -5.0;
      r <= '0';
      c <= '0';
      getAD_velue(a, r, c, ch1, ch2, rsel, csel, ain1, ain2, strb, result);
      ASSERT (result = X"000000") REPORT "fail r7" SEVERITY ERROR;      -- sould it be FFFFFF???

--
---------------------start---chanel---test-----------------------------------------------
--
   
      WAIT FOR 2 us;

      a <= 2.5;
      r <= '1';
      c <= '1';
      getAD_velue(a, r, c, ch1, ch2, rsel, csel, ain1, ain2, strb, result);
      ASSERT (result = X"FD0000") REPORT "fail c11" SEVERITY ERROR;
      ASSERT (sel = '1') REPORT "fail c12" SEVERITY ERROR;

      WAIT FOR 2 us;

      a <= -2.5;
      r <= '1';
      c <= '1';
      getAD_velue(a, r, c, ch1, ch2, rsel, csel, ain1, ain2, strb, result);
      ASSERT (result = X"030000") REPORT "fail c21" SEVERITY ERROR;
      ASSERT (sel = '1') REPORT "fail c22" SEVERITY ERROR;

      WAIT;
   END PROCESS;

END verhalten;