function [varargout] = fitBimodalHist(data)

% get bimodal gaussian fit
data = data(~isnan(data));
opt.MaxIter = 1000;
intersections = NaN;
gmm.mu = [NaN;NaN];
gmm.Sigma = [NaN;NaN];

if length(data) > opt.MaxIter
    
    gmm = fitgmdist(data,2,'Options',opt);

    intersections = gaussIntersect(gmm.mu(1),gmm.mu(2),gmm.Sigma(1),gmm.Sigma(1));

    if gmm.mu(1)<gmm.mu(2)
        intersections(intersections<gmm.mu(1)|intersections>gmm.mu(2))=[];
    else
        intersections(intersections<gmm.mu(2)|intersections>gmm.mu(1))=[];
    end

end

for i=1:nargout
    switch i
        case 1, varargout(i) = {intersections};
        case 2, varargout(i) = {gmm.mu};
        case 3, varargout(i) = {gmm.Sigma(:)};
    end
end

function ints = gaussIntersect(u1,u2,s1,s2)

  a = 1/(2*s1^2) - 1/(2*s2^2);
  b = u2/(s2^2) - u1/(s1^2);
  c = u1^2 /(2*s1^2) - u2^2 / (2*s2^2) - log(s2/s1);
  ints = roots([a b c]);