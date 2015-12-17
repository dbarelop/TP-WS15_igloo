LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY uart IS
   GENERIC(RSTDEF: std_logic := '1';
           BAUDEF: real      := 9.6e3;  -- baud rate
           FRQDEF: real      := 1.0e6);  -- clock frequency
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
END uart;

ARCHITECTURE structure OF uart IS

   CONSTANT INIVAL: std_logic := '1';
   CONSTANT LENDEF: natural   := 8;

   COMPONENT sync_flipflop
      GENERIC(RSTDEF: std_logic;
              INIVAL: std_logic);
      PORT(rst:  IN  std_logic;  -- reset, high active
           clk:  IN  std_logic;  -- clock, rising edge active
           din:  IN  std_logic;  -- data input
           dout: OUT std_logic); -- data output
   END COMPONENT;

   COMPONENT glitchfilter
      GENERIC(RSTDEF: std_logic;
              INIVAL: std_logic);
      PORT(rst:   IN  std_logic;  -- reset,           RSTDEF active
           clk:   IN  std_logic;  -- clock,           rising edge
           swrst: IN  std_logic;  -- software reset,  RSTDEF active
           ena:   IN  std_logic;  -- enable input,    high active
           din:   IN  std_logic;  -- data input,      idle high active
           dout:  OUT std_logic); -- data output,     idle high active
   END COMPONENT;

   COMPONENT baudgen
      GENERIC(RSTDEF:  std_logic;
              BAUDEF:  real;
              FRQDEF:  real);
      PORT(rst:   IN  std_logic;  -- reset RSTDEF active
           clk:   IN  std_logic;  -- rising edge active
           swrst: IN  std_logic;  -- software reset,  RSTDEF active
           ena:   IN  std_logic;  -- enable, high active
           strb:  OUT std_logic); -- strobe, high active
   END COMPONENT;

   COMPONENT receiver IS
      GENERIC(RSTDEF: std_logic;
              LENDEF: natural);
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
   END COMPONENT;

   COMPONENT transmitter IS
      GENERIC(RSTDEF: std_logic;
              LENDEF: natural);
      PORT(rst:   IN  std_logic;  -- reset RSTDEF active
           clk:   IN  std_logic;  -- clock, rising edge active
           swrst: IN  std_logic;  -- software reset, RSTDEF active
           strb:  IN  std_logic;  -- strobe, high active, from baud rate generator (x16)
           din:   IN  std_logic_vector(LENDEF-1 DOWNTO 0); -- data input
           wren:  IN  std_logic;  -- write enable, high active
           txd:   OUT std_logic;  -- transmit data output, high active
           tsre:  OUT std_logic;  -- transmit shift   register empty, high active
           thre:  OUT std_logic); -- transmit holding register empty, high active
   END COMPONENT;

   SIGNAL strb: std_logic;
   SIGNAL rxd1: std_logic;
   SIGNAL rxd2: std_logic;

BEGIN

   sff: sync_flipflop
   GENERIC MAP(RSTDEF => RSTDEF,
               INIVAL => INIVAL)
   PORT MAP(rst  => rst,
            clk  => clk,
            din  => rxd,
            dout => rxd1);

   gf: glitchfilter
   GENERIC MAP(RSTDEF => RSTDEF,
               INIVAL => INIVAL)
   PORT MAP(rst   => rst,
            clk   => clk,
            swrst => swrst,
            ena   => '1',
            din   => rxd1,
            dout  => rxd2);

   bg: baudgen
   GENERIC MAP(RSTDEF => RSTDEF,
               BAUDEF => BAUDEF,
               FRQDEF => FRQDEF)
   PORT MAP(rst   => rst,
            clk   => clk,
            swrst => swrst,
            ena   => ena,
            strb  => strb);

   re: receiver
   GENERIC MAP(RSTDEF => RSTDEF,
               LENDEF => LENDEF)
   PORT MAP(rst   => rst,
            clk   => clk,
            swrst => swrst,
            strb  => strb,
            rxd   => rxd2,
            dout  => dout,
            rden  => rden,
            rhrf  => rhrf,
            ovre  => ovre,
            frme  => frme);

   tr: transmitter
   GENERIC MAP(RSTDEF => RSTDEF,
               LENDEF => LENDEF)
   PORT MAP(rst   => rst,
            clk   => clk,
            swrst => swrst,
            strb  => strb,
            din   => din,
            wren  => wren,
            txd   => txd,
            tsre  => tsre,
            thre  => thre);

END structure;