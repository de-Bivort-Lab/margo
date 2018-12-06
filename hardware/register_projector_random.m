function register_projector_random(expmt,handles)

% This function registers the projector to the camera by rastering the
% projector's space with a circle of radius (r), taking steps of size (stp_sz) in
% pixels with a pause of stp_t in between steps. The camera automatically detects the location of the spot and
% uses camera and projector coordinate pairs for the spot to create
% scattered interpolants of the space in both x (Fx) and y (Fy). The 
% function outputs these interpolants to a file that is subsequently used
% to target specific points in the camera's field of view.

% Parameters
reg_params = expmt.hardware.projector.reg_params;
r = reg_params.spot_r;

% Estimate camera frame rate
[frameRate, expmt.hardware.cam] = estimateFrameRate(expmt.hardware.cam);

%% Initialize the camera with settings tailored to imaging the projector

% move mouse cursor
robot = java.awt.Robot;
robot.mouseMove(1, 1); 

if ~isfield(expmt.hardware.cam,'vid') || ...
        strcmp(expmt.hardware.cam.vid.Running,'off')
    imaqreset
    pause(0.1);
    expmt.hardware.cam = initializeCamera(expmt.hardware.cam);
    start(expmt.hardware.cam.vid);
    pause(0.1);
end

% Initialize the psychtoolbox window and query projector properties
bg_color=[0 0 0];
expmt = initialize_projector(expmt,bg_color);
pause(2);

%% Query cam resolution and collect reference image

% move mouse cursor
robot = java.awt.Robot;
robot.mouseMove(1, 1); 

% Image spot with cam
ref=peekdata(expmt.hardware.cam.vid,1);
if size(ref,3)>1
    ref=ref(:,:,2);
end

% adjust image for lens distortion if camera calibration parameters exist
if isfield(expmt.hardware.cam,'calibration') && expmt.hardware.cam.calibrate
    [ref,~] = undistortImage(ref,expmt.hardware.cam.calibration);
end

% Save the camera resolution that the registration was performed at
[reg_yPixels,reg_xPixels] = size(ref);


%% Set registration parameters

scr = expmt.hardware.screen;
x_stp = 20;
im_thresh=13;                       % image threshold
min_Area = ceil(((mean(size(ref)))*0.001)^2);
max_Area = floor((mean(size(ref)))*0.05)^2;

% Initialize cam/projector coord placeholders
cam_x=[];
cam_y=[];
proj_x=[];
proj_y=[];

%% Calculate display delay

% move mouse cursor
robot = java.awt.Robot;
robot.mouseMove(1, 1);    

% cam midpoint                             
mid = expmt.hardware.cam.vid.VideoResolution./2;

% get white reference
Screen('FillRect',scr.window,[1 1 1], scr.windowRect);
Screen('Flip',scr.window);
pause(0.5);
im = peekdata(expmt.hardware.cam.vid,1);
white = double(median(median(im(mid(1)-50:mid(1)+50,mid(2)-50:mid(2)+50,1))));

% black reference
Screen('FillRect',scr.window,[0 0 0], scr.windowRect);
Screen('Flip',scr.window);
pause(0.5);
im = peekdata(expmt.hardware.cam.vid,1);
black = double(median(median(im(mid(1)-50:mid(1)+50,mid(2)-50:mid(2)+50,1))));
not_white = true;  

% fill screen with white
Screen('FillRect',scr.window,[1 1 1], scr.windowRect);
Screen('Flip',scr.window);

% initialize time stamps
t = 0;
tic;
tPrev = toc;

while not_white
    
    tCurr = toc;
    t = t + tCurr - tPrev;
    tPrev = tCurr;
    im = peekdata(expmt.hardware.cam.vid,1);
    lum = double(median(median(im(mid(1)-50:mid(1)+50,mid(2)-50:mid(2)+50,1))));
    not_white = abs(lum - black) < abs(lum - white);
    
end

% black reference
Screen('FillRect',scr.window,[0 0 0], scr.windowRect);
Screen('Flip',scr.window);

delay = t*2;

