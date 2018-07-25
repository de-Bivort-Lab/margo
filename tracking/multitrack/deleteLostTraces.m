function [traces] = deleteLostTraces(traces)

active_traces = traces.duration > 0;
traces.centroid(~active_traces,:) = NaN;
traces.t(~active_traces,:) = NaN;