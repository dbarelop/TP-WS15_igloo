
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_signed.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY ADT7301 IS
   PORT(sclk: IN  std_logic;  -- serial clock input
        cs:   IN  std_logic;  -- chip select, low active
        din:  IN  std_logic;  -- serial data input
        dout: OUT std_logic); -- serial data output
END ADT7301;

-- Data is clocked into the control register on the rising edge of SCLK.
-- The SCLK input is disabled when CS is high.
-- Data is clocked out on the falling edge of SCLK.

ARCHITECTURE verhalten OF ADT7301 IS

   CONSTANT conv_time: time := 1.2 ms;
   CONSTANT loop_time: time := 150 ms;
   
   FUNCTION conv_std_logic_vector(arg: real; size: natural) RETURN std_logic_vector IS
      VARIABLE tmp2: integer;
   BEGIN
      tmp2 := integer(arg);
      RETURN conv_std_logic_vector(tmp2, size);
   END FUNCTION;

   SIGNAL sor:  std_logic_vector(15 DOWNTO 0); -- serial output register
   SIGNAL rsr:  std_logic_vector(15 DOWNTO 0);
   SIGNAL tvr:  std_logic_vector(13 DOWNTO 0); -- temperature value register
   SIGNAL temp: real;
 
BEGIN
   
   dout <= sor(15) AFTER 35 ns WHEN cs='0' ELSE 'Z' AFTER 40 ns;

   -- Writes the value of the 'tvr' in the 'sor' register and shifts it to the left every cycle
   p1: PROCESS (cs, sclk) IS
      VARIABLE cnt: integer RANGE 0 TO 15 := 0;
   BEGIN
      IF cs='0' THEN
         IF falling_edge(sclk) THEN
            IF cnt=0 THEN
               sor <= "00" & tvr;
            ELSE
               sor <= sor(14 DOWNTO 0) & '0';
            END IF;   
            cnt := (cnt + 1) MOD 16;
         END IF;
      END IF;
   END PROCESS;

   -- Shifts the 'rsr' register to the left and writes the data from 'din' pin
   p2: PROCESS (cs, sclk) IS
   BEGIN
      IF cs='0' THEN
         IF rising_edge(sclk) THEN
            rsr <= rsr(14 DOWNTO 0) & din;
         END IF;
      END IF;
   END PROCESS;
   
   -- measurement range of the device (-40øC to +150øC).
   p3: PROCESS
      CONSTANT Resolution: real := 0.03125;
      CONSTANT MinTemp:    real := -40.0;
      CONSTANT MaxTemp:    real := +150.0;
      VARIABLE dt:         real := Resolution;
   BEGIN
      temp <= MinTemp;
      WAIT FOR conv_time;
      tvr  <= conv_std_logic_vector(temp/Resolution, tvr'LENGTH);
      LOOP
         WAIT FOR loop_time;
         IF temp >= MaxTemp THEN
            dt := -Resolution;
         ELSIF temp <= MinTemp THEN
            dt := +Resolution;
         END IF;
         temp <= temp + dt;
         WAIT FOR conv_time;
         tvr  <= conv_std_logic_vector(temp/Resolution, tvr'LENGTH);
      END LOOP;
   END PROCESS;
  
END verhalten;
      