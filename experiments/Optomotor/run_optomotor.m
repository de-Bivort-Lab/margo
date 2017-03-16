function [expmt] = run_optomotor(expmt,gui_handles)
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
nROIs = size(expmt.ROI.centers,1);                                      % number of ROIs

% Initialize tracking variables
trackDat.fields={'Centroid';'Orientation';'Time';...
    'Speed';'StimStatus';'Texture'};  % properties of the tracked objects to be recorded

% initialize labels, files, and cam/video
[trackDat,expmt] = autoInitialize(trackDat,expmt,gui_handles);

% lastFrame = false until last frame of the last video file is reached
lastFrame = false;

%% Initialize the psychtoolbox window and query projector properties
bg_color=[0 0 0];          
expmt.scrProp=initialize_projector(bg_color);
pause(1);

%% Load the projector fit

gui_dir = which('autotrackergui');
gui_dir = gui_dir(1:strfind(gui_dir,'\gui\'));
fName = 'projector_fit.mat';

if exist([gui_dir 'hardware\projector_fit\']) == 7
    
    load([gui_dir '\hardware\projector_fit\' fName]);
    
else
    
    errordlg(['Projector registration not detected. Register the projector to the '...
        'camera before running experiments with projector dependency']);
    
end

[cam_yPixels,cam_xPixels]=size(expmt.ref);

if cam_xPixels ~= reg_data.cam_xPixels || cam_yPixels ~= reg_data.cam_yPixels
    
    x_scale = cam_xPixels/reg_data.cam_xPixels;
    y_scale = cam_yPixels/reg_data.cam_yPixels;
    cam_x = reg_data.cam_xCoords*x_scale;
    cam_y = reg_data.cam_yCoords*y_scale;
    
    % Create scattered interpolant for current camera resolution
    Fx=scatteredInterpolant(cam_x,cam_y,reg_data.proj_xCoords);
    Fy=scatteredInterpolant(cam_x,cam_y,reg_data.proj_yCoords);
    
else
    Fx = reg_data.Fx;
    Fy = reg_data.Fy;
end

%% Calculate ROI coords in the projector space and expand the edges by a small border to ensure ROI is fully covered

% tmp vars
scor = NaN(size(expmt.ROI.corners));
rcor = expmt.ROI.corners;
scen = NaN(nROIs,2);
rcen = expmt.ROI.centers;

% convert ROI coordinates to projector coordinates for stimulus targeting
scen(:,1) = Fx(rcen(:,1),rcen(:,2));
scen(:,2) = Fy(rcen(:,1),rcen(:,2));

scor(:,1) = Fx(rcor(:,1), rcor(:,2));   
scor(:,2) = Fy(rcor(:,1), rcor(:,2));
scor(:,3) = Fx(rcor(:,3), rcor(:,4));
scor(:,4) = Fy(rcor(:,3), rcor(:,4));

% add a buffer to stim bounding box to ensure entire ROI is covered
sbbuf = nanmean([scor(:,3)-scor(:,1), scor(:,4)-scor(:,2)],2)*0.05;
scor(:,[1 3]) = [scor(:,1)-sbbuf, scor(:,3)+sbbuf];
scor(:,[2 4]) = [scor(:,2)-sbbuf, scor(:,4)+sbbuf];


%% Pre-allocate stimulus image for texture making

% Determine stimulus size
pin_sz=round(nanmean(nanmean([scor(:,3)-scor(:,1) scor(:,4)-scor(:,2)]))*4);
nCycles = expmt.parameters.num_cycles;            % num dark-light cycles in 360 degrees
mask_r = expmt.parameters.mask_r;                 % radius of center circle dark mask (as fraction of stim_size)
ang_vel = expmt.parameters.ang_per_frame;         % angular velocity of stimulus (degrees/frame)
subim_r = floor(pin_sz/2*sqrt(2)/2);

% Initialize the stimulus image
expmt.stim.im = initialize_pinwheel(pin_sz,pin_sz,nCycles,mask_r);
imcenter = [size(expmt.stim.im,1)/2+0.5 size(expmt.stim.im,2)/2+0.5];
expmt.stim.bounds = [imcenter(2)-subim_r imcenter(1)-subim_r imcenter(2)+subim_r imcenter(1)+subim_r];
ssz_x = expmt.stim.bounds(3)-expmt.stim.bounds(1)+1;
ssz_y = expmt.stim.bounds(4)-expmt.stim.bounds(2)+1;


% Initialize source rect and scaling factors
expmt.stim.bs_src = [0 0 ssz_x/2 ssz_y/2];
expmt.stim.cen_src = CenterRectOnPointd(expmt.stim.bs_src,ssz_x/2,ssz_y/2);
expmt.stim.scale = NaN(nROIs,2);
expmt.stim.scale(:,1) = (ssz_x/2)./(scor(:,3)-scor(:,1));
expmt.stim.scale(:,2) = (ssz_y/2)./(scor(:,4)-scor(:,2));

%% Slow phototaxis specific parameters

trackDat.local_spd = NaN(15,nROIs);
trackDat.prev_ori = NaN(nROIs,1);

expmt.stim.pinTex_pos = Screen('MakeTexture', expmt.scrProp.window, expmt.stim.im);  % Placeholder for pinwheel textures positively rotating
expmt.stim.pinTex_neg = Screen('MakeTexture', expmt.scrProp.window, expmt.stim.im); % Placeholder for pinwheel textures negatively rotating


trackDat.StimStatus = false(nROIs,1);
trackDat.Texture = true(nROIs,1);

expmt.parameters.stim_duration = ...
    expmt.parameters.stim_duration * 60;   % duration of the stimulus per trial (min)

expmt.stim.t = zeros(nROIs,1);
expmt.stim.timer = zeros(nROIs,1);
expmt.stim.ct = 0;                     % Counter for number of looming stim displayed each stimulation period
expmt.stim.prev_ori=NaN(nROIs,1);
expmt.stim.dir = true(nROIs,1);  % Direction of rotation for the light
expmt.stim.angle = 0;
expmt.stim.corners = scor;
expmt.stim.centers = scen;
expmt.projector.Fx = Fx;
expmt.projector.Fy = Fy;

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

    % update the stimuli
    [trackDat, expmt] = updateOptoStim(trackDat, expmt);
    
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
    while gui_handles.pause_togglebutton.Value || gui_handles.stop_pushbutton.UserData.Value
        [expmt,tPrev,exit] = updatePauseStop(trackDat,expmt,gui_handles);
        if exit
            return
        end
    end
        
    % optional: save vid data to file if record video menu item is checked
    if ~isfield(expmt,'VideoData') && strcmp(gui_handles.record_video_menu.Checked,'on')
        [trackDat,expmt] = initializeVidRecording(trackDat,expmt,gui_handles);
    end
    
end


% wrap up experiment and save master struct
expmt = autoFinish(trackDat, expmt, gui_handles);

