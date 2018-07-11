function [expmt] = run_ledymaze(expmt,gui_handles, varargin)
%

%% Parse variable inputs

for i = 1:length(varargin)
    
    arg = varargin{i};
    
    if ischar(arg)
        switch arg
            case 'Trackdat'
                i=i+1;
                trackDat = varargin{i};     % manually pass in trackDat rather than initializing
        end
    end
end

%% Initialization: Get handles and set default preferences

gui_notify(['executing ' mfilename '.m'],gui_handles.disp_note);

% clear memory
clearvars -except gui_handles expmt trackDat

% get image handle
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','image');  


%% Experimental Setup

% properties of the tracked objects to be recorded
trackDat.fields={'centroid';'time';'Turns';'LightChoice'};                 

% initialize labels, files, and cam/video
[trackDat,expmt] = autoInitialize(trackDat,expmt,gui_handles);

% lastFrame = false until last frame of the last video file is reached
trackDat.lastFrame = false;

%% Y-maze specific parameters

% Calculate coordinates of end of each maze arm
trackDat.arm = zeros(expmt.meta.roi.n,2,6);                              % Placeholder
w = expmt.meta.roi.bounds(:,3);                                  % width of each ROI
h = expmt.meta.roi.bounds(:,4);                                  % height of each ROI

% Offsets to shift arm coords in from edge of ROI bounding box
xShift = w.*0.15;                             
yShift = h.*0.15;

% Coords 1-3 are for upside-down Ys
trackDat.arm(:,:,1) = ...
    [expmt.meta.roi.corners(:,1)+xShift expmt.meta.roi.corners(:,4)-yShift];
trackDat.arm(:,:,2) = ...
    [expmt.meta.roi.centers(:,1) expmt.meta.roi.corners(:,2)+yShift];
trackDat.arm(:,:,3) = ...
    [expmt.meta.roi.corners(:,3)-xShift expmt.meta.roi.corners(:,4)-yShift];

% Coords 4-6 are for right-side up Ys
trackDat.arm(:,:,4) = ...
    [expmt.meta.roi.corners(:,1)+xShift expmt.meta.roi.corners(:,2)+yShift];
trackDat.arm(:,:,5) = ...
    [expmt.meta.roi.centers(:,1) expmt.meta.roi.corners(:,4)-yShift];
trackDat.arm(:,:,6) = ...
    [expmt.meta.roi.corners(:,3)-xShift expmt.meta.roi.corners(:,2)+yShift];

% time stamp of last scored turn for each object
trackDat.turntStamp = zeros(expmt.meta.roi.n,1);     
trackDat.prev_arm = zeros(expmt.meta.roi.n,1);

% calculate arm threshold as fraction of width and height
expmt.parameters.arm_thresh = mean([w h],2) .* 0.2;
nTurns = zeros(size(expmt.meta.roi.centers,1),1);

%% LED Y-maze specific setup

% Detect available ports


if ~isempty(expmt.hardware.COM.aux) && ...
        strcmp(expmt.hardware.COM.aux.Status,'closed')
    
    fopen(expmt.hardware.COM.aux);
    
elseif isempty(expmt.hardware.COM.aux)
    
    error('no AUX COM object selected');
    
end

% Initialize serial object
serial_obj = expmt.hardware.COM.aux;
set(serial_obj,'BaudRate',9600);                         % Set baud rate

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
trackDat.targetPWM = 1500;      % Sets the max PWM for LEDs
for i=1:6
    trackDat.LEDs = ones(expmt.meta.roi.n,3).*mod(i,2);              
    decWriteLEDs(serial_obj,trackDat);
    pause(0.2);
end

trackDat.LEDs = true(expmt.meta.roi.n,3);     % Initialize LEDs to ON
prev_LEDs = trackDat.LEDs;

%% Main Experimental Loop


% run experimental loop until duration is exceeded or last frame
% of the last video file is reached
while ~trackDat.lastFrame
    
    % update time stamps and frame rate
    [trackDat] = autoTime(trackDat, expmt, gui_handles);

    % query next frame and optionally correct lens distortion
    [trackDat,expmt] = autoFrame(trackDat,expmt,gui_handles);


    % track, sort to ROIs, and output optional fields to sorted fields,
    % and sample the number of pixels above the image threshold
    trackDat = autoTrack(trackDat,expmt,gui_handles);

    % Determine if fly has changed to a new arm
    trackDat = detectArmChange(trackDat,expmt);

    % Create placeholder for arm change vector to write to file
    trackDat.Turns=int16(zeros(expmt.meta.roi.n,1));
    trackDat.Turns(trackDat.changed_arm) = trackDat.prev_arm(trackDat.changed_arm);
    nTurns(trackDat.changed_arm) = nTurns(trackDat.changed_arm)+1;
    
    % Detect choice with respect to the light
    trackDat.LightChoice = detectLightChoice(trackDat);

    if any(trackDat.changed_arm)
        trackDat.LEDs = updateLEDs(trackDat);               % Choose a new LED for flies that just made a turn
        numActive = decWriteLEDs(serial_obj,trackDat);      % Write new LED values to teensy
    end

    % output data to binary files
    [trackDat,expmt] = autoWriteData(trackDat, expmt, gui_handles);

    % update ref at the reference frequency or reset if noise thresh is exceeded
    [trackDat, expmt] = autoReference(trackDat, expmt, gui_handles);  

    % update the display
    trackDat = autoDisplay(trackDat, expmt, imh, gui_handles);
    
end


%% post-experiment wrap-up

% auto process data and save master struct
if expmt.meta.finish
    expmt = autoFinish(trackDat, expmt, gui_handles);
end

for i=1:nargout
    switch i
        case 1, varargout(i) = {expmt};
        case 2, varargout(i) = {trackDat};
    end
end