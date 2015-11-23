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
   signal ain1    : real := 0.0;
   signal ain2    : real := 0.0;
   signal rng     : std_logic := '1';        -- Range (0=160mV) | (1=2,56mV) 
   signal sel     : std_logic := '0';        -- Channel Select: AIN1 (=0) AIN2 (=1)
   signal mode    : std_logic := '0';        -- (0)master / (1)Slave Mode
   signal sclk    : std_logic := '1';
   signal cs      : std_logic := '1';

   signal clk		: std_logic := '0';
   signal rst 		: std_logic;

	--output Stimuli-signale
	signal dout 	: std_logic := '0';

	--Types
	TYPE tstate IS (S0, S1, S2, S3);
	signal statesysclk	: tstate;
	signal state	: tstate;

	--Tests
	signal setsclk	: std_logic := '1';
	signal din 		: std_logic_vector(N-1 downto 0) := (OTHERS => '0');
	signal cnt 		: integer range 0 to N;


	BEGIN
	--Anfang des Tests

	--Dauerhaft zugeordnete Signale
	clk 		<= not clk after 100 ns; -- 5KHz Taktfrequenz
	rst 		<= '1', '0' after 100 ns; -- generate Reset signal
	sclk 		<= not sclk after 100 ns when setsclk='0'; -- setst den System clock sobald er gesetzt werden soll (leider ist die erste Tacktflanke dann noch 100ns entfernt)
	
   ain1 		<= 2.49;
   ain2 		<= 3.01;

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

	sysclkgenerate : PROCESS
	BEGIN
	wait for 50 ns;
		if cs='1' then
			statesysclk <= S0;
			cnt 			<= 0;
			cs 			<= '0';
		elsif cs='0' then
			--evt sclk genernieren
			case statesysclk is
				when S0 =>
					wait until dout = '1';
					wait until falling_edge(dout);
					wait for 15260 ns;
					setsclk <= '0';
					statesysclk <= S1;
					wait until falling_edge(sclk);

				when S1 =>
					if cnt/=N then
						wait until falling_edge(sclk);
						cnt <= cnt + 1;
					else
						wait for 400 ns;							-- nach kurzem warten, alles wieder auf anfang stellen.
						statesysclk <= S0;
						cnt <= 0;
						setsclk <= '1';
						cs <= '1';						
						wait for 1 ms;
					end if ;
				when others =>
					statesysclk <= S0;
			end case ;
		else
		end if ;
	END PROCESS;

		

END verhalten;