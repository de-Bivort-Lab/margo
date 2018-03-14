function logvec = simple_logspace(a,b,n)

% This is a simplified version of logspace that outputs n logarithmically
% spaced numbers from 1:b, rather than n logarithmically spaced numbers
% from 10^a:10^b.


shift = a-1;

alog = 0;
blog = log(b-shift)/log(10);
logvec = logspace(alog,blog,n) + shift;
