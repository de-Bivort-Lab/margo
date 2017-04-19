function updateStimBlocks(trackDat, expmt)


if ((expmt.sweep.t + expmt.sweep.interval) - trackDat.t) <= 0
    
    % get sweep parameters
    sweep = expmt.parameters.sweep;

    % randomly pick parameters
    expmt.parameters.contrast = randi([1 length(sweep.contrasts)],1,1);
    expmt.parameters.angPerFrame = randi([1 length(sweep.ang_vels)],1,1);
    expmt.parameters.nCycles = randi([1 length(sweep.spatial_freq)],1,1);
    expmt.sweep.t = toc;
    
    % initialize new stimulus
    expmt.stim.im = initialize_pinwheel(expmt.stim.sz, expmt.stim.sz,...
        expmt.parameters.nCycles, expmt.parameters.mask_r, ...
        expmt.parameters.contrast);
    
end
