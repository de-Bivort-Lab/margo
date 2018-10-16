function [trackDat, expmt, props] = multiTrack(props, trackDat, expmt)

% props = erodeDoubleBlobs(props, trackDat);
%                 
% % apply area threshold before assigning centroids
% above_min = cat(1,props.Area) .* (expmt.parameters.mm_per_pix^2) > ...
%     expmt.parameters.area_min;
% props(~above_min,:) = [];

% assign each blob in props to an ROI
raw_cen = cat(1,props.Centroid);
ROI_num = assignROI(raw_cen, expmt);
ROI_num = cat(1,ROI_num{:});

% initialize blob index placeholder
blob_num = 1:size(raw_cen,1);

% sort blob features and blob indices into cells for each ROI
candidate_ROI_cen = arrayfun(@(x) ...
    raw_cen(ROI_num==x,:), 1:expmt.meta.roi.n, 'UniformOutput',false)';
blob_num = arrayfun(@(x) ...
    blob_num(ROI_num==x), 1:expmt.meta.roi.n, 'UniformOutput',false)';
trackDat.permutation = cell(expmt.meta.roi.n,1);

% track each ROI sequentially
for i=1:expmt.meta.roi.n
    
    % sort blob identities by last known positions for live traces
    [blob_assigned, blob_permutation] = ...
        sortROI_multitrack(trackDat.traces(i), candidate_ROI_cen{i}, ...
            trackDat.t, expmt.parameters.speed_thresh);

    % update lifespan of each trace
    updateDuration(trackDat.traces(i));

    % sort blob indices by the local (within ROI) permutation vector
    trackDat.permutation{i} = blob_num{i}(blob_permutation);

    % track any leftover blobs and add to list of candidate traces
    unassigned_blobs = candidate_ROI_cen{i}(~blob_assigned,:);
    [blob_assigned, ~] = ...
        sortROI_multitrack(trackDat.candidates(i), unassigned_blobs, ...
            trackDat.t, expmt.parameters.speed_thresh);

    % update lifespan of candidate traces
    updateDuration(trackDat.candidates(i));

    % identify candidates that have existed long enough to birth new traces
    new_cen = getNewTraces(unassigned_blobs, ...
        trackDat.candidates(i), blob_assigned, trackDat.t);

    % resurrect any dead traces with new candidates if available
    reviveTrace(trackDat.traces(i), new_cen, trackDat.t);

end   
