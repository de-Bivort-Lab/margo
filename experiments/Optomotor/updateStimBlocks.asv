function [trackDat,expmt] = updateStimBlocks(trackDat, expmt)

if ((expmt.sweep.t + expmt.sweep.interval) - trackDat.t) <= 0
    
    % get sweep parameters
    sweep = expmt.sweep;

    % randomly pick parameters
    expmt.parameters.contrast = sweep.contrasts(randi([1 length(sweep.contrasts)],1,1));
    expmt.parameters.ang_per_frame = sweep.ang_vel(randi([1 length(sweep.ang_vel)],1,1));
    expmt.parameters.num_cycles = sweep.spatial_freq(randi([1 length(sweep.spatial_freq)],1,1));
    expmt.sweep.t = toc;
    
    % assign to trackDat fields for output to file
    trackDat.SpatialFreq = expmt.parameters.num_cycles;
    trackDat.AngularVel = expmt.parameters.ang_per_frame;
    trackDat.Contrast = expmt.parameters.contrast;
    
    % initialize new stimulus
    expmt.stim.im = initialize_pinwheel(expmt.stim.sz, expmt.stim.sz,...
        expmt.parameters.num_cycles, expmt.parameters.mask_r, ...
        expmt.parameters.contrast);
    
end
