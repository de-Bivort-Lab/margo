function [area_samples, length_samples] = ...
    sampleAreaDist(vidobj,ref_im,area_bounds,im_thresh,sample_sz)

num_frames = vidobj.NumberOfFrames;
sample_idx= randperm(num_frames,sample_sz);
sample_frames =  arrayfun(@(x) read(vidobj,x), ...
                        sample_idx, 'UniformOutput',false);
                    
diff_ims = cellfun(@(x) x-ref_im, sample_frames, ...
                    'UniformOutput', false);
thresh_ims = cellfun(@(x) x>im_thresh, diff_ims, 'UniformOutput', false);
props = cellfun(@(x) regionprops(x,'Area', 'MajorAxisLength'), ...
                thresh_ims, 'UniformOutput', false);
            
% apply area threshold before assigning centroids
in_bounds = cellfun(@(x) [cat(1,x.Area) < area_bounds(2) & ...
                    cat(1,x.Area) > area_bounds(1)], ...
                    props, 'UniformOutput', false);
filtered_props = cellfun(@(x,y) x(y), props, in_bounds, ...
                        'UniformOutput', false);
                    
% convert to array
area_samples = arrayfun(@(x) cat(1,x), cell2struct(filtered_props, ...
                       'Area',1), 'UniformOutput', false);
filtered_props = cat(1,filtered_props{:});
area_samples = cat(1,filtered_props.Area);
length_samples = cat(1,filtered_props.MajorAxisLength);
                
                