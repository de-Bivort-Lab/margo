function out = nanFilteredMedian(x, varargin)
%NANFILTEREDMEAN Summary of this function goes here
%   Detailed explanation goes here

FUNCTION_ID = string('NANFILTEREDMEDIAN');
out = NanFilteredStatistic('median', FUNCTION_ID, x, varargin{:}).apply();

end

