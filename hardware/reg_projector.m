function reg_projector(camInfo,reg_params,handles)

% This function registers the projector to the camera by rastering the
% projector's space with a circle of radius (r), taking steps of size (stp_sz) in
% pixels with a pause of stp_t in between steps. The camera automatically detects the location of the spot and
% uses camera and projector coordinate pairs for the spot to create
% scattered interpolants of the space in both x (Fx) and y (Fy). The 
% function outputs these interpolants to a file that is subsequently used
% to target specific points in the camera's field of view.

%% Parameters

stp_sz = reg_params.pixel_step_size;
stp_t = reg_params.step_interval;
r = reg_params.spot_r;

%% Estimate camera frame rate

frameRate=estimateFrameRate(camInfo);
stp_t = stp_t*60/frameRate;


%% Initialize the camera with settings tailored to imaging the projector

imaqreset
pause(0.1);
vid=initializeCamera(camInfo);
start(vid);
pause(0.1);

% Initialize the psychtoolbox window and query projector properties
bg_color=[0 0 0];
scrProp=initialize_projector(bg_color);
pause(2);

%% Query cam resolution and collect reference image

ref=peekdata(vid,1);
ref=ref(:,:,2);
imshow(ref-ref);
text(size(ref,2)*0.75,size(ref,1)*0.05,'Registration in progress','fontsize',18,'Color',[1 0 0]);

% Save the camera resolution that the registration was performed at
[reg_yPixels,reg_xPixels] = size(ref);


%% Set registration parameters

xPixels=scrProp.windowRect(3);
yPixels=scrProp.windowRect(4);
x_stp=floor(xPixels/stp_sz);        % num steps in x
y_stp=floor(yPixels/stp_sz);        % num steps in y
white=[1 1 1];                      % color of the spot
im_thresh=30;                       % image threshold
subim_sz=10;                        % Radius of the extracted image ROI
min_area = ((mean(size(ref)))*0.01)^2;
max_area = ((mean(size(ref)))*0.025)^2;

% Initialize cam/projector coord placeholders
cam_x=NaN(y_stp,x_stp);
cam_y=NaN(y_stp,x_stp);
proj_x=NaN(y_stp,x_stp);
proj_y=NaN(y_stp,x_stp);

iTime=NaN(15,1);


%% Registration loop

% Initialize both x and y to zero and raster the projector
x=0;
shg
for i=1:x_stp
    y=0;
    for j=1:y_stp
        tic
        
        % Draw circle with projector at pixel coords x,y
        scrProp=drawCircles(x,y,r,white,scrProp);     
        pause(stp_t);
        
        % Image spot with cam
        im=peekdata(vid,1);
        im=im(:,:,2);
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
            if max(yi)<reg_yPixels+1 && min(yi)>0 && max(xi)<reg_xPixels+1 && min(xi)>1
            subim=im(yi,xi);
            subim=double(subim);
            subim=subim./sum(sum(subim));
            
            % Save camera coordinates of the spot
            cam_x(j,i)=sum(sum(subim).*xi);
            cam_y(j,i)=sum(sum(subim,2).*yi');
            
            % Reset axes and display tracking
            cla reset
            imagesc(im>im_thresh);
            hold on
            plot(cam_x(j,i),cam_y(j,i),'ro');
            text(cam_x(j,i),cam_y(j,i)+20,[num2str(x) ', ' num2str(y)],'fontsize',18,'Color',[1 0 0]);
            text(size(ref,2)*0.75,size(ref,1)*0.05,'Registration in progress','fontsize',18,'Color',[1 0 0]);
            hold off
            set(gca,'Xtick',[],'Ytick',[]);
            drawnow
            end
        else
            imagesc(im>im_thresh);
            hold on
            text(size(ref,2)*0.75,size(ref,1)*0.05,'Registration in progress','fontsize',18,'Color',[1 0 0]);
            hold off
            set(gca,'Xtick',[],'Ytick',[]);
            drawnow
        end
        
        % Save projector coordinates of spot
        proj_x(j,i)=x;
        proj_y(j,i)=y;
        
        % Advance y by stp_sz pixels
        y = y + stp_sz;
        iCount=(i-1)*y_stp+j;
        
        iTime(mod(iCount,length(iTime))+1)=toc;
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

% Image spot with cam
im=peekdata(vid,1);
im=im(:,:,2);
im=im-ref;
imagesc(im>im_thresh);
hold on
text(size(ref,2)*0.75,size(ref,1)*0.05,'Registration finished','fontsize',18,'Color',[1 0 0]);
hold off

% Exclude projector/camera coord pairs where spot was not detected by cam
include=~isnan(cam_x);
proj_x=proj_x(include);
proj_y=proj_y(include);
cam_x=cam_x(include);
cam_y=cam_y(include);

% Create scattered interpolant and save to HDD
Fx=scatteredInterpolant(cam_x,cam_y,proj_x);
Fy=scatteredInterpolant(cam_x,cam_y,proj_y);

reg_data.Fx = Fx;
reg_data.Fy = Fy;
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
    

