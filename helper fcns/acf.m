function ta = acf(y,p)
% ACF - Compute Autocorrelations Through p Lags
% >> myacf = acf(y,p) 
%
% Inputs:
% y - series to compute acf for, nx1 column vector
% p - total number of lags, 1x1 integer
%
% Output:
% myacf - px1 vector containing autocorrelations
%        (First lag computed is lag 1. Lag 0 not computed)
%
%
% A bar graph of the autocorrelations is also produced, with
% rejection region bands for testing individual autocorrelations = 0.
%
% Note that lag 0 autocorelation is not computed, 
% and is not shown on this graph.
%
% Example:
% >> acf(randn(100,1), 10)
%


% --------------------------
% USER INPUT CHECKS
% --------------------------

[n1, n2] = size(y) ;
if n2 ~=1
    error('Input series y must be an nx1 column vector')
end

[a1, a2] = size(p) ;
if ~((a1==1 && a2==1) && (p<n1))
    error(['Input number of lags p must be a 1x1 scalar,'...
        'and must be less than length of series y']);
end



% -------------
% BEGIN CODE
% -------------

ta = zeros(p,1);
N = max(size(y));
ybar = mean(y); 

% Collect ACFs at each lag i
for i = 1:p 
    cross_sum=(y(i+1:N)-ybar)'*(y(1:N-i)-ybar); 
    yvar = (y-ybar)'*(y-ybar) ; 
    ta(i) = (cross_sum / yvar)*(N/(N-i)) ; 
end



