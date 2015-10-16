
ENTITY uart_tb IS
   -- empty
END uart_tb;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;

ARCHITECTURE verhalten OF uart_tb IS

   CONSTANT RSTDEF: std_ulogic := '1'; -- high active
   CONSTANT FRQDEF: real       := 1.0e6;
   CONSTANT BAUDEF: real       := 19.2e3;
   CONSTANT tpd:    time       := 1 sec / FRQDEF;

   SUBTYPE std_byte IS std_logic_vector(7 DOWNTO 0);

   COMPONENT uart
      GENERIC(RSTDEF: std_logic;
              BAUDEF: real;   -- baud rate
              FRQDEF: real);  -- clock frequency
      PORT(rst:   IN  std_logic;  -- reset RSTDEF active
           clk:   IN  std_logic;  -- clock, rising edge active
           swrst: IN  std_logic;  -- software reset,  RSTDEF active
           ena:   IN  std_logic;  -- enable,          high active

           rxd:   IN  std_logic;  -- receive data
           rden:  IN  std_logic;  -- read enable,     high active
           dout:  OUT std_logic_vector(7 DOWNTO 0);
           rhrf:  OUT std_logic;  -- RHR full,        high active
           ovre:  OUT std_logic;  -- overrun error,   high active
           frme:  OUT std_logic;  -- framing error,   high active

           txd:   OUT std_logic;  -- transmit data output, high active
           wren:  IN  std_logic;  -- write enable, high active
           din:   IN  std_logic_vector(7 DOWNTO 0); -- data input
           tsre:  OUT std_logic;  -- transmit shift   register empty, high active
           thre:  OUT std_logic); -- transmit holding register empty, high active
   END COMPONENT;

   SIGNAL rst:   std_logic := RSTDEF;
   SIGNAL hlt:   std_logic := '0';
   SIGNAL clk:   std_logic := '0';
   SIGNAL swrst: std_logic := NOT RSTDEF;
   SIGNAL ena:   std_logic := '1';
   SIGNAL sdo:   std_logic := '1';
   SIGNAL frm:   std_logic := '0';
   SIGNAL rden:  std_logic := '0';
   SIGNAL rhrf:  std_logic := '0';
   SIGNAL ovre:  std_logic := '0';
   SIGNAL frme:  std_logic := '0';
   SIGNAL sdi:   std_logic := '1';
   SIGNAL wren:  std_logic := '0';
   SIGNAL tsre:  std_logic := '1';
   SIGNAL thre:  std_logic := '1';
   SIGNAL sig:   std_logic := '0';
   
   SIGNAL rx_data: std_byte := (OTHERS => '0');
   SIGNAL tx_data: std_byte := (OTHERS => '0');

BEGIN

   rst <= RSTDEF, NOT RSTDEF AFTER 15*tpd;
   clk <= not(clk) AFTER tpd/2  WHEN hlt='0' ELSE clk;

   u1: uart
   GENERIC MAP(RSTDEF => RSTDEF,
               BAUDEF => BAUDEF,
               FRQDEF => FRQDEF)
   PORT MAP(rst   => rst,
            clk   => clk,
            swrst => swrst,
            ena   => ena,
            rxd   => sdo,
            dout  => rx_data,
            rden  => rden,
            rhrf  => rhrf,
            ovre  => ovre,
            frme  => frme,
            txd   => sdi,
            wren  => wren,
            din   => tx_data,
            tsre  => tsre,
            thre  => thre);

   test: PROCESS IS
      CONSTANT dly: time := 1 sec / BAUDEF;

      PROCEDURE clock(n: positive) IS
      BEGIN
         FOR i IN 1 TO n LOOP
            WAIT UNTIL clk='1';
         END LOOP;
      END PROCEDURE;

      PROCEDURE test1_send(arg: natural) IS
         VARIABLE tmp: std_byte;
      BEGIN
         tmp  := conv_std_logic_vector(arg, tmp'LENGTH);
         sdo  <= '0'; -- Startbit
         frm  <= '1'; -- Framebit
         WAIT FOR dly;
         frm  <= '0';
         FOR i IN 0 TO 7 LOOP
            sdo <= tmp(i);
            WAIT FOR dly;
         END LOOP;
         sdo  <= '1';
         WAIT FOR dly;
      END PROCEDURE;

      PROCEDURE test1_check(arg: natural) IS
         VARIABLE tmp: natural;
      BEGIN
         clock(1);
         WHILE rhrf='0' LOOP
            clock(1);
         END LOOP;
         rden <= '1';
         tmp  := conv_integer('0' & rx_data);
         clock(1);
         rden <= '0';
         ASSERT arg=tmp REPORT "wrong data" SEVERITY error;
      END PROCEDURE;

      PROCEDURE test2_send(arg: natural) IS
      BEGIN
         clock(1);
         WHILE thre='0' LOOP
            clock(1);
         END LOOP;
         WHILE tsre='0' LOOP
            clock(1);
         END LOOP;
         wren <= '1';
         tx_data <= conv_std_logic_vector(arg, tx_data'LENGTH);
         clock(1);
         wren <= '0';
      END PROCEDURE;

      PROCEDURE test2_check(arg: natural) IS
         VARIABLE tmp: std_byte;
         VARIABLE res: natural;
      BEGIN
         WHILE sdi='1' LOOP
            WAIT FOR dly/16;
         END LOOP;
         WAIT FOR (7*dly)/16;
         sig <= '1', '0' AFTER 100 ns;
         ASSERT sdi='0' REPORT "wrong start bit" SEVERITY error;
         FOR i IN 0 TO 7 LOOP
            WAIT FOR dly;
            sig <= '1', '0' AFTER 100 ns;
            tmp(i) := sdi;
         END LOOP;
         WAIT FOR dly;
         sig <= '1', '0' AFTER 100 ns;
         ASSERT sdi='1' REPORT "wrong stop bit" SEVERITY error;
         res := conv_integer('0' & tmp);
         ASSERT arg=res REPORT "wrong data" SEVERITY error;
      END PROCEDURE;

   BEGIN

      WAIT UNTIL rst=NOT RSTDEF;
      WAIT FOR dly;

      FOR i IN 16#00# TO 16#FF# LOOP
         test1_send(i);
         test1_check(i);
      END LOOP;

      FOR i IN 16#00# TO 16#FF# LOOP
         test2_send(i);
         test2_check(i);
      END LOOP;

      hlt <= '1';
      WAIT;
   END PROCESS;

END verhalten;