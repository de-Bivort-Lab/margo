function [expmt] = run_ymaze(expmt,gui_handles)
%


%% Initialization: Get handles and set default preferences

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
set(gui_handles.display_menu.Children,'Enable','on');
set(gui_handles.display_menu.Children,'Checked','off');
set(gui_handles.display_raw_menu,'Checked','on');
gui_handles.display_menu.UserData = 1;



%% Experimental Setup

% Initialize experiment parameters
ref_stack = repmat(expmt.ref, 1, 1, ...
    gui_handles.edit_ref_depth.Value);                      % initialize the reference stack
nROIs = size(expmt.ROI.centers,1);                          % number of ROIs

% Initialize tracking variables
trackDat.fields={'Centroid';'Time';'Turns'};                % properties of the tracked objects to be recorded

% initialize labels, files, and cam/video
[trackDat,expmt] = autoInitialize(trackDat,expmt,gui_handles);

% lastFrame = false until last frame of the last video file is reached
lastFrame = false;

%% Y-maze specific parameters

% Calculate coordinates of end of each maze arm
trackDat.arm = zeros(nROIs,2,6);                              % Placeholder
w = expmt.ROI.bounds(:,3);                                  % width of each ROI
h = expmt.ROI.bounds(:,4);                                  % height of each ROI

% Offsets to shift arm coords in from edge of ROI bounding box
xShift = w.*0.15;                             
yShift = h.*0.15;

% Coords 1-3 are for upside-down Ys
trackDat.arm(:,:,1) = [expmt.ROI.corners(:,1)+xShift expmt.ROI.corners(:,4)-yShift];
trackDat.arm(:,:,2) = [expmt.ROI.centers(:,1) expmt.ROI.corners(:,2)+yShift];
trackDat.arm(:,:,3) = [expmt.ROI.corners(:,3)-xShift expmt.ROI.corners(:,4)-yShift];

% Coords 4-6 are for right-side up Ys
trackDat.arm(:,:,4) = [expmt.ROI.corners(:,1)+xShift expmt.ROI.corners(:,2)+yShift];
trackDat.arm(:,:,5) = [expmt.ROI.centers(:,1) expmt.ROI.corners(:,4)-yShift];
trackDat.arm(:,:,6) = [expmt.ROI.corners(:,3)-xShift expmt.ROI.corners(:,2)+yShift];

trackDat.turntStamp = zeros(nROIs,1);                                % time stamp of last scored turn for each object
trackDat.prev_arm = zeros(nROIs,1);

% calculate arm threshold as fraction of width and height
expmt.parameters.arm_thresh = mean([w h],2) .* 0.2;
nTurns = zeros(size(expmt.ROI.centers,1),1);


%% Main Experimental Loop

% start timer
tic
tPrev = toc;

% initialize centroid markers
clean_gui(gui_handles.axes_handle);
hold on
hMark = plot(trackDat.Centroid(:,1),trackDat.Centroid(:,2),'ro');
for i = 1:nROIs
    hNTurns(i) = text(trackDat.Centroid(i,1)-5,trackDat.Centroid(i,2)+10,'',...
    'Color',[1 0 0]);
end
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
    
    if lastFrame
        break
    end

    % ensure that image is mono
    if size(trackDat.im,3)>1
        trackDat.im=trackDat.im(:,:,2);
    end

    % track, sort to ROIs, and output optional fields to sorted fields,
    % and sample the number of pixels above the image threshold
    trackDat = autoTrack(trackDat,expmt,gui_handles);

    % Determine if fly has changed to a new arm
    trackDat = detectArmChange(trackDat,expmt);

    % Create placeholder for arm change vector to write to file
    trackDat.Turns=NaN(nROIs,1);
    trackDat.Turns(trackDat.changed_arm) = trackDat.prev_arm(trackDat.changed_arm);
    nTurns(trackDat.changed_arm) = nTurns(trackDat.changed_arm)+1;

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
        
        for i = 1:nROIs
            hNTurns(i).Position = [trackDat.Centroid(i,1)-5,trackDat.Centroid(i,2)+15];
            if trackDat.changed_arm(i)
                hNTurns(i).String = nTurns(i);
            end
        end
        
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
save([expmt.fdir expmt.date expmt.Name '_' expmt.strain '_' expmt.treatment '.mat'],'expmt');
gui_notify(['experiment complete'],gui_handles.disp_note);



