--
-- D-FF zum Demonstrieren der Testbench
--
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity simple_spi is

		
		port(
			clk : in std_logic;
			mosi : in std_logic;

			tmp: buffer std_logic_vector(7 downto 0);

			miso : out std_logic
		);
end simple_spi;
 
architecture bhv of simple_spi is


	begin
	step: process(clk)
	begin
		if rising_edge(clk) then
			for i in 0 to 6 loop
				tmp(i+1) <= tmp(i);
			end loop;
			tmp(0) <= mosi;
		end if;
	end process;
 
end bhv;
