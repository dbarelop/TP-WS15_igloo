
library ieee;
use ieee.std_logic_1164.all;

entity tb is
end;
architecture sim of tb is
    signal clk: std_logic := '0';

begin
CLOCK:
clk <=  not clk after 25 ns;
end;