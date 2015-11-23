LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;

ENTITY AD7782 IS
   GENERIC(ref: real := 2.5);
   PORT(ain1: IN  real;        -- analog input: +/- Ref
        ain2: IN  real;        -- analog input: +/- Ref
        rng:  IN  std_logic;   -- logic input which configures the input range on the internal PGA
        sel:  IN  std_logic;   -- logic input which selects the active channel AIN1 oo ANI2
        mode: IN  std_logic;   -- logic input which selects master (=0) or slave (=1) mode of operation
        sclk: IN  std_logic;   -- serial clock output
        cs:   IN  std_logic;   -- chip select, low active
        dout: OUT std_logic);  -- serial data output
END AD7782;

ARCHITECTURE verhalten OF AD7782 IS

   CONSTANT PLLFRQ:      real    := 4.194304e6;
   CONSTANT tcyc:        time    := 1 sec / PLLFRQ;

   CONSTANT StartUpTime: time    := 200 ns; -- 00 ms;
   CONSTANT FRQDEF:      real    := 32.768e3;
   CONSTANT OutputRate:  real    := FRQDEF / (69.0 * 8.0 * 3.0);
   CONSTANT tADC:        time    := 1 sec / OutputRate;
   CONSTANT tSETTLE:     time    := 2 * tADC;
   CONSTANT N:           natural := 24;

   TYPE tstate IS (S0, S1, S2);

   SIGNAL dat: std_logic_vector(N-1 DOWNTO 0) := (OTHERS => '0');    -- register storing the conversion result
   SIGNAL tsr: std_logic_vector(N   DOWNTO 0) := (OTHERS => '1');    -- shift register storing the data left to be transmitted

   SIGNAL clk:   std_logic := '0';
   SIGNAL lock:  std_logic := '0';
   SIGNAL wre:   std_logic := '0';     -- write enable -> when high dumps dat register into tsr ('0' appended as MSB)
   SIGNAL state: tstate;

BEGIN

   lock <= '0', '1' AFTER StartUpTime;

   clk  <= NOT clk AFTER tcyc/2 WHEN lock='1' AND cs='0' ELSE '0';

   p1: PROCESS (cs, clk) IS
      VARIABLE tmp:  integer;
      VARIABLE ain:  real;       -- selected analog input
      VARIABLE gain: real;
      VARIABLE old:  std_logic;  -- previously selected channel
      VARIABLE cnt:  integer;    -- counter
   BEGIN
   -- Waits for a number of cycles and performs the conversion
   -- of the selected channel input 
      IF cs='1' THEN
         state <= S0;
         ain   := 0.0;
         gain  := 0.0;
         old   := '0';
         wre   <= '0';
         cnt   := 0;
         dat   <= (OTHERS => '0');
      ELSIF rising_edge(clk) THEN
         CASE state IS
            WHEN S0 =>
            -- Selects input channel und establishes gain and cnt
               IF sel='0' THEN
                  ain := ain1;
               ELSE
                  ain := ain2;
               END IF;
               IF rng='1' THEN
                  gain := 1.0;
               ELSE
                  gain := 16.0;
               END IF;
               IF sel /= old THEN                     -- tSETTLE = 2*tADC -> if the channel selection changes
                  cnt := integer(tSETTLE/tcyc);       -- the conversion will take twice as much time to be made
               ELSE
                  cnt := integer(tADC/tcyc);
               END IF;
               old := sel;
               state <= S1;
            WHEN S1 =>
            -- Waits for cnt cycles before performing the confversion
               IF cnt=0 THEN
                  state <= S2;
               ELSE
                  cnt := cnt - 1;
               END IF;
            WHEN S2 =>
            -- Performs the conversion
               tmp   := integer(2.0**(N-1) * ((ain*gain / (1.024*ref)) + 1.0));     -- gain can bee 1 on +-2.56V Range or 16 on 160mV Range
               dat   <= conv_std_logic_vector(tmp, N);                              -- convert the integer tmp to an log_vector 
               wre   <= '1' AFTER 10 ns, '0' AFTER 20 ns;
               state <= S0;
         END CASE;
      END IF;
   END PROCESS;

   -- This clock shifts out the conversion results on the falling edge of SCLK.
   p2: PROCESS (sclk, wre) IS
      -- Not used?
      VARIABLE arg: real;
      VARIABLE tmp: integer;
   BEGIN
      IF wre='1' THEN
         tsr <= '0' & dat;
      ELSIF falling_edge(sclk) THEN
      -- Shifts tsr 1 bit to the left and feeds '1' on the right
         tsr <= tsr(tsr'LEFT-1 DOWNTO tsr'RIGHT) & '1';
      END IF;
   END PROCESS;

   -- Sends tsr MSB through dout on CS low (80 ns/bit)
   dout <= tsr(tsr'LEFT) AFTER 80 ns WHEN lock='1' AND cs='0' ELSE 'Z' AFTER 80 ns;

END verhalten;