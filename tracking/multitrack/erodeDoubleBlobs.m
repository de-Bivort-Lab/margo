function [new_props] = erodeDoubleBlobs(props, trackDat)

areas = cat(1,props.Area);
abv_areas = areas > trackDat.ref.thresh^2*.6;
dbl_blobs = props(abv_areas);
props(abv_areas) = [];

% create blank image, blob image from PixelList
coord_idx = arrayfun(@(x) x.PixelList, dbl_blobs, 'UniformOutput', false);
bounds_min = arrayfun(@(x) min(x.PixelList), dbl_blobs, ...
                  'UniformOutput', false);
bounds_max = arrayfun(@(x) max(x.PixelList), dbl_blobs, ...
                     'UniformOutput', false);
im_bounds = cellfun(@(x,y) [x(:) y(:)], bounds_min, bounds_max, ...
                    'UniformOutput', false);
blank_im = cellfun(@(x,y) false(x-y+1), bounds_max, bounds_min, ...
                   'UniformOutput', false);

% shift coordinates, convert to linear indices
shift_coords = cellfun(@(a,b) [a(:,1)-b(1)+1 a(:,2)-b(2)+1], ...
                       coord_idx, bounds_min, 'UniformOutput', false);
lin_idx = cellfun(@(x,im) sub2ind(size(im),x(:,1),x(:,2)), shift_coords,...
                  blank_im, 'UniformOutput', false);
blob_im = cellfun(@(x,y) drawBlob(x,y), lin_idx, blank_im, ...
                  'UniformOutput', false);

              
erodel = arrayfun(@(x) strel('disk',ceil(sqrt(x.Area)*0.07),0), dbl_blobs, ...
                  'UniformOutput', false);
erode_im = cellfun(@(x,y) imerode(x, y), blob_im, erodel, ...
                   'UniformOutput', false);
               
new_props = cellfun(@(x) regionprops(x, trackDat.in_fields),...
                    erode_im, 'UniformOutput', false);
                
% delete new_props elements with no blobs
no_blobs = cellfun(@isempty,new_props);
new_props(no_blobs) = [];
bounds_min(no_blobs) = [];
raw_cen = [];
raw_area = [];

if ~isempty(new_props)
    raw_cen = cellfun(@(x) cat(1,x.Centroid), ...
                      new_props, 'UniformOutput', false);
    raw_cen = cellfun(@(x,y)[x(1)+y(:,1)-1 x(2)+y(:,2)-1], bounds_min, ...
                      raw_cen, 'UniformOutput', false);
    new_props = cat(1, new_props{:});
    raw_cen = cat(1, raw_cen{:});
    new_props = arrayfun(@updateProps,new_props,num2cell(raw_cen,2));
end

new_props = cat(1, props, new_props);
                 
function blob_im = drawBlob(lin_idx, blob_im)
blob_im(lin_idx) = true;

function props = updateProps(props, cen)

props.Centroid = cen{:};