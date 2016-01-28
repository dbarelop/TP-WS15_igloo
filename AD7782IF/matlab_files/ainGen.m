function ain = ainGen(hex_in, gain)
    dec_in = hex2dec(hex_in);
    v = 1.024 * 2.5;
    a = 2^(24-1);

    ain = (v*((dec_in/a)-1))/gain;
end