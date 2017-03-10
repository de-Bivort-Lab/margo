function [expmt] = run_basictracking(expmt,gui_handles)
%
% This is a blank experimental template to serve as a framework for new
% custom experiments. The function takes the master experiment struct
% (expmt) and the handles to the gui (gui_handles) as inputs and outputs
% the data assigned to out. In this example, object centroid, pixel area,
% and the time of each frame are output to file.

%% Initialization: Get handles and set default preferences

gui_notify(['executing ' mfilename '.m'],gui_handles.disp_note);

% clear memory
clearvars -except gui_handles expmt

% set MATLAB to highest priority via windows cmd line
cmd_str = 'wmic process where name="MATLAB.exe" CALL setpriority 128';
[~,~] = system(cmd_str);

% get handles
gui_fig = gui_handles.gui_fig;                            % gui figure handle
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','image');   % image handle

% clear any objects drawn to gui window
clean_gui(gui_handles.axes_handle);

% set colormap and enable display control
colormap('gray');
set(gui_handles.display_menu.Children,'Checked','off')
set(gui_handles.display_menu.Children,'Enable','on')
gui_handles.display_raw_menu.Checked = 'on';
gui_handles.display_menu.UserData = 1;


%% Experimental Setup

% Initialize experiment parameters
ref_stack = repmat(expmt.ref, 1, 1, gui_handles.edit_ref_depth.Value);  % initialize the reference stack

% Initialize tracking variables
trackDat.fields={'Centroid';'Time'};                 % properties of the tracked objects to be recorded

% initialize labels, files, and cam/video
[trackDat,expmt] = autoInitialize(trackDat,expmt,gui_handles);

% lastFrame = false until last frame of the last video file is reached
lastFrame = false;


%% Main Experimental Loop

% start timer
tic
tPrev = toc;

% initialize centroid markers
clean_gui(gui_handles.axes_handle);
hold on
hMark = plot(trackDat.Centroid(:,1),trackDat.Centroid(:,2),'ro');
hold off

% run experimental loop until duration is exceeded or last frame
% of the last video file is reached
while trackDat.t < gui_handles.edit_exp_duration.Value * 3600 && ~lastFrame
    
    % update time stamps and frame rate
    [trackDat, tPrev] = updateTime(trackDat, tPrev, expmt, gui_handles);

    % Take single frame
    if strcmp(expmt.source,'camera')
        trackDat.im = peekdata(expmt.camInfo.vid,1);
    else
        [trackDat.im, expmt.video] = nextFrame(expmt.video,gui_handles);
        
        % stop expmt when last frame of last video is reached
        if isfield(expmt.video,'fID')
            lastFrame = feof(expmt.video.fID);
        elseif ~hasFrame(expmt.video.vid) && expmt.video.ct == expmt.video.nVids
            lastFrame = true;
        end
    end

    % ensure that image is mono
    if size(trackDat.im,3)>1
        trackDat.im=trackDat.im(:,:,2);
    end

    % track, sort to ROIs, and output optional fields to sorted fields,
    % and sample the number of pixels above the image threshold
    trackDat = autoTrack(trackDat,expmt,gui_handles);


    % output data to binary files
    for i = 1:length(trackDat.fields)
        precision = class(trackDat.(trackDat.fields{i}));
        fwrite(expmt.(trackDat.fields{i}).fID,trackDat.(trackDat.fields{i}),precision);
    end

    % update ref at the reference frequency or reset if noise thresh is exceeded
    [trackDat, ref_stack, expmt] = updateRef(trackDat, ref_stack, expmt, gui_handles);

    if gui_handles.display_menu.UserData ~= 5
        % update the display
        updateDisplay(trackDat, expmt, imh, gui_handles);

        % update centroid mark position
        hMark.XData = trackDat.Centroid(:,1);
        hMark.YData = trackDat.Centroid(:,2);
    end

    % update the gui
    drawnow
    
    % listen for gui pause/unpause
    while gui_handles.pause_togglebutton.Value
        tPrev = toc;
        pause(0.01);
    end
        
    % optional: save vid data to file if record video menu item is checked
    if ~isfield(expmt,'VideoData') && strcmp(gui_handles.record_video_menu.Checked,'on')
        [trackDat,expmt] = initializeVidRecording(trackDat,expmt,gui_handles);
    end
    
end

% record the dimensions of data in each recorded field
for i = 1:length(trackDat.fields)
    expmt.(trackDat.fields{i}).dim = size(trackDat.(trackDat.fields{i}));
    expmt.(trackDat.fields{i}).precision = class(trackDat.(trackDat.fields{i}));
end

% store number of dropped frames for each object in master data struct
expmt.drop_ct = trackDat.drop_ct;
expmt.fields = trackDat.fields;
expmt.nFrames = trackDat.ct;

if isfield(expmt.camInfo,'vid')
    delete(expmt.camInfo.vid);
    expmt.camInfo = rmfield(expmt.camInfo,'src');
    expmt.camInfo = rmfield(expmt.camInfo,'vid');
end

% close fileIDs
% generate file ID for files to write
for i = 1:length(trackDat.fields)                           
    fclose(expmt.(trackDat.fields{i}).fID);
end

% re-save updated expmt data struct to file
save([expmt.fdir expmt.fLabel '.mat'],'expmt');
gui_notify(['experiment complete'],gui_handles.disp_note);

