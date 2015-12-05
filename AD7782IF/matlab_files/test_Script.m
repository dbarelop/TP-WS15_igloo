
code = adcCodeGeneration(24, 0.49, 1, 2.5);
code_output = floor(code);
bin_out = decimalToBinaryVector(code_output, 24);
hex_out = binaryVectorToHex(bin_out);

code_input = binaryVectorToDecimal(bin_out);
ain = adcAINGeneration(code_input, 24, 1, 2.5);

%Funktioniert so mit jedem input wert!