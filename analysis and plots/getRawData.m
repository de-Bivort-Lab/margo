function expmt = getRawData(expmt)

% attempt to autofix aborted expmt files
if ~isfield(expmt.meta,'num_frames')
    
    expmt = updatefID(expmt,'time'); 
    attach(expmt.data.time);
    expmt.meta.num_frames = expmt.data.time.dim(1);
    
end
    

%% sequentially initialize raw data maps for each field

attach(expmt);
    
end

