function [trackDat,expmt] = autoInitialize(trackDat,expmt,gui_handles)

%% Initialize labels, file paths, and files for tracked fields
expmt.date = datestr(clock,'mm-dd-yyyy-HH-MM-SS_');         % get date string
expmt.labels = labelMaker(expmt);                           % convert labels cell into table format
expmt.strain=expmt.labels{1,1}{:};                          % get strain string
expmt.treatment=expmt.labels{1,3}{:};                       % get treatment string

% make a new directory for the files
expmt.fdir = [expmt.fpath '\' expmt.date expmt.strain '_' expmt.treatment '\'];
mkdir(expmt.fdir);

% generate file ID for files to write
for i = 1:length(trackDat.fields)                           
    expmt.(trackDat.fields{i}).path = ...                   % initialize path for new file    
        [expmt.fdir expmt.date expmt.strain '_' ...
        expmt.treatment '_' trackDat.fields{i} '.bin'];
    expmt.(trackDat.fields{i}).fID = ...
        fopen(expmt.(trackDat.fields{i}).path,'w');         % open fileID with write permission
end

% save current parameters to .mat file prior to experiment
params = fieldnames(gui_handles.gui_fig.UserData);
for i = 1:length(params)
    expmt.parameters.(params{i}) = gui_handles.gui_fig.UserData.(params{i});
end
save([expmt.fdir expmt.date expmt.Name '_' expmt.strain '_' expmt.treatment '.mat'],'expmt');


%% Setup the camera and/or video object

if strcmp(expmt.source,'camera') && strcmp(expmt.camInfo.vid.Running,'off')
    
    % Clear old video objects
    imaqreset
    pause(0.2);

    % Create camera object with input parameters
    expmt.camInfo = initializeCamera(expmt.camInfo);
    start(expmt.camInfo.vid);
    pause(0.1);
    
elseif strcmp(expmt.source,'video') 
    
    % set current file to first file in list
    gui_handles.vid_select_popupmenu.Value = 1;
    
    if isfield(expmt.video,'fID')
        
        % ensure that the current position of the file is set to 
        % the beginning of the file (bof) + an offset of 32 bytes
        % (the first 32 bytes store info on resolution and precision)
        fseek(expmt.video.fID, 32, 'bof');
        
    else
        
        % open video object from file
        expmt.video.vid = ...
            VideoReader([expmt.video.fdir ...
            expmt.video.fnames{gui_handles.vid_select_popupmenu.Value}]);

        % get file number in list
        expmt.video.ct = gui_handles.vid_select_popupmenu.Value;

        % estimate duration based on video duration
        gui_handles.edit_exp_duration.Value = expmt.video.total_duration * 1.15 / 3600;
        
    end
    
end

% initialize video recording if enabled
if strcmp(gui_handles.record_video_menu.Checked,'on')
    [trackDat,expmt] = initializeVidRecording(trackDat,expmt,gui_handles);
end