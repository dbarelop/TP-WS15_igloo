
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY transmitter IS
   GENERIC(RSTDEF: std_logic := '0';
           LENDEF: natural   := 8);
   PORT(rst:   IN  std_logic;  -- reset RSTDEF active
        clk:   IN  std_logic;  -- clock, rising edge active
        swrst: IN  std_logic;  -- software reset, RSTDEF active
        strb:  IN  std_logic;  -- strobe, high active, from baud rate generator (x16)
        din:   IN  std_logic_vector(LENDEF-1 DOWNTO 0); -- data input
        wren:  IN  std_logic;  -- write enable, high active
        txd:   OUT std_logic;  -- transmit data output, high active
        tsre:  OUT std_logic;  -- transmit shift   register empty, high active
        thre:  OUT std_logic); -- transmit holding register empty, high active
END transmitter;


-- asynchrones Handshaking:
-- thre: 0->1
-- Daten werden bereitgestellt, wren: 0->1
-- thre: 1->0
-- wren: 1->0

-- feste Baudrate
-- Uebertragungsframe:
-- Startbit + Data.Bit(0) + .. + Data.Bit(LENDEF-1) + Stoppbit
-- Zuerst wird das LSB Data.Bit(0) vom Datum gesendet
ARCHITECTURE verhalten OF transmitter IS
   SIGNAL tsr:    std_logic_vector(LENDEF   DOWNTO 0); -- transmit shift   register
   SIGNAL thr:    std_logic_vector(LENDEF-1 DOWNTO 0); -- transmit holding register
   SIGNAL hre:    std_logic; -- holding register empty
   SIGNAL sre:    std_logic; -- shift register empty
   SIGNAL cnt16:  natural RANGE 0 TO 15;
   SIGNAL cnt10:  natural RANGE 0 TO  LENDEF+1;
BEGIN

   thre <= hre;
   tsre <= sre;
   txd  <= tsr(0);

   PROCESS (rst, clk) IS
      PROCEDURE reset IS
      BEGIN
         thr   <= (OTHERS => '0');
         tsr   <= (OTHERS => '1');
         hre   <= '1';
         sre   <= '1';
         cnt16 <=  0;
         cnt10 <=  0;
      END PROCEDURE;
   BEGIN
      IF rst=RSTDEF THEN
         reset;
      ELSIF rising_edge(clk) THEN
         IF strb='1' THEN
            -- dieser Abschnitt ist vom strobe-Signal abhaengig
            IF NOT(sre='1') THEN
               -- wenn das Shift-Register nicht leer ist,
               -- dann schiebe das Register solange, bis
               -- alle Bits transportiert sind.

               cnt16 <= (cnt16 + 1) MOD 16; -- freilaufender Zaehler

               IF cnt16=15 THEN
                  tsr   <= '1' & tsr(tsr'LEFT DOWNTO tsr'RIGHT+1);
                  cnt10 <= cnt10 + 1;
               END IF;
               IF cnt10=LENDEF+1 AND cnt16=14 THEN
                  sre <= '1';
               END IF;
            ELSE
               -- die Uebernahme der Daten in das Shift-Register ist nur dann
               -- moeglich, wenn das Shift-Register leer ist, und wenn im
               -- Holding-Register Daten vorhanden sind
               -- Ressourcen-Optimierung:
               -- Das Stoppbit im TSR braucht nicht explizit angegeben zu werden,
               -- denn beim Shiften wird das TSR immer mit '1' nachgeladen
               IF NOT(hre='1') THEN
                  tsr   <= thr & '0';
                  sre   <= '0';
                  hre   <= '1';
                  cnt16 <=  0;
                  cnt10 <=  0;
               END IF;
            END IF;
         END IF;

         -- Uebernahme der Daten in das Holding-Register erfolgt synchron
         -- aber vom strobe-Signal unabhaengig
         IF wren='1' AND hre='1' THEN
            thr <= din;
            hre <= '0';
         END IF;

         IF swrst=RSTDEF THEN
            reset;
         END IF;
      END IF;
   END PROCESS;

END verhalten;