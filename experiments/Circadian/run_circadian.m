function [expmt] = run_circadian(expmt,gui_handles)
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

% get handles
gui_fig = gui_handles.gui_fig;                            % gui figure handle
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','image');   % image handle


%% Experimental Setup

% Initialize experiment parameters
ref_stack = repmat(expmt.ref, 1, 1, gui_handles.edit_ref_depth.Value);  % initialize the reference stack

% Initialize tracking variables
trackDat.fields={'Centroid';'Time';'Light';'Motor'};                 % properties of the tracked objects to be recorded

% initialize labels, files, and cam/video
[trackDat,expmt] = autoInitialize(trackDat,expmt,gui_handles);

% lastFrame = false until last frame of the last video file is reached
lastFrame = false;

%% Circadian specific parameters

%Initialize vibration parameters
trackDat.vib.stat = 0;                                    % Trackings whether current iteration is during a bout of stimulation
trackDat.vib.prev = 0;
trackDat.vib.ct = 0;
trackDat.vib.t = 0;
trackDat.pulse.stat = 0;
trackDat.pulse.ct = 0;
trackDat.pulse.prev = 0;
trackDat.ramp.stat = false;
trackDat.ramp.ct = 0;
trackDat.ramp.t = 0;

% declare image processing options
expmt.parameters.dilate_element = [];


%{
isPuls=0;                                        % Pulse state from current iteration
wasVib=0;                                   % tracks whether previous iteration occured during bout of stimulation
wasPuls=0;                                       % Pulse state from previous iteration
pulse_ct=0;                                    % Current num. pulses that have occured during a bout of stimulation
vib_ct=0;                                % Current num. pulses that have occured during the entire experiment
pulse_int=(1/handles.pulse_frequency)/2;            % Length of time between successive pulses during same bout
pulse_dur=(1/handles.pulse_frequency)/2;             % Length of time any given pulse is on
vib_int=handles.pulse_interval;
vibrationDur=handles.pulse_number*(1/handles.pulse_frequency);
%}

%% Determine position in light/dark cycle and initialize white light

t=clock;            % grab current time
t=t(4:5);           % grab hrs and min only

if expmt.parameters.lights_ON(1)<=t(1) && expmt.parameters.lights_OFF(1)>=t(1)
    if expmt.parameters.lights_ON(2)<=t(2)
        trackDat.Light = uint8(expmt.light.white);
        writeInfraredWhitePanel(expmt.COM,0,trackDat.Light);
        trackDat.light.stat=1;
    else
        trackDat.Light = uint8(0);
        writeInfraredWhitePanel(expmt.COM,0,0);
        trackDat.light.stat=0;
    end
else
        trackDat.Light = uint8(0);
        writeInfraredWhitePanel(expmt.COM,0,0);
        trackDat.light.stat=0;
end

%% Main Experimental Loop

% start timer
tic
tPrev = toc;

% initialize centroid markers
clean_gui(gui_handles.axes_handle);
hold on
hMark = plot(trackDat.Centroid(:,1),trackDat.Centroid(:,2),'ro');
hold off

% run experimental loop until duration is exceede d or last frame
% of the last video file is reached
while trackDat.t < gui_handles.edit_exp_duration.Value * 3600 && ~lastFrame
    
    % update time stamps and frame rate
    [trackDat, tPrev] = updateTime(trackDat, tPrev, expmt, gui_handles);

    % Take single frame
    if strcmp(expmt.source,'camera')
        
        % grab frame from camera
        trackDat.im = peekdata(expmt.camInfo.vid,1);
        
    else
        % get next frame from video file
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

    % track, sort to ROIs, output optional fields set during intialization
    % and compare noise to the noise distribution measured during sampling
    trackDat = autoTrack(trackDat,expmt,gui_handles);

    % update motor and light panel
    trackDat = updateCircadian(trackDat,expmt,gui_handles);

    % output data tracked fields to binary files
    for i = 1:length(trackDat.fields)
        precision = class(trackDat.(trackDat.fields{i}));
        fwrite(expmt.(trackDat.fields{i}).fID,trackDat.(trackDat.fields{i}),precision);
    end

    % update ref at the reference frequency or reset if noise thresh is exceeded
    [trackDat, ref_stack, expmt] = updateRef(trackDat, ref_stack, expmt, gui_handles);

    % display update
    if gui_handles.display_menu.UserData ~= 5
        
        % set image data
        updateDisplay(trackDat, expmt, imh, gui_handles);

        % update centroid mark position
        hMark.XData = trackDat.Centroid(:,1);
        hMark.YData = trackDat.Centroid(:,2);
    end
    
    % force immediate screen drawing and callback evaluation
    drawnow limitrate                 
    
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
    elseif isfield(expmt,'VideoData')
        writeVideo(expmt.VideoData.obj,trackDat.im);
    end
    
end


% wrap up experiment and save master struct
expmt = autoFinish(trackDat, expmt, gui_handles);

