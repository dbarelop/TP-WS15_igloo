-- Testbench fuer simple spi shift register
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
-- leere entity
entity simple_spi_tb is
end entity simple_spi_tb;
 
architecture bhv of simple_spi_tb is
 
	component simple_spi is
		port(
			clk : in std_logic;
			mosi : in std_logic;

			tmp: buffer std_logic_vector(7 downto 0);

			miso : out std_logic
		);
	end component;

	-- input
	signal clk_tb : std_logic := '0';
	signal mosi_tb : std_logic := '0';

	-- debug
	signal buffer_tb: std_logic_vector(7 downto 0);

	-- output
	signal miso_tb : std_logic;

	begin
		mosi_tb <= not mosi_tb after 10 ns;
		clk_tb <= not clk_tb after 7 ns;

		DUT: simple_spi
			port map(
				mosi => mosi_tb,
				clk => clk_tb,

				tmp => buffer_tb,

				miso => miso_tb
				);
 
end architecture;