%% clear axes objects and initialize marker and text objects

clean_gui(handles.axes_handle);

handles.hImage = findobj(handles.gui_fig,'-depth',3,'Type','image');


%% Registration loop

% move mouse cursor
robot = java.awt.Robot;
robot.mouseMove(1, 1); 

% Initialize both x and y to zero and raster the projector
tic
tPrev = toc;
for i=1:x_stp
     
    % delay imaging to match frame rate of the camera
    tCurr = toc;
    ifi = tCurr-tPrev;
    while ifi < 1/frameRate
        tCurr = toc;
        ifi = tCurr-tPrev;
    end
    tPrev = tCurr;

    % Draw circle with projector at pixel coords x,y
    centers = random_dots(scr.windowRect(3), scr.windowRect(4), 700, r);
    scr=drawCircles(centers(:,1),centers(:,2),r,[1,1,1],scr);  
    
    % pause before imaging to account for lag between projector
    % and camera
    pause(delay);

    % Image spot with cam
    im=peekdata(expmt.hardware.cam.vid,1);
    if size(im,3)>1
        im=im(:,:,2);
    end

    % adjust image for lens distortion if camera calibration parameters exist
    if isfield(expmt.hardware.cam,'calibration') && expmt.hardware.cam.calibrate
        [im,~] = undistortImage(im,expmt.hardware.cam.calibration);
    end

    % extract blobs from image
    diffim=im-ref;
    props = regionprops(diffim>im_thresh,diffim,'WeightedCentroid','Area');
    
    % threshold blobs by area
    area = cat(1,props.Area);
    below_min = area  < min_Area;
    above_max = area > max_Area;
    oob = below_min | above_max;
    props(oob) = [];
    
    % get centroid coords
    cenDat = cat(1,props.WeightedCentroid);

    % Further process the Centroid if spot detected
    if ~isempty(cenDat)

        tform_centers = cpd_margo(cenDat,centers);

        tmp.cen = cenDat;
        tmp.t = zeros(size(cenDat,1),1);
        tmp.speed = NaN(numel(tmp.t));
        [~, bp, tmp, updated] = sortROI_multitrack_proj(tmp, tform_centers, 1, 100);


        % Save camera coordinates of the spot
        cam_x = [cam_x; cenDat(updated,1)];
        cam_y = [cam_y; cenDat(updated,2)];
        proj_x = [proj_x; centers(bp,1)];
        proj_y = [proj_y; centers(bp,2)];

    end
    
    % update display
    handles.hImage.CData = im>im_thresh;
    drawnow

    clearvars im props subim
    
end

% Image spot with cam
hTitle.String = 'Registration complete';

% Exclude projector/camera coord pairs where spot was not detected by cam
include=~isnan(cam_x);
proj_x=proj_x(include);
proj_y=proj_y(include);
cam_x=cam_x(include);
cam_y=cam_y(include);

% Create scattered interpolant and save to HDD
interp_Fx=scatteredInterpolant(cam_x,cam_y,proj_x);
interp_Fy=scatteredInterpolant(cam_x,cam_y,proj_y);

[poly_Fx, poly_Fy] = fit_adjust_proj_models(cam_x, cam_y, proj_x, proj_y);

reg_data.interp_Fx = interp_Fx;
reg_data.interp_Fy = interp_Fy;
reg_data.poly_Fx = poly_Fx;
reg_data.poly_Fy = poly_Fy;
reg_data.cam_xPixels = reg_xPixels;
reg_data.cam_yPixels = reg_yPixels;
reg_data.cam_xCoords = cam_x;
reg_data.cam_yCoords = cam_y;
reg_data.proj_xCoords = proj_x;
reg_data.proj_yCoords = proj_y;

if exist([handles.gui_dir 'hardware\projector_fit\'])
    save([handles.gui_dir 'hardware\projector_fit\projector_fit.mat'],'reg_data');
else
    mkdir([handles.gui_dir 'hardware\projector_fit\']);
    save([handles.gui_dir 'hardware\projector_fit\projector_fit.mat'],'reg_data');
end

% close open projector window
sca
    

