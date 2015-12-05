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
		ASSERT (din = X"FC8000") report "fail on read AIN1" severity error;

		-- T02
		WAIT FOR 200 ns;
   	ain2 		<= 3.01;
		rng 	<= '1';	--2.56V
		sel 	<= '1';	--ch2(ain2)
		din 	<= (OTHERS => '0');

		WAIT FOR 50 ns;
		getAD_velue(din, setsclk, cs, cs, dout);
		WAIT FOR 10 ns;
		ASSERT (din = X"FFFFFF") report "fail on read AIN2" severity error;

		WAIT FOR 1 sec;

	END PROCESS;

		

END verhalten;