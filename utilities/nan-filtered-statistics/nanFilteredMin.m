function out = nanFilteredMin(x, varargin)
%NANFILTEREDMEAN Summary of this function goes here
%   Detailed explanation goes here

FUNCTION_ID = "NANFILTEREDMIN";
out = NanFilteredStatistic("min", FUNCTION_ID, x, varargin{:}).apply();

end

