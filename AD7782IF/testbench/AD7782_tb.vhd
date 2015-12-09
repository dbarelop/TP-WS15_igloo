library ieee;
use ieee.std_logic_1164.all;

--leere Entity
ENTITY AD7782_tb IS
	-- empty
END ENTITY AD7782_tb;

ARCHITECTURE verhalten OF AD7782_tb IS

	CONSTANT RSTDEF	: std_logic := '0';
	CONSTANT FRQDEF	: natural	:= 1e6;
	CONSTANT	PLLFRQ	: real		:= 4.194304e6;
	CONSTANT tcyc		: time		:= 1 sec / PLLFRQ;
	CONSTANT N 			: natural	:= 24;

	--Moduldeklaration
	COMPONENT AD7782
		--Komponentenbeschreibung
		GENERIC(ref: real := 2.5);
      PORT(
         ain1: IN  real;      -- analog input: +/- Ref
         ain2: IN  real;        -- analog input: +/- Ref
         rng:  IN  std_logic;   -- logic input which configures the input range on the internal PGA
         sel:  IN  std_logic;   -- logic input which selects the active channel AIN1 oo ANI2
         mode: IN  std_logic;   -- logic input which selects master (=0) or slave (=1) mode of operation
         sclk: IN  std_logic;   -- serial clock output
         cs:   IN  std_logic;   -- chip select, low active
         dout: OUT std_logic);  -- serial data output
	END COMPONENT;

	--input Stimuli-signale definieren
   SIGNAL ain1    : real := 0.0;
   SIGNAL ain2    : real := 0.0;
   SIGNAL rng     : std_logic := '1';        -- Range (0=160mV) | (1=2,56mV) 
   SIGNAL sel     : std_logic := '0';        -- Channel Select: AIN1 (=0) AIN2 (=1)
   SIGNAL mode    : std_logic := '0';        -- (0)master / (1)Slave Mode
   SIGNAL sclk    : std_logic := '1';
   SIGNAL cs      : std_logic := '1';

   SIGNAL clk		: std_logic := '0';
   SIGNAL rst 		: std_logic;

	--output Stimuli-SIGNALe
	SIGNAL dout 	: std_logic := '0';

	--Types
	TYPE tstate IS (S0, S1, S2, S3);
	SIGNAL statesysclk	: tstate;
	SIGNAL state	: tstate;

	--Tests
	SIGNAL setsclk	: std_logic := '1';
	SIGNAL din 		: std_logic_vector(N-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL cnt 		: integer range 0 to N;


	PROCEDURE getAD_velue (
		SIGNAL pout 	: OUT std_logic_vector(23 DOWNTO 0);
		SIGNAL setsclk : OUT std_logic;
		SIGNAL cso 		: OUT std_logic;
		SIGNAL csi 		: IN std_logic;
		SIGNAL dout		: IN std_logic) is

	BEGIN

		cso 	<= '0';
		WAIT UNTIL csi = '0';

		WAIT UNTIL dout = '1';
		WAIT UNTIL falling_edge(dout);
		--WAIT FOR 15260 ns;						-- minimale convertierungs zeit

		setsclk <= '0';
		WAIT UNTIL falling_edge(sclk);		-- erstes Datenbit kommt jetzt auf dout, ist bei der nechsten rising edge verfügbar!

		FOR I in 23 DOWNTO 0 LOOP
			--Hier Daten einlesen.
			WAIT UNTIL rising_edge(sclk);		-- Daten werden immer an der falling Edge geschrieben und liegen an rising Edge stabiel an!
			--Jetzt liegen Daten stabiel an!
			pout(I)	<= dout;
		END LOOP;

		-- Daten wurden eingelesen, Jetzt alles zurück setzten.
		cso 		<= '1';
		setsclk 	<= '1';

	END getAD_velue;


	BEGIN
	--Anfang des Tests

	--Dauerhaft zugeordnete SIGNALE
	clk 		<= not clk after 100 ns; -- 5KHz Taktfrequenz
	rst 		<= '1', '0' after 100 ns; -- generate Reset signal
	sclk 		<= not sclk after 100 ns when setsclk='0'; -- setst den System clock sobald er gesetzt werden soll (leider ist die erste Tacktflanke dann noch 100ns entfernt)
	

	-- Modulinstanzierung mittels "port map"
	-- <Komponenten-port> => <Stimulie-Signal>,
		-- ...);
	adc : AD7782 PORT MAP(
      ain1  => ain1,
      ain2  => ain2,
      rng   => rng,
      sel   => sel,
      mode  => mode,
      sclk  => sclk,
      cs    => cs,
      dout  => dout
      );

	test : PROCESS
	BEGIN
   	ain1 		<= 2.49;
   	ain2 		<= 3.01;

		-- T01
		WAIT FOR 200 ns;
   	ain1 		<= 2.49;
		rng 	<= '1';	--2.56V
		sel 	<= '0';	--ch1(ain1)

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		ASSERT (din = X"FC8000") report "fail on read 2.49V" severity error;

		-- T02
		WAIT FOR 200 ns;
   	ain2 		<= 3.01;
		rng 	<= '1';	--2.56V
		sel 	<= '1';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"FFFFFF") report "fail on read 3.01" severity error;

		-- T03
		WAIT FOR 200 ns;
		ain1 		<= -0.1;
		rng 	<= '1';	--2.56V
		sel 	<= '0';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"7B0000") report "fail on read -0.1V" severity error;

		-- T04
		WAIT FOR 200 ns;
		ain1 		<= -1.49;
		rng 	<= '1';	--2.56V
		sel 	<= '0';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"358000") report "fail on read -1.4V" severity error;

		-- T05
		WAIT FOR 200 ns;
		ain1 		<= -2.0;
		rng 	<= '1';	--2.56V
		sel 	<= '0';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"1C0000") report "fail on read -2.0V" severity error;

		-- T06
		WAIT FOR 200 ns;
		ain1 		<= -2.4;
		rng 	<= '1';	--2.56V
		sel 	<= '0';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"080000") report "fail on read -2.4V" severity error;

		-- T07
		WAIT FOR 200 ns;
		ain1 		<= -2.485;
		rng 	<= '1';	--2.56V
		sel 	<= '0';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"03C000") report "fail on read -2.48V" severity error;

		-- T09
		WAIT FOR 200 ns;
		ain1 		<= -2.495;
		rng 	<= '1';	--2.56V
		sel 	<= '0';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"034000") report "fail on read -2.495V" severity error;

		-- T10
		WAIT FOR 200 ns;
		ain1 		<= -2.5;
		rng 	<= '1';	--2.56V
		sel 	<= '0';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"030000") report "fail on read -2.5V" severity error;

		-- T11
		WAIT FOR 200 ns;
		ain1 		<= -2.56;
		rng 	<= '1';	--2.56V
		sel 	<= '0';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"000000") report "fail on read -2.56V" severity error;

		-- T12
		WAIT FOR 200 ns;
		ain1 		<= -3.01;
		rng 	<= '1';	--2.56V
		sel 	<= '0';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"000000") report "fail on read -3.01V" severity error;


		--RangeTests
		--TR01
		WAIT FOR 200 ns;
		ain1 		<= 0.17;
		rng 	<= '0';	--160mV
		sel 	<= '0';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"FFFFFF") report "fail on read 0.17V on 160mV Range" severity error;

		--TR02
		WAIT FOR 200 ns;
		ain1 		<= 0.16;
		rng 	<= '0';	--160mV
		sel 	<= '0';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"FFFFFF") report "fail on read 0.16V on 160mV Range" severity error;

		--TR02
		WAIT FOR 200 ns;
		ain1 		<= 0.15;
		rng 	<= '0';	--160mV
		sel 	<= '0';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"F80000") report "fail on read 0.15V on 160mV Range" severity error;

		--TR02
		WAIT FOR 200 ns;
		ain1 		<= 0.1;
		rng 	<= '0';	--160mV
		sel 	<= '0';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"D00000") report "fail on read 0.1V on 160mV Range" severity error;

		--TR03
		WAIT FOR 200 ns;
		ain1 		<= 0.05;
		rng 	<= '0';	--160mV
		sel 	<= '0';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"A80000") report "fail on read 0.05V on 160mV Range" severity error;

		--TR04
		WAIT FOR 200 ns;
		ain1 		<= 0.0;
		rng 	<= '0';	--160mV
		sel 	<= '0';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"800000") report "fail on read 0.0V on 160mV Range" severity error;

		--TR02
		WAIT FOR 200 ns;
		ain1 		<= -0.05;
		rng 	<= '0';	--160mV
		sel 	<= '0';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"580000") report "fail on read -0.05V on 160mV Range" severity error;

		--TR02
		WAIT FOR 200 ns;
		ain1 		<= -0.1;
		rng 	<= '0';	--160mV
		sel 	<= '0';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"300000") report "fail on read -0.1V on 160mV Range" severity error;

		--TR02
		WAIT FOR 200 ns;
		ain1 		<= -0.15;
		rng 	<= '0';	--160mV
		sel 	<= '0';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"080000") report "fail on read -0.15V on 160mV Range" severity error;

		--TR02
		WAIT FOR 200 ns;
		ain1 		<= -0.16;
		rng 	<= '0';	--160mV
		sel 	<= '0';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"000000") report "fail on read -0.16V on 160mV Range" severity error;

		--TR02
		WAIT FOR 200 ns;
		ain1 		<= -0.17;
		rng 	<= '0';	--160mV
		sel 	<= '0';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"000000") report "fail on read -0.17V on 160mV Range" severity error;

		



		WAIT FOR 1 sec;
	END PROCESS;

		

END verhalten;