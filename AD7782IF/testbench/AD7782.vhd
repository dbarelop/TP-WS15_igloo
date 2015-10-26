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

   CONSTANT StartUpTime: time    := 3 ms; -- 00 ms;
   CONSTANT FRQDEF:      real    := 32.768e3;
   CONSTANT OutputRate:  real    := FRQDEF / (69.0 * 8.0 * 3.0);
   CONSTANT tADC:        time    := 1 sec / OutputRate;
   CONSTANT tSETTLE:     time    := 2 * tADC;
   CONSTANT N:           natural := 24;

   TYPE tstate IS (S0, S1, S2);

   SIGNAL dat: std_logic_vector(N-1 DOWNTO 0) := (OTHERS => '0');
   SIGNAL tsr: std_logic_vector(N   DOWNTO 0) := (OTHERS => '1'); 		--was ist tsr?

   SIGNAL clk:   std_logic := '0';
   SIGNAL lock:  std_logic := '0';
   SIGNAL wre:   std_logic := '0'; --evt. write enable
   SIGNAL state: tstate;

BEGIN

   lock <= '0', '1' AFTER StartUpTime;

   clk  <= NOT clk AFTER tcyc/2 WHEN lock='1' AND cs='0' ELSE '0';

   p1: PROCESS (cs, clk) IS
      VARIABLE tmp:  integer;
      VARIABLE ain:  real;		-- analog input
      VARIABLE gain: real;
      VARIABLE old:  std_logic; -- alter Wert von sel
      VARIABLE cnt:  integer;	-- counter
   BEGIN
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
               IF sel /= old THEN
                  cnt := integer(tSETTLE/tcyc);
               ELSE
                  cnt := integer(tADC/tcyc);
               END IF;
               old := sel;
               state <= S1;
            WHEN S1 =>				--S1 counts the cnt dont to "0" and switch to S2
               IF cnt=0 THEN
                  state <= S2;
               ELSE
                  cnt := cnt - 1;
               END IF;
            WHEN S2 =>
               tmp   := integer(2.0**(N-1) * ((ain*gain / (1.024*ref)) + 1.0));		-- gain can bee 1 on +-2.56V Range or 16 on 160mV Range
               dat   <= conv_std_logic_vector(tmp, N);								-- convert the integer tmp to an log_vector 
               wre   <= '1' AFTER 10 ns, '0' AFTER 20 ns;
               state <= S0;
         END CASE;
      END IF;
   END PROCESS;

   -- This clock shifts out the conversion results on the falling edge of SCLK.
   p2: PROCESS (sclk, wre) IS
      VARIABLE arg: real;		--wo wird das verwendet???
      VARIABLE tmp: integer;	--wo wird...
   BEGIN
      IF wre='1' THEN			--warum so nicht in zwei verschiedene Prozesse?
         tsr <= '0' & dat;
      ELSIF falling_edge(sclk) THEN
         tsr <= tsr(tsr'LEFT-1 DOWNTO tsr'RIGHT) & '1';									-- Shift register? nach Links mit 1 füllen
      END IF;
   END PROCESS;

   dout <= tsr(tsr'LEFT) AFTER 80 ns WHEN lock='1' AND cs='0'  ELSE 'Z' AFTER 80 ns;	-- gibt register tsr aus -- Buisy flag for the time device is busisy

END verhalten;