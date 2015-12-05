function [ ain ] = adcAINGeneration(dec_code, N, gain, VReff)
%adcAINGeneration Summary of this function goes here
%   Detailed explanation goes here
    v = 1.024 * VReff;
    a = 2^(N-1);

    ain = (v*((dec_code/a)-1))/gain;
end

