function [expmt] = run_ledymaze(expmt,gui_handles)
%


%% Initialization: Get handles and set default preferences

gui_notify(['executing ' mfilename '.m'],gui_handles.disp_note);

% clear memory
clearvars -except gui_handles expmt

% get handles
gui_fig = gui_handles.gui_fig;                            % gui figure handle
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','image');   % image handle

%% Experimental Setup

% Initialize experiment parameters
ref_stack = repmat(expmt.ref, 1, 1, ...
    gui_handles.edit_ref_depth.Value);                      % initialize the reference stack
nROIs = size(expmt.ROI.centers,1);                          % number of ROIs

% Initialize tracking variables
trackDat.fields={'Centroid';'Time';'Turns';'LightChoice'};  % properties of the tracked objects to be recorded

% initialize labels, files, and cam/video
[trackDat,expmt] = autoInitialize(trackDat,expmt,gui_handles);

% lastFrame = false until last frame of the last video file is reached
lastFrame = false;

%% Y-maze specific parameters

% Calculate coordinates of end of each maze arm
trackDat.arm = zeros(nROIs,2,6);                            % Placeholder
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

%% LED Y-maze specific setup

% Detect available ports
serialInfo = instrhwinfo('serial');
ports=serialInfo.AvailableSerialPorts;
objs = instrfindall;

if ~any(strcmp(expmt.AUX_COM{:},ports))
    for i = 1:length(objs)
        if strcmp(objs(i).port,expmt.AUX_COM{:})
            fclose(objs(i));
            delete(objs(i));
        end
    end
end

% Initialize serial object
serial_obj = serial(expmt.AUX_COM{:});                  % Create Serial Object
set(serial_obj,'BaudRate',9600);                         % Set baud rate
fopen(serial_obj);                                       % Open the port

% Set LED permutation vector that converts LED number by maze
% into a unique address for each LED driver board on the teensy
trackDat.pLED = [1 24 2 23 3 22 4 21 5 20 6 ...
               19 7 18 8 17 9 16 34 48 35 ...
               47 36 46 37 45 38 44 39 43 ...
               40 42 41 13 12 14 11 15 10 ...
               82 33 83 32 84 31 85 30 86 ...
               29 87 28 88 27 89 26 90 25 ...
               91 96 92 95 93 94 49 72 50  ...
               71 51 70 52 69 53 68 54 67 ...
               55 66 56 81 115 80 116 79  ...
               117 78 118 77 119 76 120 75 ...
               73 74 64 63 65 62 139 61   ...
               140 60 141 59 142 58 143 57 ...
               144 114 100 113 101 112 102 ...
               111 103 110 104 109 105 108 ...
               106 107 130 129 131 128 132 ...
               127 133 126 134 125 135 124 ...
               136 123 137 122 138 121 160 ...
               99 161 98 162 97 163 168  ...
               164 167 165 166 191 190 192 ...
               189 169 188 170 187 171 159 ...
               211 158 212 157 213 156 214 ...
               155 215 154 216 153 145 152 ...
               146 151 147 150 148 149 179 ...
               178 180 177 181 176 182 175 ...
               183 174 184 173 185 172 186 ...
               210 193 209 194 208 195 207 ...
               196 206 197 205 198 204 199 ...
               203  200  202  201];  

% Flicker lights ON/OFF to indicate board is working
trackDat.targetPWM = 4095;      % Sets the max PWM for LEDs
for i=1:6
    trackDat.LEDs = ones(nROIs,3).*mod(i,2);              
    decWriteLEDs(serial_obj,trackDat);
    pause(0.2);
end

trackDat.LEDs = logical(ones(nROIs,3));     % Initialize LEDs to ON
prev_LEDs = trackDat.LEDs;

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
    
    % Detect choice with respect to the light
    trackDat.LightChoice = detectLightChoice(trackDat);

    
    if any(trackDat.changed_arm)
        trackDat.LEDs = updateLEDs(trackDat);               % Choose a new LED for flies that just made a turn
        numActive = decWriteLEDs(serial_obj,trackDat);      % Write new LED values to teensy
    end


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
    end
    
end


% wrap up experiment and save master struct
expmt = autoFinish(trackDat, expmt, gui_handles);