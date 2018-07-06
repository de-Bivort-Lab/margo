function [batch_size, batch_num] = getBatchSize(expmt, batch_scale)
% calculates batch size and number by computing total processing size
% (bytes), scaling the result by batch_scale, and dividing by available
% memory

[~,msz] = memory;
msz = msz.PhysicalMemory.Available;
switch expmt.data.centroid.precision
    case 'double'
        cen_prcn = 8;
    case 'single'
        cen_prcn = 4;
end
full_size = ...
    expmt.meta.num_traces * expmt.meta.num_frames * (cen_prcn*2 + batch_scale);
batch_num = ceil(full_size/msz * 2);
batch_size = ceil(expmt.meta.num_frames/batch_num);