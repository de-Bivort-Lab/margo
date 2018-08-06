function new_traces = getNewTraces(candidate_ROI_cen, can, ...
                blob_assigned, t_elapsed)


if any(~blob_assigned)
    
    if size(can.duration,2) == 0
        can.duration = can.duration';
    end
    if size(can.t,2) == 0
        can.t = can.t';
    end
    if size(can.updated,2) == 0
        can.updated = can.updated';
    end
    can.cen= cat(1, can.cen, candidate_ROI_cen(~blob_assigned,:));
    can.duration = cat(1, can.duration, ones(sum(~blob_assigned),1));
    can.t = cat(1, can.t, repmat(t_elapsed, sum(~blob_assigned), 1));
    can.updated = cat(1, can.updated, true(sum(~blob_assigned),1));
end

is_newtrace = can.duration == can.max_duration;
new_traces = can.cen(is_newtrace,:);
can.cen(is_newtrace,:) = [];
can.duration(is_newtrace) = [];
can.t(is_newtrace) = [];
can.updated(is_newtrace) = [];