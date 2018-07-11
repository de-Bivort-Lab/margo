function expmt = initialize_projector(expmt,varargin)

screen_num = expmt.hardware.projector.reg_params.screen_num;
background_color = [0 0 0];
if ~isempty(varargin)
    background_color = varargin{1};
end
    

% Clear the workspace
sca;

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1);


% Define black, white and grey
white = WhiteIndex(screen_num);
black = BlackIndex(screen_num);

% Open the screen
[window, windowRect] = PsychImaging('OpenWindow', screen_num, background_color);
Screen('Flip', window);

% Get inter frame interval
ifi = Screen('GetFlipInterval', window);

% Set maximum priority
MaxPriority(window);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% flip to background color and get retrace timestamp
vbl = Screen('Flip', window);

% Numer of frames to wait before re-drawing
waitframes = 1;

scrProp.screenNumber = screen_num;
scrProp.window = window;
scrProp.windowRect = windowRect;
scrProp.xCenter = xCenter;
scrProp.yCenter = yCenter;
scrProp.black = black;
scrProp.white = white;
scrProp.vbl = vbl;
scrProp.ifi=ifi;
scrProp.waitframes = waitframes;
expmt.hardware.screen = scrProp;

%% Load the projector fit

gui_dir = which('autotracker');
gui_dir = gui_dir(1:strfind(gui_dir,'\gui\'));
fName = 'projector_fit.mat';

if exist([gui_dir 'hardware\projector_fit\']) == 7
    
    load([gui_dir '\hardware\projector_fit\' fName]);
    
else
    
    errordlg(['Projector registration not detected. Register the projector to the '...
        'camera before running experiments with projector dependency']);
    
end

[cam_yPixels,cam_xPixels]=size(expmt.meta.ref);

if cam_xPixels ~= reg_data.cam_xPixels || cam_yPixels ~= reg_data.cam_yPixels
    
    x_scale = cam_xPixels/reg_data.cam_xPixels;
    y_scale = cam_yPixels/reg_data.cam_yPixels;
    cam_x = reg_data.cam_xCoords*x_scale;
    cam_y = reg_data.cam_yCoords*y_scale;
    
    % Create scattered interpolant for current camera resolution
    expmt.hardware.projector.Fx=scatteredInterpolant(cam_x,cam_y,reg_data.proj_xCoords);
    expmt.hardware.projector.Fy=scatteredInterpolant(cam_x,cam_y,reg_data.proj_yCoords);
    
else
    expmt.hardware.projector.Fx = reg_data.Fx;
    expmt.hardware.projector.Fy = reg_data.Fy;
end
