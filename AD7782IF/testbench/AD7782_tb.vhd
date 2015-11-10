library ieee;
use ieee.std_logic_1164.all;

--leere Entity
ENTITY ad7782_tb IS
	-- empty
END ENTITY ad7782_tb;

ARCHITECTURE verhalten OF ad7782_tb IS

	--Moduldeklaration
	COMPONENT ad7782 IS
		--Komponentenbeschreibung
		PORT (
			--Portbeschreibung

			);
	END COMPONENT;

	--input Stimuli-signale definieren
	signal clk		: std_logic := '0';

	--output Stimuli-signale
	signal data 	: std_logic_vector(15 downto 0);

	BEGIN
	--Anfang des Tests

	clk 	<= not clk after 100 ns; -- 5KHz Taktfrequenz

	--Modulinstanzierung mittels "port map"
	--port map ( 
		--<Komponenten-port> => <Stimulie-Signal>,
		--...);
	
	stimuli : PROCESS (clk)
	BEGIN
		--<Stimulie-Signal> <= '<Wert>';
		--wait for x ns;
		--


END ARCHITECTURE;
