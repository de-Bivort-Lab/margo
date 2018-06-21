function projector_testFit(expmt,handles)

% This function displays and records the discrepancy between the current
% projector fit and the camera

%% Parameters

stp_sz = expmt.reg_params.pixel_step_size;
r = expmt.reg_params.spot_r;
screenNumber = expmt.reg_params.screen_num;

%% Estimate camera frame rate

[frameRate, expmt.hardware.cam] = estimateFrameRate(expmt.hardware.cam);


%% Initialize the camera with settings tailored to imaging the projector

if ~isfield(expmt.hardware.cam,'vid') || strcmp(expmt.hardware.cam.vid.Running,'off')
    imaqreset
    pause(0.1);
    expmt.hardware.cam = initializeCamera(expmt.hardware.cam);
    start(expmt.hardware.cam.vid);
    pause(0.1);
end

% Initialize the psychtoolbox window and query projector properties
bg_color=[0 0 0];
scrProp=initialize_projector(screenNumber,bg_color);
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

%% Load the projector fit

load([handles.gui_dir 'hardware\projector_fit\projector_fit.mat']);
[cam_yPixels,cam_xPixels]=size(ref);

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

%% Set test parameters

x_stp=floor(cam_xPixels/stp_sz);        % num steps in x
y_stp=floor(cam_yPixels/stp_sz);        % num steps in y
white=[1 1 1];                      % color of the spot
im_thresh=30;                       % image threshold
subim_sz=10;                        % Radius of the extracted image ROI
min_area = ((mean(size(ref)))*0.01)^2;
max_area = ((mean(size(ref)))*0.05)^2;

% Initialize cam/projector coord placeholders
cam_x=NaN(y_stp,x_stp);
cam_y=NaN(y_stp,x_stp);
proj_x=NaN(y_stp,x_stp);
proj_y=NaN(y_stp,x_stp);

iTime=NaN(15,1);

%% clear axes objects and initialize marker and text objects

clean_gui(handles.axes_handle);
hold on
hTitle = text(handles.axes_handle.XLim(2)*0.05,handles.axes_handle.YLim(2)*0.05,...
    'Registration in progress','fontsize',12,'Color',[1 0 0]);
hMark = plot(0,0,'ro');
hTextx = text(0,0,'','Color',[1 0 1],'fontsize',14);
hTexty = text(0,0,'','Color',[0 1 1],'fontsize',14);
hold off

%% Calculate display delay

% move mouse cursor
robot = java.awt.Robot;
robot.mouseMove(1, 1);    

% cam midpoint                             
mid = expmt.hardware.cam.vid.VideoResolution./2;

% get white reference
Screen('FillRect',scrProp.window,[1 1 1], scrProp.windowRect);
Screen('Flip',scrProp.window);
pause(0.5);
im = peekdata(expmt.hardware.cam.vid,1);
white = double(median(median(im(mid(1)-50:mid(1)+50,mid(2)-50:mid(2)+50,1))));

% black reference
Screen('FillRect',scrProp.window,[0 0 0], scrProp.windowRect);
Screen('Flip',scrProp.window);
pause(0.5);
im = peekdata(expmt.hardware.cam.vid,1);
black = double(median(median(im(mid(1)-50:mid(1)+50,mid(2)-50:mid(2)+50,1))));
not_white = true;  
blank = false;

% fill screen with white
Screen('FillRect',scrProp.window,[1 1 1], scrProp.windowRect);
Screen('Flip',scrProp.window);

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
Screen('FillRect',scrProp.window,[0 0 0], scrProp.windowRect);
Screen('Flip',scrProp.window);

delay = t*1.5;

%% Registration loop

% move mouse cursor
robot = java.awt.Robot;
robot.mouseMove(1, 1); 

% Initialize both x and y to zero and raster the projector
x=0;
shg
tic
tPrev = toc;
for i=1:x_stp
    y=0;
    for j=1:y_stp
        
        tCurr = toc;
        ifi = tCurr-tPrev;
        while ifi < 1/frameRate
            tCurr = toc;
            ifi = tCurr-tPrev;
        end
        tPrev = tCurr;
        
        % Draw circle with projector at pixel coords x,y
        scrProp=drawCircles(Fx(x,y),Fy(x,y),r,white,scrProp);  
        %scrProp.vbl
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
        
        % Extract centroid of spot
        props=regionprops(im>im_thresh,'Centroid','Area');
        props=props([props.Area]>min_area & [props.Area]<max_area);
        
        % Further process the centroid if spot detected
        if ~isempty([props.Centroid]) && length([props.Centroid])==2
            
            % Calculate center of mass using roi detected for the spot
            cenDat=round([props.Centroid]);
            yi=cenDat(2)-subim_sz:cenDat(2)+subim_sz;
            xi=cenDat(1)-subim_sz:cenDat(1)+subim_sz;
            
            if max(yi)<cam_yPixels+1 && min(yi)>0 && max(xi)<cam_xPixels+1 && min(xi)>1
                
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
                hTextx.Position = [cam_x(j,i),cam_y(j,i)+20];
                hTexty.Position = [cam_x(j,i),cam_y(j,i)+40];
                hTextx.String = ['x error: ' num2str(round((cam_x(j,i)-x)*10)/10)];
                hTexty.String = ['y error: ' num2str(round((cam_y(j,i)-y)*10)/10)];
                
                if strcmp(hMark.Visible,'off')
                    hMark.Visible = 'on';
                    hTextx.Visible = 'on';
                    hTexty.Visible = 'on';
                end

                drawnow
                
            end
        else
            handles.hImage.CData = im>im_thresh;
            if strcmp(hMark.Visible,'on')
                hMark.Visible = 'off';
                hTextx.Visible = 'off';
                hTexty.Visible = 'off';
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
                if timeRemaining < 60; 
                    set(handles.edit_time_remaining, 'String', ['00:00:' sprintf('%0.2d',timeRemaining)]);
                    set(handles.edit_time_remaining, 'BackgroundColor', [1 0.4 0.4]);
                elseif (3600 > timeRemaining) && (timeRemaining > 60);
                    minute = floor(timeRemaining/60);
                    sec = rem(timeRemaining, 60);
                    set(handles.edit_time_remaining, 'String', ['00:' sprintf('%0.2d',minute) ':' sprintf('%0.2d',sec)]);
                    set(handles.edit_time_remaining, 'BackgroundColor', [1 1 1]);
                elseif timeRemaining > 3600;
                    hr = floor(timeRemaining/3600);
                    minute = floor(rem(timeRemaining, 3600)/60);
                    sec = timeRemaining - hr*3600 - minute*60;
                    set(handles.edit_time_remaining, 'String', [sprintf('%0.2d', hr) ':' sprintf('%0.2d',minute) ':' sprintf('%0.2d',sec)]);
                    set(handles.edit_time_remaining, 'BackgroundColor', [1 1 1]);
                end
        end

        clearvars im props subim
    end
    
    % Advance x by stp_sz pixels
    x = x + stp_sz;
    
end


% Exclude projector/camera coord pairs where spot was not detected by cam
include=~isnan(cam_x);
proj_x=proj_x(include);
proj_y=proj_y(include);
cam_x=cam_x(include);
cam_y=cam_y(include);

