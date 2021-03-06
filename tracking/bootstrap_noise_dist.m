function [pix_dist, roi_dist] = bootstrap_noise_dist(pix_dist, roi_dist, update_ct)
% Updates the pixel distribution by the estimated number of objects in each
% ROI. In principle, this helps produce a corrected estimate of the pixel noise
% during the sampling period if some ROIs are empty.

% find under sampled ROIs
n_frames = size(pix_dist,1);
under_sampled = update_ct < n_frames*.1;

if sum(~under_sampled)<1
   warning('No ROIs sampled during noise sampling. Unable to resample noise distribution');
   return
end

% restrict bootstrap pool to well-sampled ROIs
if size(roi_dist,2) == numel(under_sampled)
    sampling_dist = roi_dist(:,~under_sampled);

    % generate random ROI numbers for each frame to sample from dist
    rand_ids = randi(sum(~under_sampled),[n_frames sum(under_sampled)]);
    frame_idx = (1:n_frames)'*ones(1,sum(under_sampled));
    lin_idx = sub2ind(size(sampling_dist),frame_idx,rand_ids);
    added_noise = sampling_dist(lin_idx);

    % update total and ROI distributions
    roi_dist(:,under_sampled) = added_noise;
    pix_dist = pix_dist + sum(added_noise,2);
end
