function [num_frames, num_batches] = get_batch_sizes(data)

% split data into batches
data_sz = size(data);
precision = class(data(1));

% query bytes per element
bytes_per = bytes_per_el(precision);

% get total number of bytes (oversize by factor 2) and query available memory
total_bytes = numel(data) * bytes_per *2;
mem_stats = memory;

% calculate batch size and number
num_batches = ceil(total_bytes/mem_stats.MemAvailableAllArrays);
num_frames = ceil(data_sz(1)/num_batches);
