function hex_out = main( AIN, GAIN)
    a_in = AIN;
    % gain =  1 when range 2.56V
    % gain = 16 when range 0.16V
    gain = GAIN;

    Vref = 2.5;
    N = 24;

    code = adcCodeGeneration(N, a_in, gain, Vref);
    code_output = floor(code);
    bin_oi = decimalToBinaryVector(code_output, N);
    hex_out = binaryVectorToHex(bin_oi);

    code_input = binaryVectorToDecimal(bin_oi);
    ain = adcAINGeneration(N, code_input, gain, Vref);

    %Funktioniert so mit jedem input wert!
end