function varargout = run_tempphototaxis(expmt,gui_handles,varargin)
%
% This is a blank experimental template to serve as a framework for new
% custom experiments. The function takes the master experiment struct
% (expmt) and the handles to the gui (gui_handles) as inputs and outputs
% the data assigned to out. In this example, object centroid, pixel area,
% and the time of each frame are output to file.


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

% get handles
gui_fig = gui_handles.gui_fig;                            % gui figure handle
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','image');   % image handle


%% Experimental Setup

% Initialize experiment parameters
ref_stack = repmat(expmt.meta.ref, 1, 1, gui_handles.edit_ref_depth.Value);  % initialize the reference stack
nROIs = size(expmt.ROI.centers,1);                                      % number of ROIs

% Initialize tracking variables
trackDat.fields={'Centroid';'Orientation';'Time';'LightStatus'};  % properties of the tracked objects to be recorded

% initialize labels, files, and cam/video
[trackDat,expmt] = autoInitialize(trackDat,expmt,gui_handles);
    
% lastFrame = false until last frame of the last video file is reached
trackDat.lastFrame = false;


%% Initialize the psychtoolbox window and query projector properties
bg_color=[0 0 0];          
expmt = initialize_projector(expmt, bg_color);
Fx = expmt.projector.Fx;
Fy = expmt.projector.Fy;
pause(1);

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

% Determine stimulus size by calculating mean ROI edge length
stmsz=round(nanmean(nanmean([scor(:,3)-scor(:,1) scor(:,4)-scor(:,2)])));
src_edge_length = stmsz;
stmsz=sqrt(stmsz^2+stmsz^2);

% Initialize the stimulus image
light = ones(ceil(stmsz));
dark = zeros(ceil(stmsz));
imcenter = [size(light,1)/2+0.5 size(light,2)/2+0.5];

% Initialize source rect and scaling factors
expmt.stim.base = [0 0 src_edge_length src_edge_length];
expmt.stim.source = CenterRectOnPointd(expmt.stim.base,stmsz/2,stmsz/2);

%% Slow phototaxis specific parameters

stim_ct=0;

expmt.stim.lightTex = Screen('MakeTexture', expmt.scrProp.window, light);      % texture for half-light half-dark
expmt.stim.darkTex = Screen('MakeTexture', expmt.scrProp.window, dark);        % texture for all dark
expmt.parameters.div_thresh = (mean(expmt.ROI.bounds(:,[3 4]),2) .* expmt.parameters.divider_size * 0.5)';

expmt.stim.t = 0;
expmt.stim.ct = 0;                          % Counter for number of looming stim displayed each stimulation period
trackDat.StimAngle = round(rand(nROIs,1).*360);        % Initialize random stimulus starting angle
expmt.StimAngle = trackDat.StimAngle;
expmt.stim.prev_ori=NaN(nROIs,1);
expmt.stim.dir = boolean(ones(nROIs,1));    % Direction of rotation for the light
trackDat.Texture = boolean(1);              % active texture (dark or light)
trackDat.LightStatus = false(nROIs,1);
expmt.stim.corners = scor;
expmt.stim.centers = scen;
expmt.projector.Fx = Fx;
expmt.projector.Fy = Fy;

%% Main Experimental Loop

% make sure the mouse cursor is at screen edge
robot = java.awt.Robot;
robot.mouseMove(1, 1);

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

    % update the stimuli
    [trackDat, expmt] = updateTemporalPhotoStim(trackDat, expmt);
    
    % output data to binary files
    [trackDat,expmt] = autoWriteData(trackDat, expmt, gui_handles);

    % update ref at the reference frequency or reset if noise thresh is exceeded
    [trackDat, expmt] = autoReference(trackDat, expmt, gui_handles);  
    
    % update the display
    trackDat = autoDisplay(trackDat, expmt, imh, gui_handles);

 
end

%% post-experiment wrap-up

% close the psychtoolbox window
sca;

if expmt.Finish
    
    % % auto process data and save master struct
    expmt = autoFinish(trackDat, expmt, gui_handles);

end

for i=1:nargout
    switch i
        case 1, varargout(i) = {expmt};
        case 2, varargout(i) = {trackDat};
    end
end

