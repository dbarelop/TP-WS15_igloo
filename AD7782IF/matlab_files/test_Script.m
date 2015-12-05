
code = adcCodeGeneration(24, 0.0, 16.0, 2.5);
code_output = floor(code);
bin_oi = decimalToBinaryVector(code_output, 24);
hex_out = binaryVectorToHex(bin_oi);

code_input = binaryVectorToDecimal(bin_oi);
ain = adcAINGeneration(24, code_input, 16.0, 2.5);

%Funktioniert so mit jedem input wert!