function [rect_bounds] = centerRect(centroids,radii)
    rect_bounds = [centroids(:,1)-radii centroids(:,2)-radii radii*2 radii*2];
end