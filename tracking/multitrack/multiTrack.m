function [trackDat, expmt, props] = multiTrack(props, trackDat, expmt)


props = erodeDoubleBlobs(props, trackDat);
                
% apply area threshold before assigning centroids
above_min = cat(1,props.Area) .* (expmt.parameters.mm_per_pix^2) > ...
    expmt.parameters.area_min;
props(~above_min,:) = [];

% assign each blob in props to an ROI
[candidate_ROI_cen, blob_num] = assignROI(cat(1,props.Centroid), expmt);

[blob_assigned, blob_permutation] = ...
    arrayfun(@(trace, blob) sortROI_multitrack(trace, blob, ...
        trackDat.t, expmt.parameters.speed_thresh), ...
        trackDat.traces, candidate_ROI_cen, 'UniformOutput',false);
            
arrayfun(@(t) updateDuration(t), trackDat.traces);
            
trackDat.permutation = cellfun(@(bn,bp) bn(bp), blob_num, blob_permutation,...
                    'UniformOutput',false);

unassigned_blobs = cellfun(@(cr,ba) cr(~ba,:), candidate_ROI_cen, ... 
                       blob_assigned, 'UniformOutput', false);
%add_nums = cellfun(@(ba) find(~ba), blob_assigned, 'UniformOutput', false);

[blob_assigned, ~] = ...
    arrayfun(@(trace, blob) sortROI_multitrack(trace, blob, ...
        trackDat.t, expmt.parameters.speed_thresh), ...
        trackDat.candidates, unassigned_blobs,'UniformOutput', false);  

arrayfun(@(t) updateDuration(t), trackDat.candidates);

new_cen = arrayfun(@(ub, can, ba) getNewTraces(ub, can, ba, trackDat.t),...
    unassigned_blobs, trackDat.candidates, blob_assigned,...
    'UniformOutput', false);
              
% is_new = cat(1,is_newtrace{:});
% if any(is_new)
%     pp = cellfun(@(bn,an,ap,in) bn(an(ap(in))), ...
%         blob_num, add_nums, add_permutation, is_newtrace,...
%         'UniformOutput', false);
%     disp('pause');
% end

arrayfun(@(trace, cen) ...
    reviveTrace(trace, cen, trackDat.t), trackDat.traces, new_cen);
      
% trackDat.permutation = cellfun(@(bn,bp) bn(bp), blob_num, blob_permutation,...
%     'UniformOutput',false);