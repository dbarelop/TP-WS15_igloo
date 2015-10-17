-- Testbench fuer Mini DDS
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
-- leere entity
entity mini_dds_tb is
end entity mini_dds_tb;
 
architecture bhv of mini_dds_tb is
 
  -- Moduldeklaration
  component mini_dds is
    port (
      clk   : in std_logic;
      reset : in std_logic;
 
      sinus     : out std_logic_vector(3 downto 0);
      saegezahn : out std_logic_vector(3 downto 0);
      rechteck  : out std_logic_vector(3 downto 0)
    );
  end component;
 
  -- input
  signal clk   : std_logic := '0';
  signal reset : std_logic;
 
  -- output
  signal sinus, saegezahn, rechteck : std_logic_vector(3 downto 0);
 
begin
  clk   <= not clk  after 20 ns;  -- 25 MHz Taktfrequenz
  reset <= '1', '0' after 100 ns; -- erzeugt Resetsignal: --__
 
  -- Modulinstatziierung
  dut : mini_dds
    port map (
      clk       => clk,
      reset     => reset,
 
      sinus     => sinus,
      saegezahn => saegezahn,
      rechteck  => rechteck
      );
 
end architecture;