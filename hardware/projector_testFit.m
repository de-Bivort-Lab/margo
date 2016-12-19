function projector_testFit(camInfo,stp_sz,stp_t,r)

% This function displays and records the discrepancy between the current
% projector fit and the camera

%% Initialize the camera with settings tailored to imaging the projector

imaqreset
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
text(size(ref,2)*0.75,size(ref,1)*0.05,'Registration test in progress','fontsize',18,'Color',[1 0 0]);

%% Load the projector fit

load('C:\Users\debivortlab\Documents\MATLAB\projectorTracker\projector_fit.mat');
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

%% Estimate camera frame rate

frameRate=estimateFrameRate(vid);
stp_t = stp_t*60/frameRate;

%% Set test parameters

x_stp=floor(cam_xPixels/stp_sz);        % num steps in x
y_stp=floor(cam_yPixels/stp_sz);        % num steps in y
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
        scrProp=drawCircles(Fx(x,y),Fy(x,y),r,white,scrProp);     
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
            if max(yi)<cam_yPixels+1 && min(yi)>0 && max(xi)<cam_xPixels+1 && min(xi)>1
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
            text(cam_x(j,i),cam_y(j,i)+10,[num2str(x) ', ' num2str(y)],'fontsize',12,'Color',[1 0 0]);
            text(cam_x(j,i),cam_y(j,i)+20,[num2str(cam_x(j,i)) ', ' num2str(cam_y(j,i))],'fontsize',12,'Color',[0 0 1]);
            text(cam_x(j,i),cam_y(j,i)+30,[num2str(cam_x(j,i)-x) ', ' num2str(cam_y(j,i)-y)],'fontsize',12,'Color',[1 1 0]);
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
        iCount=(i-1)*x_stp+j;
        
        iTime(mod(iCount,length(iTime))+1)=toc;
        if iCount >= length(iTime)
            timeRemaining = round(mean(iTime)*(x_stp*y_stp-iCount));
                if timeRemaining < 60; 
                    set(edit_time_remaining, 'String', ['00:00:' sprintf('%0.2d',timeRemaining)]);
                    set(edit_time_remaining, 'BackgroundColor', [1 0.4 0.4]);
                elseif (3600 > timeRemaining) && (timeRemaining > 60);
                    minute = floor(timeRemaining/60);
                    sec = rem(timeRemaining, 60);
                    set(edit_time_remaining, 'String', ['00:' sprintf('%0.2d',minute) ':' sprintf('%0.2d',sec)]);
                    set(edit_time_remaining, 'BackgroundColor', [1 1 1]);
                elseif timeRemaining > 3600;
                    hr = floor(timeRemaining/3600);
                    minute = floor(rem(timeRemaining, 3600)/60);
                    sec = timeRemaining - hr*3600 - minute*60;
                    set(edit_time_remaining, 'String', [sprintf('%0.2d', hr) ':' sprintf('%0.2d',minute) ':' sprintf('%0.2d',sec)]);
                    set(edit_time_remaining, 'BackgroundColor', [1 1 1]);
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

