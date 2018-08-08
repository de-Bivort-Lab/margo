function projector_grid_register(expmt, handles)


% This function registers the projector to the camera by rastering the
% projector's space with a circle of radius (r), taking steps of size (stp_sz) in
% pixels with a pause of stp_t in between steps. The camera automatically detects the location of the spot and
% uses camera and projector coordinate pairs for the spot to create
% scattered interpolants of the space in both x (Fx) and y (Fy). The 
% function outputs these interpolants to a file that is subsequently used
% to target specific points in the camera's field of view.

%% Parameters

reg_params = expmt.hardware.projector.reg_params;
stp_sz = reg_params.pixel_step_size;
r = reg_params.spot_r;
screenNumber = reg_params.screen_num;

%% Estimate camera frame rate

[frameRate, expmt.hardware.cam] = estimateFrameRate(expmt.hardware.cam);

%% Initialize the camera with settings tailored to imaging the projector

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
xPixels=scr.windowRect(3);
yPixels=scr.windowRect(4);
x_stp=floor(xPixels/stp_sz);        % num steps in x
y_stp=floor(yPixels/stp_sz);        % num steps in y
white=[1 1 1];                      % color of the spot
im_thresh=30;                       % image threshold
subim_sz=10;                        % Radius of the extracted image ROI
min_Area = ((mean(size(ref)))*0.01)^2;
max_Area = ((mean(size(ref)))*0.05)^2;

% Initialize cam/projector coord placeholders
cam_x=NaN(y_stp,x_stp);
cam_y=NaN(y_stp,x_stp);
proj_x=NaN(y_stp,x_stp);
proj_y=NaN(y_stp,x_stp);

iTime=NaN(15,1);

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
blank = false;

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

delay = t*1.5;

%%

handles.hImage = findobj(handles.gui_fig,'-depth',3,'Type','image');


%% Registration loop

% move mouse cursor
robot = java.awt.Robot;
robot.mouseMove(1, 1); 
f = {'Centroid';'Area';'Orientation';'MajorAxisLength';'MinorAxisLength'};

% Initialize both x and y to zero and raster the projector
x=size(ref,2)/2;
y=size(ref,1)/2;
r = [r r*3];
tic
tPrev = toc;
aligned = false;
while ~aligned
        
    tCurr = toc;
    ifi = tCurr-tPrev;
    while ifi < 1/frameRate
        tCurr = toc;
        ifi = tCurr-tPrev;
    end
    tPrev = tCurr;

    % Draw circle with projector at pixel coords x,y
    scr=drawCircles(x,y,r,white,scr);     
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

    im=im-ref;

    % Extract Centroid of spot
    props=regionprops(im>im_thresh, f);
    props=props([props.Area]>min_Area & [props.Area]<max_Area);

    % Further process the Centroid if spot detected
    if ~isempty([props.Centroid]) && length([props.Centroid])==2

        % Calculate center of mass using roi detected for the spot
        cenDat=round([props.Centroid]);
        yi=cenDat(2)-subim_sz:cenDat(2)+subim_sz;
        xi=cenDat(1)-subim_sz:cenDat(1)+subim_sz;
        if max(yi)<reg_yPixels+1 && min(yi)>0 && max(xi)<reg_xPixels+1 && min(xi)>1

            subim=im(yi,xi);
            subim=double(subim);
            subim=subim./sum(sum(subim));

            % Save camera coordinates of the spot
            cam_x(j,i)=sum(sum(subim).*xi);
            cam_y(j,i)=sum(sum(subim,2).*yi');

            % Reset axes and display tracking
            handles.hImage.CData = im>im_thresh;
            hMark.XData = cam_x(j,i);
            hMark.YData = cam_y(j,i);
            hText.Position = [cam_x(j,i),cam_y(j,i)+20];
            hText.String = ['(' num2str(round(cam_x(j,i)*10)/10) ...
                ',' num2str(round(cam_y(j,i)*10)/10) ')'];

            if strcmp(hMark.Visible,'off')
                hMark.Visible = 'on';
                hText.Visible = 'on';
            end

            drawnow
        end
    else
        handles.hImage.CData = im>im_thresh;
        if strcmp(hMark.Visible,'on')
            hMark.Visible = 'off';
            hText.Visible = 'off';
        end
        drawnow
    end

    % Save projector coordinates of spot
    proj_x(j,i)=x;
    proj_y(j,i)=y;

    % Advance y by stp_sz pixels
    y = y + stp_sz;
    iCount=(i-1)*y_stp+j;

    iTime(mod(iCount,length(iTime))+1)=ifi;
    if iCount >= length(iTime)
        timeRemaining = round(mean(iTime)*(x_stp*y_stp-iCount));
        updateTimeString(timeRemaining, handles.edit_time_remaining);
    end
    clearvars im props subim


    % Advance x by stp_sz pixels
    x = x + stp_sz;
    
end
