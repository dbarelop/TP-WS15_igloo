library ieee;
use ieee.std_logic_1164.all;

--leere Entity
ENTITY AD7782_tb IS
	-- empty
END ENTITY AD7782_tb;

ARCHITECTURE verhalten OF AD7782_tb IS

	CONSTANT RSTDEF	: std_logic := '0';
	CONSTANT FRQDEF	: natural	:= 1e6;
	CONSTANT tcyc		: time		:= 1 sec / FRQDEF;

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
   signal ain1    : real := 0.0;
   signal ain2    : real := 0.0;
   signal rng     : std_logic := '0';        -- Range (0=160mV) | (1=2,56mV) 
   signal sel     : std_logic := '0';        -- Channel Select: AIN1 (=0) AIN2 (=1)
   signal mode    : std_logic := '0';        -- (0)master / (1)Slave Mode
   signal sclk    : std_logic := '0';
   signal cs      : std_logic := '1';

   TYPE tstate IS (S0, S1);
   signal state	: tstate := S0;

   signal clk 		: std_logic;
	--output Stimuli-signale
	signal dout 	: std_logic := '0';

	BEGIN
	--Anfang des Tests

	--Dauerhaft zugeordnete Signale
	clk 		<= not clk after 100 ns; -- 5KHz Taktfrequenz
   ain1 		<= 2.49;
   ain2 		<= 3.01;

	--Modulinstanzierung mittels "port map"
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
		--<Komponenten-port> => <Stimulie-Signal>,
		--...);
	
	stimuli : PROCESS (clk) IS
	BEGIN
		--<Stimulie-Signal> <= '<Wert>';
		--wait for x ns;
		--assert anweisung
		IF (state = S0) THEN
			-- Initial state S0
			rng 	<= '1';
			sel 	<= '0';
			mode 	<= '0';
			sclk	<= '1';
			cs 	<= '1';

			state <= S1;
		ELSIF (state = S1) THEN
			-- Working state S1

			cs 	<= '0';
			--wait until falling_edge(dout);


		END IF;
   END PROCESS;
END verhalten;