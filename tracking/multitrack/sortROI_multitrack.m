
function [traces_out, blob_assigned, blob_permutation] = ...
             sortROI_multitrack(traces_in, blob_cen, t_curr, spd_thresh)
%% sort ROIs in multitracking mode
% inputs
%   -> prev_cen:  all trace coords for previous frame of a single ROI
%   -> can_cen:   all blob coords assigned to ROI for current frame

traces_out = traces_in;
trace_permutation = [];
blob_permutation = [];

if isempty(traces_in.centroid)
    traces_in.centroid = zeros(0,1);
end

% define sorting mode
if sum(~isnan(traces_in.centroid(:,1))) <= size(blob_cen,1)
    sort_mode = 'trace_sort';
else
    sort_mode = 'blob_sort';
end

switch sort_mode
    case 'trace_sort'
        tar_cen = traces_in.centroid;
        can_cen = blob_cen;
        targets_assigned = false(size(tar_cen,1),1);
        candidates_assigned = false(size(can_cen,1),1);
        targets_assigned(isnan(traces_in.centroid(:,1))) = true;
        tar_cen(targets_assigned,:) = [];
        trace_updated = targets_assigned;
        blob_assigned = candidates_assigned;
        
    case 'blob_sort'
        tar_cen = blob_cen;
        can_cen = traces_in.centroid;
        targets_assigned = false(size(tar_cen,1),1);
        candidates_assigned = false(size(can_cen,1),1);
        candidates_assigned(isnan(traces_in.centroid(:,1))) = true;
        can_cen(candidates_assigned,:) = [];
        trace_updated = candidates_assigned;
        blob_assigned = targets_assigned;
end

% exit early if there is nothing to sort
if isempty(tar_cen)
    return;
end

while any(~targets_assigned)
    % pairwise distance for each target to the candidates
    pw_dist = cellfun(@(c) sqrt((c(1)-can_cen(:,1)).^2 +...
                                (c(2)-can_cen(:,2)).^2),...
                                num2cell(tar_cen,2),'UniformOutput',false);

    % get the min distance for each target to closest candidate and return
    % the index of the closest candidate
    [min_dist,match_idx] = cellfun(@min,pw_dist);

    % find candidate indices that are assigned to more than one target
    has_dup = find(histc(match_idx,1:size(can_cen,1))>1);


    no_dup = ~ismember(match_idx,has_dup);
    can_idx = find(~candidates_assigned);
    tar_idx = find(~targets_assigned);

    switch sort_mode
        case 'blob_sort'
            traces_out.centroid(can_idx(match_idx(no_dup)),:) = tar_cen(no_dup,:);
           traces_in.t_out(can_idx(match_idx(no_dup))) = t_curr;
            trace_permutation = [trace_permutation; can_idx(match_idx(no_dup))];
            blob_permutation = [blob_permutation; tar_idx(no_dup)];
        case 'trace_sort'
            traces_out.centroid(tar_idx(no_dup),:) = can_cen(match_idx(no_dup),:);
           traces_in.t_out(tar_idx(no_dup)) = t_curr;
            trace_permutation = [trace_permutation; tar_idx(no_dup)];
            blob_permutation = [blob_permutation; can_idx(match_idx(no_dup))];
    end

    candidates_assigned(can_idx(match_idx(no_dup))) = true;

    remove_can = match_idx(no_dup);
    idx_shift = arrayfun(@(x) sum(remove_can<x), match_idx);
    match_idx = match_idx - idx_shift;
    can_cen(remove_can,:)=[];
    min_dist(no_dup)=[];
    match_idx(no_dup) = [];           
    tar_cen(no_dup,:) = [];
    targets_assigned(tar_idx(no_dup)) = true;

    % resolve duplicate assignments by finding nearest neighbor
    if ~isempty(has_dup)
        sub_idx = arrayfun(@(idx) find(match_idx==idx),...
                                unique(match_idx),'UniformOutput',false);
        [~,sub_match] = arrayfun(@(idx) min(min_dist(match_idx==idx)),...
                                unique(match_idx));
        best_match = cellfun(@(x,y) x(y), sub_idx, num2cell(sub_match));
        %tmp_match = match_idx+idx_shift(~no_dup);
        can_idx = find(~candidates_assigned);
        tar_idx = find(~targets_assigned);

        switch sort_mode
            case 'blob_sort'
                traces_out.centroid(can_idx(best_match),:) = tar_cen(best_match,:);
               traces_in.t_out(can_idx(best_match)) = t_curr;
                trace_permutation = [trace_permutation; can_idx(best_match)];
                blob_permutation = [blob_permutation; tar_idx(best_match)];
            case 'trace_sort'
                traces_out.centroid(tar_idx(best_match),:) = can_cen ...
                                                   (unique(match_idx),:);
               traces_in.t_out(tar_idx(best_match)) = t_curr;
                trace_permutation = [trace_permutation; tar_idx(best_match)];
                blob_permutation = [blob_permutation; can_idx(best_match)];
        end

        candidates_assigned(can_idx(best_match)) = true;
        targets_assigned(tar_idx(best_match)) = true;
        can_cen(unique(match_idx),:) = [];
        tar_cen(best_match,:) = [];
    end

end

switch sort_mode
    case 'trace_sort'
        trace_updated = targets_assigned;
        blob_assigned = candidates_assigned;
        
    case 'blob_sort'
        trace_updated = candidates_assigned;
        blob_assigned = targets_assigned;
end

[~,p] = sort(trace_permutation);
blob_permutation = blob_permutation(p);

trace_updated(isnan(traces_out.centroid(:,1))) = false;

%% apply speed threshold to centroid tracking
% calculate distance and convert from pix to mm
d = sqrt((traces_out.centroid(:,1)-traces_in.centroid(:,1)).^2 + ...
         (traces_out.centroid(:,2)-traces_in.centroid(:,2)).^2);
d = d .* 1;

% time elapsed since each centroid was last updated
dt = t_curr -traces_in.t;

% calculate speed and remove centroids over threshold
spd = d./dt;
above_spd = spd > spd_thresh;
traces_out.centroid(above_spd,:) = traces_in.centroid(above_spd,:);
traces_out.t(above_spd,:) = traces_in.t(above_spd,:);

traces_out.updated = trace_updated & ~above_spd;
blob_permutation(ismember(trace_permutation,find(above_spd))) = [];

if size(traces_out.updated,1) ~= size(traces_out.centroid,1)
    disp();
end




