function traces = addNewTraces(new_traces, traces, max_ct, t_elapsed)

if ~isempty(new_traces)
    nan_idx = find(isnan(traces.centroid(:,1)), size(new_traces,1), 'first');
    traces.centroid(nan_idx,:) = new_traces(1:numel(nan_idx),:);
    traces.duration(nan_idx) = max_ct;
    traces.t(nan_idx) = t_elapsed;
end