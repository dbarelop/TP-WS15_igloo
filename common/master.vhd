process (busy, clk)
	IF rising_edge(busy) THEN
		cnt <= (others => '0');	
	ELSIF busy = '1' AND rising_edge(clk) THEN
		busy <= '0';
		swrst <= '1';