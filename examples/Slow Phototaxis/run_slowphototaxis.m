function expmt = run_slowphototaxis(expmt,gui_handles,varargin)
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
                trackDat = varargin{i};
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

% Initialize tracking variables
trackDat.fields={'centroid';'orientation';'time';'StimAngle';'Texture'};

% initialize labels, files, and cam/video
[trackDat,expmt] = autoInitialize(trackDat,expmt,gui_handles);

% lastFrame = false until last frame of the last video file is reached
trackDat.lastFrame = false;


%% Initialize the psychtoolbox window and query projector properties
bg_color=[0 0 0];          
expmt = initialize_projector(expmt, bg_color);
Fx = expmt.hardware.projector.Fx;
Fy = expmt.hardware.projector.Fy;
pause(1);

set(gui_handles.display_menu.Children,'Checked','off')
set(gui_handles.display_menu.Children,'Enable','on')
gui_handles.display_none_menu.Checked = 'on';
gui_handles.display_menu.UserData = 5;

%% Calculate ROI coords in the projector space and expand the edges 

% tmp vars
nROIs = expmt.meta.roi.n;
scor = NaN(size(expmt.meta.roi.corners));
rcor = expmt.meta.roi.corners;
scen = NaN(nROIs,2);
rcen = expmt.meta.roi.centers;

% convert ROI coordinates to projector coordinates for stimulus targeting
scen(:,1) = Fx(rcen(:,1),rcen(:,2));
scen(:,2) = Fy(rcen(:,1),rcen(:,2));

scor(:,1) = Fx(rcor(:,1), rcor(:,2));   
scor(:,2) = Fy(rcor(:,1), rcor(:,2));
scor(:,3) = Fx(rcor(:,3), rcor(:,4));
scor(:,4) = Fy(rcor(:,3), rcor(:,4));

% add a buffer to stim bounding box to ensure entire ROI is covered
sbbuf = nanFilteredMean([scor(:,3)-scor(:,1), scor(:,4)-scor(:,2)],2)*0.05;
scor(:,[1 3]) = [scor(:,1)-sbbuf, scor(:,3)+sbbuf];
scor(:,[2 4]) = [scor(:,2)-sbbuf, scor(:,4)+sbbuf];


%% Pre-allocate stimulus image for texture making

% Determine stimulus size by calculating mean ROI edge length
stmsz=round(nanFilteredMean(nanFilteredMean([scor(:,3)-scor(:,1) scor(:,4)-scor(:,2)])));
src_edge_length = stmsz;
stmsz=sqrt(stmsz^2+stmsz^2);

% Initialize the stimulus image
light = initialize_photo_stim(ceil(stmsz),ceil(stmsz), ...
            expmt.parameters.divider_size,expmt.parameters.stim_contrast);
dark = ones(size(light)); 

% Initialize source rect and scaling factors
stim.base = [0 0 src_edge_length src_edge_length];
stim.source = CenterRectOnPointd(stim.base,stmsz/2,stmsz/2);

%% Slow phototaxis specific parameters

stim.lightTex = Screen('MakeTexture', expmt.hardware.screen.window, light);      % texture for half-light half-dark
stim.darkTex = Screen('MakeTexture', expmt.hardware.screen.window, dark);        % texture for all dark

stim.t = 0;
stim.ct = 0;                          % Counter for number of looming stim displayed each stimulation period
trackDat.StimAngle = single(zeros(nROIs,1));        % Initialize stimulus starting angle to 0
stim.prev_ori=NaN(nROIs,1);
stim.dir = boolean(ones(nROIs,1));    % Direction of rotation for the light
trackDat.Texture = boolean(1);              % active texture (dark or light)
stim.corners = scor;
stim.centers = scen;

% assign stim to ExperimentData
expmt.meta.stim = stim;

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
    [trackDat, expmt] = updatePhotoStim(trackDat, expmt);
    
    % output data to binary files
    [trackDat,expmt] = autoWriteData(trackDat, expmt, gui_handles);

    % update ref at the reference frequency or reset if noise thresh is exceeded
    [trackDat, expmt] = autoReference(trackDat, expmt, gui_handles);  

    % update the display
    trackDat = autoDisplay(trackDat, expmt, imh, gui_handles);
    
end




function update_stat_display(c, n, ch, h)

h.Position = [c{1}(1)-5,c{1}(2)+15];
if ch
    h.String = num2str(n);
end