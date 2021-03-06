function trackDat = singleTrack_updateDuration(trackDat, update, max_dur)
% updates the trace lifespan by whether or not the centroid position was
% updated in the current frame

% update duration counter
trackDat.cen_duration(update) = trackDat.cen_duration(update) + 1;
trackDat.cen_duration(~update) = trackDat.cen_duration(~update) - 1;

% assign traces as live or dead and fix min/max bounds
live_trace = trackDat.cen_duration>=max_dur;
dead_trace = trackDat.cen_duration<0;
trackDat.cen_duration(live_trace) = max_dur;
trackDat.cen_duration(dead_trace) = 0;

% de-assign dead traces
trackDat.dead_trace(live_trace) = false;
trackDat.dead_trace = trackDat.dead_trace | dead_trace;
trackDat.centroid(trackDat.dead_trace,:) = NaN;
