-- Testbench fuer D-FF
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
-- leere entity
entity d_ff_tb is
end entity d_ff_tb;
 
architecture bhv of d_ff_tb is
 
	component d_ff is
		port(
			d : in std_logic;
			c : in std_logic;

			q : out std_logic;
			q_n: out std_logic
		);
	end component;

	-- input
	signal d_tb : std_logic := '0';
	signal c_tb : std_logic := '0';

	-- output
	signal q_tb : std_logic;
	signal q_n_tb : std_logic;

	begin
		d_tb <= not d_tb after 20 ns;
		c_tb <= not c_tb after 10 ns;

		DUT: d_ff
			port map(
				d => d_tb,
				c => c_tb,

				q => q_tb,
				q_n => q_n_tb
				);
 
end architecture;