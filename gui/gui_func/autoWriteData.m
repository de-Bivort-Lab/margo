function [trackDat,expmt] = autoWriteData(trackDat, expmt, gui_handles)

% if first frame update the expmt file with output precision and dimensions
if trackDat.ct == 1 && ~expmt.meta.initialize
    
    % record the dimensions of data in each recorded field
    for i = 1:length(trackDat.fields)
        expmt.data.(trackDat.fields{i}).dim = ...
            size(trackDat.(trackDat.fields{i}));
        expmt.data.(trackDat.fields{i}).precision = ...
            class(trackDat.(trackDat.fields{i}));
    end
    
    expmt.meta.fields = trackDat.fields;
    save([expmt.meta.path.dir expmt.meta.path.name '.mat'],'expmt','-v7.3');  
end

% write raw data to binary files
for i = 1:length(trackDat.fields)
    precision = class(trackDat.(trackDat.fields{i}));
    fwrite(expmt.data.(trackDat.fields{i}).fID,...
        trackDat.(trackDat.fields{i}),precision);
end

% optional: save vid data to file if record video menu item is checked
if ~isfield(expmt.meta,'VideoData') && isfield(expmt.meta,'video_out') ...
        && expmt.meta.video_out.record
    
    % initialize new video if none exists
    expmt = initializeVidRecording(expmt,gui_handles);
    
% record frame    
elseif isfield(expmt.meta,'VideoData')
    
    % enforce sub-sampling rate
    if expmt.meta.video_out.rate >= 0 && ...
            expmt.meta.video_out.t < 1/expmt.meta.video_out.rate
        return
    end
    
    % assign image to write base on image data source
    switch expmt.meta.video_out.source
        case 'raw image'
            im_out = trackDat.im;
        case 'threshold image'
            im_out = trackDat.thresh_im;
        case 'difference image'
            im_out = trackDat.diffim;
    end
    
    % reset the sub-sampling timer and write video frame
    expmt.meta.video_out.t
    writeVideo(expmt.meta.VideoData.obj, im_out);
end