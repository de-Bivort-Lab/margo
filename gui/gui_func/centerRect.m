function [rect_bounds] = centerRect(centroids,radii)
    rect_bounds = [centroids(:,1)-radii centroids(:,2)-radii repmat(radii*2,size(centroids,1),2)];
end