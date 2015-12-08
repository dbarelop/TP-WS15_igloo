LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_signed.ALL;
USE ieee.std_logic_arith.ALL;

-- The MODE pin selects master or slave mode of operation. When MODE = 0, the AD7782 operates in
-- master mode while the AD7782 is configured for slave mode when MODE = 1.

-- With sel = 0, channel AIN1(+)/AIN1(-) is selected while the active
-- channel is AIN2(+)/AIN2(-) when sel = 1.

-- With RNG = 0, the full-scale input range is +/-160 mV while the full-scale
-- input range equals +/-2.56 V when RANGE = 1 for a +2.5 V Reference.

-- Data is output on the falling SCLK edge and is valid on the rising edge

-- When the analog input channel is switched, the settling time of the part must elapse
-- before a new valid word is available from the ADC.

ENTITY AD7782IF IS
   GENERIC(RSTDEF: std_logic := '1');
   PORT(rst:  IN  std_logic;  -- reset RSTDEF active
        clk:  IN  std_logic;  -- rising edge active, 1 MHz
        strb: IN  std_logic;  -- strobe, high active
        csel: IN  std_logic;  -- select wich chanel is used
        rng:  OUT std_logic;  -- logic output which configures the input range on the internal PGA
        sel:  OUT std_logic;  -- logic output which selects the active channel AIN1 (=0) or ANI2 (=1)
        mode: OUT std_logic;  -- logic output which selects master (=0) or slave (=1) mode of operation
        cs:   OUT std_logic;  -- chip select, low active
        sclk: OUT std_logic;  -- serial clock output
        din:  IN  std_logic;  -- serial data input
        ch1:  OUT std_logic_vector(LENDEF-1 DOWNTO 0);
        ch2:  OUT std_logic_vector(LENDEF-1 DOWNTO 0));
END AD7782IF;

ARCHITECTURE behaviour OF AD7782IF IS

   CONSTANT LENDEF: natural   := 24;
   CONSTANT MASTER: std_logic := '0';
   CONSTANT SLAVE:  std_logic := '1';
   CONSTANT CPOL:   std_logic := '1';

   TYPE tstate IS (S0, S1, S2, S3, S4);

   SIGNAL state: tstate;
   SIGNAL dff1:  std_logic;
   SIGNAL dff2:  std_logic;
   SIGNAL reg:   std_logic_vector(LENDEF-1 DOWNTO 0); -- shift register

BEGIN

   mode <= SLAVE;
   rng  <= '1';
   sel  <= csel;

   p1: PROCESS (rst, clk) IS
   BEGIN
      IF rst=RSTDEF THEN
         dff1 <= '1';
         dff2 <= '1';
      ELSIF rising_edge(clk) THEN
         dff1 <= din;
         dff2 <= dff1;
      END IF;
   END PROCESS;

   p2: PROCESS (rst, clk) IS
      CONSTANT MAXCNT: natural := reg'LENGTH;
      VARIABLE cnt: integer RANGE 0 TO MAXCNT-1;
   BEGIN
      IF rst=RSTDEF THEN
         state <= S0;
         cs    <= '1';
         sclk  <= CPOL;
         reg   <= (OTHERS => '0');
         ch1   <= (OTHERS => '0');
         ch2   <= (OTHERS => '0');
      ELSIF rising_edge(clk) THEN
         CASE state IS
            WHEN S0 =>
               IF strb='1' THEN
                  state <= S1;
                  cs    <= '0';
               END IF;
            WHEN S1 =>
               IF dff2='0' THEN
                  cnt   := 0;
                  state <= S2;
               END IF;
            WHEN S2 =>
               sclk  <= '0';
               state <= S3;
            WHEN S3 =>
               sclk <= '1';
               reg  <= reg(reg'LEFT-1 DOWNTO reg'RIGHT) & din;
               IF cnt=MAXCNT-1 THEN
                  state <= S4;
               ELSE
                  state <= S2;
                  cnt   := cnt + 1;
               END IF;
            WHEN S4 =>
               cs <= '1';
               IF csel='0' THEN
                  ch1 <= reg(LENDEF-1 DOWNTO 0);
               ELSE
                  ch2 <= reg(LENDEF-1 DOWNTO 0);
               END IF;
               state <= S0;
         END CASE;
      END IF;
   END PROCESS;

END behaviour;