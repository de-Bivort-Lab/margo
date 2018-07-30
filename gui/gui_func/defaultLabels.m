function labels = defaultLabels(expmt)

labels = cell(5,11);
labels(:,1:8) = {''};
labels(:,9:11) = {zeros(1,0)};
labels(1,4) = {1};
labels(1,5) = {size(expmt.meta.roi.centers,1)};
labels(1,6) = {1};
labels(1,7) = {size(expmt.meta.roi.centers,1)};
labels(1,8) = {1};