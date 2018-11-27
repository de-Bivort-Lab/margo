function expmt = initialize_projector(expmt,varargin)


% get default projector settings if none exist
if ~isfield(expmt.hardware.projector,'reg_params') ||...
        isempty(expmt.hardware.projector.reg_params)
    expmt.hardware.projector.reg_params = ...
        registration_parameter_subgui('default_registration_parameters');
end
screen_num = expmt.hardware.projector.reg_params.screen_num;
reg_params = expmt.hardware.projector.reg_params;

background_color = [0 0 0];
if ~isempty(varargin)
    background_color = varargin{1};
end
    

% Clear the workspace
try
    sca;
catch
    errordlg('Projector initialization failed. Psychtoolbox not detected.');
    expmt.meta.finish = false;
    return
end

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

gui_dir = which('margo');
gui_dir = gui_dir(1:strfind(gui_dir,'\gui\'));
fName = 'projector_fit.mat';

if exist([gui_dir 'hardware\projector_fit\'],'dir') == 7 &&...
        exist([gui_dir 'hardware\projector_fit\' fName],'file') == 2
    load([gui_dir '\hardware\projector_fit\' fName]);
else
    return  
end

if ~isfield(reg_params,'reg_fun')
    expmt.meta.finish = false;
    errordlg(['Projector settings not configured. Set projector options' ...
        ' before using.']);
    return
end

im = peekdata(expmt.hardware.cam.vid,1);
[cam_yPixels,cam_xPixels]=size(im);

if cam_xPixels ~= reg_data.cam_xPixels || cam_yPixels ~= reg_data.cam_yPixels
    
    x_scale = cam_xPixels/reg_data.cam_xPixels;
    y_scale = cam_yPixels/reg_data.cam_yPixels;
    cam_x = reg_data.cam_xCoords*x_scale;
    cam_y = reg_data.cam_yCoords*y_scale;
    proj_x = reg_data.proj_xCoords;
    proj_y = reg_data.proj_yCoords;
    
    % Create mapping model for projector to camera
    switch reg_params.reg_fun
        case 'scattered interpolant'
            expmt.hardware.projector.Fx = ...
                scatteredInterpolant(cam_x,cam_y,proj_x);
            expmt.hardware.projector.Fy = ...
                scatteredInterpolant(cam_x,cam_y,proj_y);
        case '2D polynomial'
            [poly_Fx, poly_Fy] = fit_adjust_proj_models(cam_x, cam_y, proj_x, proj_y);
            expmt.hardware.projector.Fx = poly_Fx;
            expmt.hardware.projector.Fy = poly_Fy;
    end
else
    switch reg_params.reg_fun
        case 'scattered interpolant'
            expmt.hardware.projector.Fx = reg_data.interp_Fx;
            expmt.hardware.projector.Fy = reg_data.interp_Fy;
        case '2D polynomial'
            expmt.hardware.projector.Fx = reg_data.poly_Fx;
            expmt.hardware.projector.Fy = reg_data.poly_Fy;
        otherwise
            errordlg(['Projector registration not detected. Register'...
                ' the projector to the camera before running'...
                ' experiments with projector dependency']);
    end
end
