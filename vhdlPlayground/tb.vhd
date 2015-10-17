
library ieee;
use ieee.std_logic_1164.all;

entity tb is
end;
architecture sim of tb is
    signal clk: std_logic := '0';

begin
CLOCK:
clk <=  '1' after 25 ns when clk = '0' else
        '0' after 25 ns when clk = '1';
end;