
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY receiver IS
   GENERIC(RSTDEF: std_logic := '1';
           LENDEF: natural   := 8);
   PORT(rst:   IN  std_logic;  -- reset RSTDEF active
        clk:   IN  std_logic;  -- clock, rising edge active
        swrst: IN  std_logic;  -- software reset,  RSTDEF active
        strb:  IN  std_logic;  -- strobe,          high active
        rxd:   IN  std_logic;  -- receive data
        rden:  IN  std_logic;  -- read enable,     high active
        dout:  OUT std_logic_vector(LENDEF-1 DOWNTO 0);
        rhrf:  OUT std_logic;  -- RHR full,        high active
        ovre:  OUT std_logic;  -- overrun error,   high active
        frme:  OUT std_logic); -- framing error,   high active
END receiver;


-- LSB wird zuerst empfangen
ARCHITECTURE behaviour OF receiver IS

   TYPE   TState IS (S0, S1, S2, S3, S4, S5, S6, S7,
                     R0, R1, R2, R3, R4, R5, R6, R7, R8,
                     R9, R10, R11, R12, R13, R14, R15, R16);

   SIGNAL state: TState;
   SIGNAL rsr:   std_logic_vector(LENDEF-1 DOWNTO 0); -- receive shift register
   SIGNAL len:   natural RANGE 0 TO LENDEF;
   SIGNAL done:  std_logic;
   SIGNAL tmp:   std_logic;
BEGIN

   rhrf <= done;

   PROCESS (rst, clk)
      PROCEDURE reset IS
      BEGIN
         state <= S0;
         rsr   <= (OTHERS => '0');
         dout  <= (OTHERS => '0');
         len   <= LENDEF-1;
         done  <= '0';
         ovre  <= '0';
         frme  <= '0';
         tmp   <= '0';
      END PROCEDURE;
   BEGIN
      IF rst=RSTDEF THEN
         reset;
      ELSIF rising_edge(clk) THEN
         tmp <= '0';
         IF rden='1' THEN
            done <= '0';
            ovre <= '0';
            frme <= '0';
         END IF;
         IF strb='1' THEN
            CASE state IS
               WHEN S0 =>  state <= S0;
                  IF rxd='0' THEN
                     state <= S1;
                  END IF;
               WHEN S1  => state <= S2;
               WHEN S2  => state <= S3;
               WHEN S3  => state <= S4;
               WHEN S4  => state <= S5;
               WHEN S5  => state <= S6;
               WHEN S6  => state <= S7;
               WHEN S7  => state <= S0;
                  len <= LENDEF;
                  tmp <= '1';
                  IF rxd='0' THEN
                     state <= R0;
                  END IF;
               WHEN R0  => state <= R1;
               WHEN R1  => state <= R2;
               WHEN R2  => state <= R3;
               WHEN R3  => state <= R4;
               WHEN R4  => state <= R5;
               WHEN R5  => state <= R6;
               WHEN R6  => state <= R7;
               WHEN R7  => state <= R8;
               WHEN R8  => state <= R9;
               WHEN R9  => state <= R10;
               WHEN R10 => state <= R11;
               WHEN R11 => state <= R12;
               WHEN R12 => state <= R13;
               WHEN R13 => state <= R14;
               WHEN R14 => state <= R15;
                  IF len=0 THEN
                     state <= R16;
                  END IF;
               WHEN R15 => state <= R0;
                  tmp  <= '1';
                  rsr  <= rxd & rsr(LENDEF-1 DOWNTO 1);
                  len  <= len - 1;
               WHEN R16 => state <= S0;
                  tmp  <= '1';
                  dout <= rsr(LENDEF-1 DOWNTO 0);
                  done <= rxd;
                  ovre <= done AND NOT rden;
                  frme <= NOT rxd;
            END CASE;
         END IF;
         IF swrst=RSTDEF THEN
            reset;
         END IF;
      END IF;
   END PROCESS;

END behaviour;