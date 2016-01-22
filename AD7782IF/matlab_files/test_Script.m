N = 24;
a_in = 0.85;
gain = 1;
Vref = 2.5;

code = adcCodeGeneration(N, a_in, gain, Vref);
code_output = floor(code);
bin_oi = decimalToBinaryVector(code_output, N);
hex_out = binaryVectorToHex(bin_oi);

code_input = binaryVectorToDecimal(bin_oi);
ain = adcAINGeneration(N, code_input, gain, Vref);

%Funktioniert so mit jedem input wert!