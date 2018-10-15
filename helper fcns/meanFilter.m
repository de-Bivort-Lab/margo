function x_filtered = meanFilter(x, window_sz)
% smooth data (x) with sliding mean filter

N = numel(x);
if N > length(x)
    error('x must be one dimensional');
end

idx = bsxfun(@(a,b) a+b, (1:N)',0-window_sz/2:window_sz/2-1);
x_filtered = cellfun(@(i) mean(x(i>0 & i<N)), num2cell(idx,2));