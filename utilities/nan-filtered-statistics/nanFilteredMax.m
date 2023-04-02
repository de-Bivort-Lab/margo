function out = nanFilteredMax(x, varargin)
%NANFILTEREDMEAN Summary of this function goes here
%   Detailed explanation goes here

FUNCTION_ID = "NANFILTEREDMAX";
out = NanFilteredStatistic(@max, FUNCTION_ID, x, varargin{:}).apply();

end

