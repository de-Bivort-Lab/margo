function out = nanFilteredStd(x, varargin)
%NANFILTEREDMEAN Summary of this function goes here
%   Detailed explanation goes here

FUNCTION_ID = "NANFILTEREDSTDDEV";
out = NanFilteredStatistic("std", FUNCTION_ID, x, varargin{:}).apply();

end

