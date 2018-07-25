function sub_ims = getSubImage(sub_coords, im, shift, erodel)

% define bounds, prevent out-of-bounds situations in sub-images
im_bounds = zeros(1,4);
im_bounds = cellfun(@(x) [ceil(min(x,[],1) - shift)...
                    ceil(max(x,[],1) + shift)],...
                    sub_coords, 'UniformOutput', false);
bounds_limit = [1 1 size(im,2) size(im,1)];

out_of_bounds = cellfun(@(x) [x(1:2)<bounds_limit(1:2)...
                    x(3:4)>bounds_limit(3:4)], ...
                    im_bounds, 'UniformOutput', false);
                
out_of_bounds = cat(1,out_of_bounds{:}); 
im_bounds = cat(1,im_bounds{:});
bounds_limit = repmat(bounds_limit,numel(sub_coords),1);
im_bounds(out_of_bounds) = bounds_limit(out_of_bounds);

sub_ims = cellfun(@(i) im(i(2):i(4),i(1):i(3)), num2cell(im_bounds,2),...
                  'UniformOutput', false);
                            
erode_ims = cellfun(@(x) imerode(x, erodel), sub_ims, ...
                    'UniformOutput', false);
