function [trackDat,expmt] = autoWriteData(trackDat, expmt, gui_handles)

% if first frame update the expmt file with output precision and dimensions
if trackDat.ct == 1 && ~expmt.Initialize
    
    % record the dimensions of data in each recorded field
    for i = 1:length(trackDat.fields)
        expmt.(trackDat.fields{i}).dim = size(trackDat.(trackDat.fields{i}));
        expmt.(trackDat.fields{i}).precision = class(trackDat.(trackDat.fields{i}));
    end
    
    expmt.fields = trackDat.fields;
    save([expmt.fdir expmt.fLabel '.mat'],'expmt','-v7.3');
    
end

% write raw data to binary files
for i = 1:length(trackDat.fields)
    precision = class(trackDat.(trackDat.fields{i}));
    fwrite(expmt.(trackDat.fields{i}).fID,trackDat.(trackDat.fields{i}),precision);
end

% optional: save vid data to file if record video menu item is checked
if ~isfield(expmt,'VideoData') && strcmp(gui_handles.record_video_menu.Checked,'on')
    [trackDat,expmt] = initializeVidRecording(trackDat,expmt,gui_handles);
elseif isfield(expmt,'VideoData')
    writeVideo(expmt.VideoData.obj,trackDat.im);
end