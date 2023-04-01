function out = nanFilteredMean(x, varargin)
%NANFILTEREDMEAN Summary of this function goes here
%   Detailed explanation goes here

FUNCTION_ID = "NANFILTEREDMEAN";
out = NanFilteredStatistic(@mean, FUNCTION_ID, x, varargin{:}).apply();

end

