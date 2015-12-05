function code = adcCodeGeneration( N, AIN, GAIN, VReff)
%adcCodeGeneration Summary of this function goes here
%   Detailed explanation goes here

    code = (2^(N-1) * ((AIN * GAIN/(1.024 * VReff)) + 1));
end

