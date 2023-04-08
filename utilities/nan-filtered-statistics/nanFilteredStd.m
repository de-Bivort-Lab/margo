function out = nanFilteredStd(x, varargin)
%NANFILTEREDMEAN Summary of this function goes here
%   Detailed explanation goes here

FUNCTION_ID = string('NANFILTEREDSTDDEV');
out = NanFilteredStatistic(string('std'), FUNCTION_ID, x, varargin{:}).apply();

end

