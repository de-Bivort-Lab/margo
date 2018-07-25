function trace_out = updateTraceDuration(trace_out, max_trace_count)

                       
trace_out.duration(trace_out.updated) = trace_out.duration(trace_out.updated) + 1;
trace_out.duration(~trace_out.updated) = trace_out.duration(~trace_out.updated) - 1;
trace_out.duration(trace_out.duration > max_trace_count) = max_trace_count;
trace_out.duration(trace_out.duration == 0) = NaN;
