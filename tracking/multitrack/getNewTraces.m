function [new_traces, can] = getNewTraces(candidate_ROI_cen, can, ...
                blob_assigned, max_ct, t_elapsed)

            
can.centroid(isnan(can.duration),:) = [];
can.t(isnan(can.duration)) = [];
can.updated(isnan(can.duration)) = [];
can.duration(isnan(can.duration)) = [];


if any(~blob_assigned)
    
    if size(can.duration,2) == 0
        can.duration = can.duration';
    end
    if size(can.t,2) == 0
        can.t = can.t';
    end
    can.centroid = cat(1, can.centroid, candidate_ROI_cen(~blob_assigned,:));
    can.duration = cat(1, can.duration, ones(sum(~blob_assigned),1));
    can.t = cat(1, can.t, repmat(t_elapsed, sum(~blob_assigned), 1));

end

is_newtrace = can.duration == max_ct;
new_traces = can.centroid(is_newtrace,:);


can.centroid(is_newtrace,:) = [];
can.duration(is_newtrace) = [];
can.t(is_newtrace) = [];
can.updated(is_newtrace) = [];