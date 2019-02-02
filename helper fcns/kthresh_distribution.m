function [thresh, class_means] = kthresh_distribution(data)

% exclude NaN and inf values
data(isnan(data)) = [];
data(isinf(data)) = [];

% perform k-means clustering
if numel(data)>2
    [idx,class_means] = kmeans(data,2);
    idx = [min(data(idx==1)) max(data(idx==1)) min(data(idx==2)) max(data(idx==2))];
    class_boundaries = sort(idx);
    class_means = sort(class_means);
    thresh = mean(class_boundaries(2:3));
else
    thresh = [];
    class_means = [];
end
