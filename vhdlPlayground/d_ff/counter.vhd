--
-- D-FF zum Demonstrieren der Testbench
--
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity d_ff is
		port(
			d : in std_logic;
			c : in std_logic;

			q : out std_logic;
			q_n: out std_logic
		);
end d_ff;
 
architecture bhv of d_ff is

	begin
	step: process(d, c)
	begin
		if c = '1' then
			q <= d;
			q_n <= not d;
		end if;
	end process;
 
end bhv;
