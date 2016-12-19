clearvars -except handles
colormap('gray')

%% Set MATLAB to High Priority via Windows Command Line
cmd_str = 'wmic process where name="MATLAB.exe" CALL setpriority 128';
[~,~] = system(cmd_str);

%% Define parameters - adjust parameters here to fix tracking and ROI segmentation errors

% Experimental parameters
exp_duration=handles.exp_duration;
exp_duration=exp_duration*60;
referenceStackSize=handles.ref_stack_size;                  % Number of images to keep in rolling reference
referenceFreq=handles.ref_freq;                             % Seconds between reference images
referenceTime = 60;                                         % Seconds over which intial reference images are taken

% Tracking parameters
imageThresh=get(handles.threshold_slider,'value');          % Difference image threshold for detecting centroids
speedThresh=80;                                             % Maximum allow pixel speed (px/s);

% ROI detection parameters
ROI_thresh=get(handles.threshold_slider,'value')/255;       % Binary image threshold from zero (black) to one (white) for segmentation  
sigma=0.47;                                                 % Sigma expressed as a fraction of the image height
gaussWeight=0.34;                                           % Scalar weighting of gaussian vignette correction when applied to the image

% Phototactic stimulus parameters
stim_duration=handles.exp_parameters.stim_duration*60;         % duration of the stimulus per trial (min)
stim_divider_size=handles.exp_parameters.divider_size;      % width of the gray divider line (expressed as fraction of the diameter);

%% Save labels and create placeholder files for data

t = datestr(clock,'mm-dd-yyyy-HH-MM-SS_');
labels = cell2table(labelMaker(handles.labels),'VariableNames',{'Strain' 'Sex' 'Treatment' 'ID' 'Day'});
strain=labels{1,1}{:};
treatment=labels{1,3}{:};
labelID = [handles.fpath '\' t strain '_' treatment '_labels.dat'];     % File ID for label data
writetable(labels, labelID);

% Create placeholder files
cenID = [handles.fpath '\' t strain '_' treatment '_Centroid.dat'];            % File ID for centroid data
oriID = [handles.fpath '\' t strain '_' treatment '_Orientation.dat'];         % File ID for turn data
stimID = [handles.fpath '\' t strain '_' treatment '_StimStatus.dat'];         % File ID for stimulus state
texID = [handles.fpath '\' t strain '_' treatment '_StimTexture.dat'];         % File ID for stimulus state
 
dlmwrite(cenID, []);                          % create placeholder ASCII file
dlmwrite(oriID, []);                         % create placeholder ASCII file
dlmwrite(stimID, []);                         % create placeholder ASCII file
dlmwrite(texID, []);                         % create placeholder ASCII file

%% Setup the camera and video object
imaqreset
pause(0.5);
% Camera mode set to 8-bit with 664x524 resolution
vid = initializeCamera(handles.camInfo);
start(vid);
pause(0.5);

%% Grab image for ROI detection and segment out ROIs
stop=get(handles.accept_thresh_pushbutton,'value');

while stop~=1;
tic
stop=get(handles.accept_thresh_pushbutton,'value');

% Take single frame
imagedata=peekdata(vid,1);
% Extract red channel
grayscale_im=imagedata(:,:,2);

% Update threshold value
ROI_thresh=get(handles.threshold_slider,'value')/255;

% Build a kernel to smooth vignetting
gaussianKernel=buildGaussianKernel(size(grayscale_im,2),size(grayscale_im,1),sigma,gaussWeight);
grayscale_im=(uint8(double(grayscale_im).*gaussianKernel));

% Extract ROIs from thresholded image
[ROI_bounds,ROI_coords,ROI_widths,ROI_heights,binaryimage] = detect_ROIs(grayscale_im,ROI_thresh);

% Create orientation vector for mazes (upside down Y = 0, right-side up = 1)
mazeOri=logical(zeros(size(ROI_coords,1),1));

% Calculate coords of ROI centers
[xCenters,yCenters]=ROIcenters(grayscale_im,binaryimage,ROI_coords);
centers=[xCenters,yCenters];

% Define a permutation vector to sort ROIs from top-right to bottom left
[ROI_coords,mazeOri,ROI_bounds,centers]=sortROIs(ROI_coords,mazeOri,centers,ROI_bounds);


    cla reset
    imagesc(binaryimage);
    hold on
    for i = 1:size(ROI_coords,1)
        rectangle('Position',ROI_bounds(i,:),'EdgeColor','r')
        if mazeOri(i)
            text(centers(i,1)-5,centers(i,2),int2str(i),'Color','m')
        else
            text(centers(i,1)-5,centers(i,2),int2str(i),'Color','b')
        end
    end
    hold off
    drawnow


    
set(handles.edit_frame_rate,'String',num2str(round(1/toc)));
end

% Reset the accept threshold button
set(handles.accept_thresh_pushbutton,'value',0);


%% Initialize the psychtoolbox window and query projector properties
bg_color=[0 0 0];          
scrProp=initialize_projector(bg_color);
pause(1);

%% Automatically average out flies from reference image

refImage=imagedata(:,:,2);                              % Assign reference image
refStack=repmat(refImage,1,1,referenceStackSize);       % Initialize reference stack
lastCentroid=centers;                                   % Create placeholder for most recent non-NaN centroids
referenceCentroids=zeros(size(ROI_coords,1),2,referenceStackSize);      % Create placeholder for cen. coords when references are taken
propFields={'Centroid';'Area';'Orientation'};           % Define fields for regionprops
nRefs=zeros(size(ROI_coords,1),1);                      % Reference number placeholder
numbers=1:size(ROI_coords,1);                           % Numbers to display while tracking
centStamp=zeros(size(ROI_coords,1),1);
vignetteMat=filterVignetting(refImage,binaryimage,ROI_coords);

% Set maximum allowable distance to center of ROI as the long axis of the
% ROI + some error
w=median(ROI_bounds(:,3));
h=median(ROI_bounds(:,4));
distanceThresh=mean(mean(([w h])))/2;  

%title('Reference Acquisition In Progress - Press any key to continue')
shg

% Time stamp placeholders
tElapsed=0;
tic
previous_tStamp=toc;
current_tStamp=0;

% Collect reference until timeout OR "accept reference" GUI press
while toc<referenceTime&&get(handles.accept_thresh_pushbutton,'value')~=1
    
    % Update image threshold value from GUI
    imageThresh=get(handles.threshold_slider,'value');
    
    % Update tStamps
    current_tStamp=toc;
    set(handles.edit_frame_rate,'String',num2str(round(1/toc)));
    tElapsed=tElapsed+current_tStamp-previous_tStamp;
    previous_tStamp=current_tStamp;
    
        % Report time remaining to reference timeout to GUI
        timeRemaining = round(referenceTime - toc);
        if timeRemaining < 60; 
            set(handles.edit_time_remaining, 'String', ['00:00:' sprintf('%0.2d',timeRemaining)]);
            set(handles.edit_time_remaining, 'BackgroundColor', [1 0.4 0.4]);
        elseif (3600 > timeRemaining) && (timeRemaining > 60);
            min = floor(timeRemaining/60);
            sec = rem(timeRemaining, 60);
            set(handles.edit_time_remaining, 'String', ['00:' sprintf('%0.2d',min) ':' sprintf('%0.2d',sec)]);
            set(handles.edit_time_remaining, 'BackgroundColor', [1 1 1]);
        elseif timeRemaining > 3600;
            hr = floor(timeRemaining/3600);
            min = floor(rem(timeRemaining, 3600)/60);
            sec = timeRemaining - hr*3600 - min*60;
            set(handles.edit_time_remaining, 'String', [sprintf('%0.2d', hr) ':' sprintf('%0.2d',min) ':' sprintf('%0.2d',sec)]);
            set(handles.edit_time_remaining, 'BackgroundColor', [1 1 1]);
        end
        
        % Take difference image
        imagedata=peekdata(vid,1);
        imagedata=imagedata(:,:,2);
        subtractedData=(refImage-vignetteMat)-(imagedata-vignetteMat);

        % Extract regionprops and record centroid for blobs with (11 > area > 30) pixels
        props=regionprops((subtractedData>imageThresh),propFields);
        validCentroids=([props.Area]>4&[props.Area]<120);
        cenDat=reshape([props(validCentroids).Centroid],2,length([props(validCentroids).Centroid])/2)';

        % Match centroids to ROIs by finding nearest ROI center
        [cen_permutation,update_centroid]=matchCentroids2ROIs(cenDat,lastCentroid,centers,distanceThresh);

        % Apply speed threshold to centroid tracking
        if any(update_centroid)
        d = sqrt([cenDat(cen_permutation,1)-lastCentroid(update_centroid,1)].^2 + [cenDat(cen_permutation,2)-lastCentroid(update_centroid,2)].^2);
        dt = tElapsed-centStamp(update_centroid);
        speed = d./dt;
        above_spd_thresh = speed > speedThresh;
        cen_permutation(above_spd_thresh)=[];
        update_centroid=find(update_centroid);
        update_centroid(above_spd_thresh)=[];
        end

        % Use permutation vector to sort raw centroid data and update
        % vector to specify which centroids are reliable and should be updated
        lastCentroid(update_centroid,:)=cenDat(cen_permutation,:);
            
        % Step through each ROI one-by-one
        for i=1:size(ROI_coords,1)

        % Calculate distance to previous locations where references were taken
        tCen=repmat(lastCentroid(i,:),size(referenceCentroids,3),1);
        d=abs(sqrt(dot((tCen-squeeze(referenceCentroids(i,:,:))'),(squeeze(referenceCentroids(i,:,:))'-tCen),2)));

            % Create a new reference image for the ROI if fly is greater than distance thresh
            % from previous reference locations
            if sum(d<10)==0&&sum(isnan(lastCentroid(i,:)))==0
                nRefs(i)=nRefs(i)+1;
                referenceCentroids(i,:,mod(nRefs(i),referenceStackSize)+1)=lastCentroid(i,:);
                newRef=imagedata(ROI_coords(i,2):ROI_coords(i,4),ROI_coords(i,1):ROI_coords(i,3));
                refStack(ROI_coords(i,2):ROI_coords(i,4),ROI_coords(i,1):ROI_coords(i,3),mod(nRefs(i),referenceStackSize)+1)=newRef;
            end
        end
        
        % Update median ref
        refImage = median(refStack,3);
        
       % Check "Display ON" toggle button from GUI 

           % Update the plot with new reference
           cla reset
           imagesc(subtractedData>imageThresh);

           % Draw last known centroid for each ROI and update ref. number indicator
           hold on
           for i=1:size(ROI_coords,1)
               color=[(1/nRefs(i)) 0 (1-1/nRefs(i))];
               color(color>1)=1;
               color(color<0)=0;
               plot(ROI_coords(i,1),ROI_coords(i,2),'o','Linew',3,'Color',color);      
               text(ROI_coords(i,1),ROI_coords(i,2)+15,int2str(numbers(i)),'Color','m')
               text(lastCentroid(i,1),lastCentroid(i,2),int2str(numbers(i)),'Color','R')
           end
       hold off
       set(gca,'Xtick',[],'Ytick',[]);
       drawnow

end

% Update vignette offset matrix with better reference
vignetteMat=filterVignetting(refImage,binaryimage,ROI_coords);

% Reset accept reference button
set(handles.accept_thresh_pushbutton,'value',0);

% Recalculate coords of ROI centers
[xCenters,yCenters]=ROIcenters(refImage,binaryimage,ROI_coords);
centers=[xCenters,yCenters];

% Define a permutation vector to sort ROIs from top-right to bottom left
[ROI_coords,mazeOri,ROI_bounds,centers]=sortROIs(ROI_coords,mazeOri,centers,ROI_bounds);


%% Display tracking to screen for tracking errors


ct=1;                               % Frame counter
pixDistSize=100;                    % Num values to record in p
pixelDist=NaN(pixDistSize,1);       % Distribution of total number of pixels above image threshold
tElapsed=0;

tic   
while ct<pixDistSize;
        
        % Grab image thresh from GUI slider
        imageThresh=get(handles.threshold_slider,'value');

        % Update time stamps
        current_tStamp=toc;
        tElapsed=tElapsed+current_tStamp-previous_tStamp;
        set(handles.edit_frame_rate,'String',num2str(round(1/(current_tStamp-previous_tStamp))));
        previous_tStamp=current_tStamp;

            timeRemaining = round(referenceTime - toc);
                
                %set(handles.edit10, 'String', num2str(pixDistSize-ct));

               % Get centroids and sort to ROIs
               imagedata=peekdata(vid,1);
               imagedata=imagedata(:,:,2);
               imagedata=(refImage-vignetteMat)-(imagedata-vignetteMat);
               props=regionprops((imagedata>imageThresh),propFields);

               % Match centroids to ROIs by finding nearest ROI center
               validCentroids=([props.Area]>4&[props.Area]<120);
               cenDat=reshape([props(validCentroids).Centroid],2,length([props(validCentroids).Centroid])/2)';
               
                % Match centroids to last known centroid positions
                [cen_permutation,update_centroid]=matchCentroids2ROIs(cenDat,lastCentroid,centers,distanceThresh);

                % Apply speed threshold to centroid tracking
                if any(update_centroid)
                d = sqrt([cenDat(cen_permutation,1)-lastCentroid(update_centroid,1)].^2 + [cenDat(cen_permutation,2)-lastCentroid(update_centroid,2)].^2);
                dt = tElapsed-centStamp(update_centroid);
                speed = d./dt;
                above_spd_thresh = speed > speedThresh;
                cen_permutation(above_spd_thresh)=[];
                update_centroid=find(update_centroid);
                update_centroid(above_spd_thresh)=[];
                end

                % Use permutation vector to sort raw centroid data and update
                % vector to specify which centroids are reliable and should be updated
                lastCentroid(update_centroid,:)=cenDat(cen_permutation,:);
                
               %Update display if display tracking is ON
               imshow(imagedata>imageThresh);
               hold on
               % Mark centroids
               plot(lastCentroid(:,1),lastCentroid(:,2),'o','Color','r');
               hold off
               set(gca,'Xtick',[],'Ytick',[]);
               drawnow

               
           % Create distribution for num pixels above imageThresh
           % Image statistics used later during acquisition to detect noise
           pixelDist(mod(ct,pixDistSize)+1)=nansum(nansum(imagedata>imageThresh));
           ct=ct+1;
   
end

% Record stdDev and mean without noise
pixStd=nanstd(pixelDist);
pixMean=nanmean(pixelDist);    

w=ROI_bounds(:,3);
h=ROI_bounds(:,4);


%% Set experiment parameters
exp_duration=exp_duration*60;                   
referenceFreq = referenceFreq;                   
refStack=repmat(refImage,1,1,referenceStackSize);   % Create placeholder for 5-image rolling reference.
refCount=0;
aboveThresh=ones(10,1)*pixMean;                      % Num pixels above threshold last 5 frames
pixDev=ones(10,1);                                   % Num Std. of aboveThresh from mean
noiseCt=1;
ct=1;                                               % Frame counter
tempCount=1;
previous_tStamp=0;
tElapsed=0;
centStamp=zeros(size(ROI_coords,1),1);
turntStamp=zeros(size(ROI_coords,1),1);

previous_refUpdater=0;                          % Compared to current_refUpdater to update the reference at correct freq.
write=logical(0);                               % Data written to hard drive when true

display=logical(1);                             % Updates display every 2s when true
mazes=1:size(ROI_coords,1);
previous_arm=zeros(size(ROI_coords,1),1);

%% Load the projector fit

load('C:\Users\debivortlab\Documents\MATLAB\projectorTracker\projector_fit.mat');
[cam_yPixels,cam_xPixels]=size(refImage);

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

%% Calculate ROI coords in the projector space and expand the edges by a small border to ensure ROI is fully covered

stim_coords=NaN(size(ROI_coords));
stim_coords(:,1)=Fx(ROI_coords(:,1),ROI_coords(:,2));
stim_coords(:,2)=Fy(ROI_coords(:,1),ROI_coords(:,2));
stim_coords(:,3)=Fx(ROI_coords(:,3),ROI_coords(:,4));
stim_coords(:,4)=Fy(ROI_coords(:,3),ROI_coords(:,4));
stim_bounds_buffer=nanmean([stim_coords(:,3)-stim_coords(:,1) stim_coords(:,4)-stim_coords(:,2)],2)*0.05;
stim_coords(:,[1 3])=[stim_coords(:,1)-stim_bounds_buffer stim_coords(:,3)+stim_bounds_buffer];
stim_coords(:,[2 4])=[stim_coords(:,2)-stim_bounds_buffer stim_coords(:,4)+stim_bounds_buffer];
stim_centers=NaN(size(centers));
stim_centers(:,1)=Fx(centers(:,1),centers(:,2));
stim_centers(:,2)=Fy(centers(:,1),centers(:,2));

%% Pre-allocate stimulus image for texture making

% Determine stimulus size by calculating mean ROI edge length
stim_size=round(nanmean(nanmean([stim_coords(:,3)-stim_coords(:,1) stim_coords(:,4)-stim_coords(:,2)])));
src_edge_length = stim_size;
stim_size=sqrt(stim_size^2+stim_size^2);

% Initialize the stimulus image
contrast = handles.exp_parameters.stim_contrast;
photo_stim=initialize_photo_stim(ceil(stim_size),ceil(stim_size),stim_divider_size,contrast);
imcenter=[size(photo_stim,1)/2+0.5 size(photo_stim,2)/2+0.5];

% Initialize source rect and scaling factors
base_srcRect=[0 0 src_edge_length src_edge_length];
srcRect=CenterRectOnPointd(base_srcRect,stim_size/2,stim_size/2);

%% Run Experiment

clearvars numbers oldRef grayscale_im subtractedData
photo_stimTex = Screen('MakeTexture', scrProp.window, photo_stim);
blank_stim = zeros(size(photo_stim));
blank_stimTex = Screen('MakeTexture', scrProp.window, blank_stim);

tic
shg
delay=0.0001;
pt=0; % Initialize pause time
stim_tStamp=0;
stim_count=0;                                        % Counter for number of looming stim displayed each stimulation period
stim_angles=zeros(size(ROI_coords,1),1);             % Initialize stimulus starting angle to 0
lastOrientation=NaN(size(ROI_coords,1),1);
stim_ct=0;
rot_dir = boolean(ones(size(ROI_coords,1),1));       % Direction of rotation for the photo_stim
active_tex = boolean(1);                                      % active texture (blank or photo_stim)
disp_tStamp = 0;
exp_start=boolean(1);

while toc < exp_duration
    
        % Grab new time stamp
        current_tStamp = toc-pt;
        ifi=current_tStamp-previous_tStamp;
        tElapsed=tElapsed+ifi;
        set(handles.edit_frame_rate,'String',num2str(round(1/(current_tStamp-previous_tStamp))));
        previous_tStamp=current_tStamp;
        ct=ct+1;
        tempCount=tempCount+1;

        % Get framerate delay to slow acquisition
        %delay=str2double(get(handles.edit9,'String'));
        %delay=delay/1000;
        %pause(delay);
    
        % Update clock in the GUI
        timeRemaining = round(exp_duration - toc);
        if timeRemaining < 60; 
            set(handles.edit_time_remaining, 'String', ['00:00:' sprintf('%0.2d',timeRemaining)]);
            set(handles.edit_time_remaining, 'BackgroundColor', [1 0.4 0.4]);
        elseif (3600 > timeRemaining) && (timeRemaining > 60);
            min = floor(timeRemaining/60);
            sec = rem(timeRemaining, 60);
            set(handles.edit_time_remaining, 'String', ['00:' sprintf('%0.2d',min) ':' sprintf('%0.2d',sec)]);
            set(handles.edit_time_remaining, 'BackgroundColor', [1 1 1]);
        elseif timeRemaining > 3600;
            hr = floor(timeRemaining/3600);
            min = floor(rem(timeRemaining, 3600)/60);
            sec = timeRemaining - hr*3600 - min*60;
            set(handles.edit_time_remaining, 'String', [sprintf('%0.2d', hr) ':' sprintf('%0.2d',min) ':' sprintf('%0.2d',sec)]);
            set(handles.edit_time_remaining, 'BackgroundColor', [1 1 1]);
        end

        
        % Capture frame and extract centroid
        imagedata=peekdata(vid,1);
        imagedata=imagedata(:,:,2);
        diffImage=(refImage-vignetteMat)-(imagedata-vignetteMat);
        props=regionprops((diffImage>imageThresh),propFields);
        
        % update reference image and ROI_positions at the reference frequency and print time remaining 
        current_refUpdater=mod(toc,referenceFreq);
        aboveThresh(mod(ct,10)+1)=sum(sum(diffImage>imageThresh));
        pixDev(mod(ct,10)+1)=(nanmean(aboveThresh)-pixMean)/pixStd;
        
        % Only gather centroids and record turns if noise is below
        % threshold
        if pixDev(mod(ct,10)+1)<8

            % Match centroids to ROIs by finding nearest ROI center
            validCentroids=([props.Area]>4&[props.Area]<120);
            cenDat=reshape([props(validCentroids).Centroid],2,length([props(validCentroids).Centroid])/2)';
            oriDat=[props(validCentroids).Orientation];

            [cen_permutation,update_centroid]=matchCentroids2ROIs(cenDat,lastCentroid,centers,distanceThresh);

            % Apply speed threshold to centroid tracking
            if any(update_centroid)
            d = sqrt([cenDat(cen_permutation,1)-lastCentroid(update_centroid,1)].^2 + [cenDat(cen_permutation,2)-lastCentroid(update_centroid,2)].^2);
            dt = tElapsed-centStamp(update_centroid);
            spd = d./dt;
            above_spd_thresh = spd > speedThresh;
            cen_permutation(above_spd_thresh)=[];
            update_centroid=find(update_centroid);
            update_centroid(above_spd_thresh)=[];
            

            % Use permutation vector to sort raw centroid data and update
            % vector to specify which centroids are reliable and should be updated
            lastCentroid(update_centroid,:)=cenDat(cen_permutation,:);
            lastOrientation(update_centroid)=oriDat(cen_permutation);
            centStamp(update_centroid)=tElapsed;
            speed = zeros(1,size(ROI_coords,1));
            speed(update_centroid)=spd(~above_spd_thresh);
            
            end
            
            % Write data to the hard drive
            dlmwrite(cenID, [[ct;ifi] lastCentroid'], '-append');
            dlmwrite(oriID, lastOrientation', '-append');
            dlmwrite(stimID, stim_angles, '-append');
            dlmwrite(texID, active_tex, '-append');
            
        end
        
      
        % Update the stimuli and trigger new stimulation period if stim
        % time is exceeded
        if stim_tStamp+stim_duration < tElapsed || exp_start
            
            exp_start = boolean(0);
            active_tex = ~active_tex;     % Alternate between baseline and stimulation periods
            
            stim_tStamp=tElapsed;         % Record the time of new stimulation period
            
            % convert current fly position to stimulus coords
            proj_centroid=NaN(size(ROI_coords,1),2);
            proj_centroid(:,1)=Fx(lastCentroid(:,1),lastCentroid(:,2));
            proj_centroid(:,2)=Fy(lastCentroid(:,1),lastCentroid(:,2));
            
            % determine which half of the arena is l
            
            % Find the angle between stim_centers and proj_cen and the horizontal axis.
            stim_angles = atan2(proj_centroid(:,2)-stim_centers(:,2),proj_centroid(:,1)-stim_centers(:,1)).*180./pi;
            
            % Rotate stim image and generate stim texture
            rot_dir = rand(size(ROI_coords,1),1)>0.5;
            stim_angles(rot_dir) = stim_angles(rot_dir)+180;
            
            if active_tex
                % Pass photo stimulation textures to screen
                Screen('DrawTextures', scrProp.window, photo_stimTex, srcRect', stim_coords', stim_angles,...
                [], [], [],[], []);
            else
                % Pass blank textures to screen
                Screen('DrawTextures', scrProp.window, blank_stimTex, srcRect', stim_coords', stim_angles,...
                [], [], [],[], []);
            end
            % Flip to the screen
            scrProp.vbl = Screen('Flip', scrProp.window, scrProp.vbl + (scrProp.waitframes - 0.5) * scrProp.ifi);
        end
        
        
        
        % Update the display if the stimulus is not on
        if disp_tStamp + 0.5 < tElapsed
            
           proj_x = Fx(lastCentroid(:,1),lastCentroid(:,2));
           proj_y = Fy(lastCentroid(:,1),lastCentroid(:,2));
           [div_dist,lightStat] = parseShadeLight(stim_angles,proj_x,proj_y,stim_centers,1);
           div_dist=round(div_dist.*100)./100;
            
           disp_tStamp = tElapsed;
           cla reset
           imagesc((imagedata-vignetteMat));
           hold on
           plot(lastCentroid(:,1),lastCentroid(:,2),'o','Color','r');
           for i=1:48
            text(lastCentroid(i,1),lastCentroid(i,2)+8,num2str(lightStat(i)),'Color',[1 0 0]);
            text(lastCentroid(i,1),lastCentroid(i,2)+16,num2str(div_dist(i)),'Color',[0 0 1]);
           end
           hold off
           set(gca,'Xtick',[],'Ytick',[]);
           drawnow
        end 


        % Display current noise level once/sec
        if mod(ct,round(60/delay))==0
            currentDev=mean(pixDev);
        end
        
        % If noise in the image goes more than 6 std above mean, wipe the
        % old references and create new ones            

        if current_refUpdater<previous_refUpdater||mean(pixDev)>8
            
            % If noise is above threshold: reset reference stack,
            % aboveThresh, and pixDev
            % Otherwise, just update the stack with a new reference
            if mean(pixDev)>10
               refStack=repmat(imagedata,1,1,referenceStackSize);
               refImage=uint8(mean(refStack,3));
               aboveThresh=ones(10,1)*pixMean;
               pixDev=ones(10,1);
               disp('NOISE THRESHOLD REACHED, REFERENCES RESET')
            else
               % Update reference
               refCount=refCount+1;
               refStack(:,:,mod(refCount,referenceStackSize)+1)=imagedata;
               refImage=uint8(mean(refStack,3));
               % Update vignette offset matrix with better reference
               vignetteMat=filterVignetting(refImage,binaryimage,ROI_coords);
            end         
        end 
        previous_refUpdater=current_refUpdater;
        
        clearvars imagedata cenDat pos_rotim neg_rotim moving in_center interval_exceeded r props diffImage...
            src_rects proj_centroid
        
end

clearvars min refImage refStack

%% Pull in ASCII data, format into matrices
disp('Experiment Complete')
disp('Importing Data - may take a few minutes...')
flyTracks=[];
flyTracks.exp='Slow Phototaxis';
flyTracks.ROI_coords=ROI_coords;
flyTracks.ROIcenters=centers;
flyTracks.nFlies = size(ROI_coords,1);
flyTracks.mazeOri=mazeOri;
flyTracks.labels = readtable(labelID);
flyTracks.filePath=cenID(1:end-12);

tmp = dlmread(cenID);
flyTracks.tStamps=tmp(mod(1:size(tmp,1),2)==0,1);
flyTracks.tStamps(flyTracks.tStamps<0)=0;
tmp(:,1)=[];
centroid=NaN(size(tmp,1)/2,2,flyTracks.nFlies);
xCen=tmp(mod(1:size(tmp,1),2)==1,:);
yCen=tmp(mod(1:size(tmp,1),2)==0,:);
clearvars tmp

% Reshape centroid data
centroid(:,1,:)=xCen;
centroid(:,2,:)=yCen;
clearvars xCen yCen

% Create tmp holder for handedness processing
tmpCen=NaN(size(centroid,1),2*flyTracks.nFlies);
tmpCen(:,mod(1:size(tmpCen,2),2)==1)=centroid(:,1,:);
tmpCen(:,mod(1:size(tmpCen,2),2)==0)=centroid(:,2,:);

% Save temp struct and process centroid data
flyTracks.centroid=centroid;
clearvars centroid tmp xCen yCen
save(strcat(handles.fpath,'\',t,'.mat'),'flyTracks');
tmpCen=[flyTracks.tStamps tmpCen];
cData = processCentroid(tmpCen,flyTracks.nFlies,flyTracks.ROI_coords);
flyCircles = avgAngle(cData,[cData(:).width]);

%% Calculate avg. local velocity over a one-minute sliding window

stepSize = floor((size(cData(1).speed,1)-1)/120);
window = mod(1:stepSize,2)==0;
habRate=NaN(flyTracks.nFlies,1);

for i = 1:flyTracks.nFlies
    locVel = zeros(1,120);
    k=0;
    for j = 1:stepSize:stepSize*120
        tmpSpeed=cData(i).speed(j:j+stepSize);
        k=k+1;
        locVel(k) = nanmean(tmpSpeed(window));
    end
    X=1:length(locVel);
    nanLoc = find(isnan(locVel)==1);
    X(nanLoc)=[];
    locVel(nanLoc)=[];
    linCoeffs=polyfit(X,locVel,1);
    habRate(i)=linCoeffs(1);
end

%% Record arena circling metrics
% Calculate averaged circling angle mu. Assign data in flyCircles to master data struct flyData
% Assign flyID to each fly

mu=NaN(flyTracks.nFlies,1);
speed=NaN(flyTracks.nFlies,1);
rPos=NaN(flyTracks.nFlies,1);
angHist=NaN(length(flyCircles(1).angleavg),flyTracks.nFlies);

for i = 1:flyTracks.nFlies
    angHist(:,i)=flyCircles(i).angleavg;
    mu(i)=flyCircles(i).mu;

    % Record behavioral parameters and store in master data file
    speed(i) = nanmean(cData(i).speed);
    rPos(i) = nanmean(cData(i).r);    
end

flyTracks.rPos=rPos;
flyTracks.speed=speed;
flyTracks.mu=mu;
flyTracks.angHist=angHist;

%plotArenaTraces(flyCircles,tmpCen,flyTracks.ROI_coords)

%% Analyze stimulus response

clearvars tmpSpeed

stim_angles=dlmread(stimID);
stim_angles=reshape(stim_angles,flyTracks.nFlies,length(stim_angles)/flyTracks.nFlies)';
tex=dlmread(texID);
tex=boolean(tex);

% Convert centroid data to projector sapce
x=squeeze(flyTracks.centroid(:,1,:));
y=squeeze(flyTracks.centroid(:,2,:));
proj_x = Fx(x,y);
proj_y = Fy(x,y);
[div_dist,lightStat] = parseShadeLight(stim_angles,proj_x,proj_y,stim_centers,0);

% Calculate mean distance to divider for each fly
avg_d = mean(div_dist);

% Initialize light occupancy variables
light_occupancy = NaN(flyTracks.nFlies,1);
light_occupancy_time = NaN(flyTracks.nFlies,1);
light_total_time = NaN(flyTracks.nFlies,1);

% Initialize blank stimulus occupancy variables
blank_occupancy = NaN(flyTracks.nFlies,1);
blank_occupancy_time = NaN(flyTracks.nFlies,1);
blank_total_time = NaN(flyTracks.nFlies,1);

% Calculate occupancy for each fly in both blank and photo_stim conditions
for i=1:flyTracks.nFlies
    
    % When one half of the arena is lit
    off_divider = abs(div_dist(:,i))>3;                         % data mask for trials where fly is clearly in one half or the other
    tmp_tStamps = flyTracks.tStamps(off_divider & tex);               % ifi for included frames
    tmp_lightStat = lightStat(off_divider & tex,i);                   % light status for included frames
    light_occupancy_time(i) = sum(tmp_tStamps(tmp_lightStat));        % total time in the light
    light_total_time(i) = sum(tmp_tStamps);
    light_occupancy(i) = sum(tmp_tStamps(tmp_lightStat))/light_total_time(i);    % fractional time in light
    
    % When both halfs of the arena are unlit
    tmp_tStamps = flyTracks.tStamps(off_divider & ~tex);               % ifi for included frames
    tmp_lightStat = lightStat(off_divider & ~tex,i);                   % light status for included frames
    blank_occupancy_time(i) = sum(tmp_tStamps(tmp_lightStat));        % total time in the fake lit half
    blank_total_time(i) = sum(tmp_tStamps);
    blank_occupancy(i) = sum(tmp_tStamps(tmp_lightStat))/blank_total_time(i);    % fractional time in fake lit half
    
end

% Convert occupancy time from seconds to hours
light_occupancy_time = light_occupancy_time./3600;
light_total_time = light_total_time./3600;
blank_occupancy_time = blank_occupancy_time./3600;
blank_total_time = blank_total_time./3600;

%% Generate plots

min_active_period = 0.4;        % Minimum time spent off the boundary divider (hours)
active = flyTracks.speed >0.01;
%active = boolean(ones(size(flyTracks.speed)));

% Histogram for stimulus ON period
figure();
bins = 0:0.05:1;
c=histc(light_occupancy(light_total_time>min_active_period&active),bins)./sum(light_total_time>min_active_period&active);
c(end)=[];
plot(c,'Color',[1 0 1],'Linewidth',2);
set(gca,'Xtick',0:2:length(c),'XtickLabel',0:0.1:1);
axis([0 length(c) 0 max(c)+0.05]);
n_light=sum(light_total_time>min_active_period&active);

% Histogram for blank stimulus with fake lit half
bins = 0:0.05:1;
c=histc(blank_occupancy(blank_total_time>min_active_period&active),bins)./sum(blank_total_time>min_active_period&active);
c(end)=[];
hold on
plot(c,'Color',[0 0 1],'Linewidth',2);
set(gca,'Xtick',0:2:length(c),'XtickLabel',0:0.1:1);
axis([0 length(c) 0 max(c)+0.05]);
title('Light Occupancy Histogram');
n_blank=sum(blank_total_time>min_active_period&active);
hold off

% Generate legend labels
if iscellstr(flyTracks.labels{1,1})
    strain=flyTracks.labels{1,1}{:};
end
if iscellstr(flyTracks.labels{1,3})
    treatment=flyTracks.labels{1,3}{:};
end

% light ON label
light_avg_occ = round(mean(light_occupancy(light_total_time>min_active_period&active))*100)/100;
light_mad_occ = round(mad(light_occupancy(light_total_time>min_active_period&active))*100)/100;
n = sum(light_total_time>min_active_period&active);
legendLabel(1)={['Stim ON: ' strain ' ' treatment ' (u=' num2str(light_avg_occ)...
    ', MAD=' num2str(light_mad_occ) ', n=' num2str(n) ')']};
% light OFF label
blank_avg_occ = round(mean(blank_occupancy(blank_total_time>min_active_period&active))*100)/100;
blank_mad_occ = round(mad(blank_occupancy(blank_total_time>min_active_period&active))*100)/100;
n = sum(blank_total_time>min_active_period&active);
legendLabel(2)={['Stim OFF: ' strain ' ' treatment ' (u=' num2str(blank_avg_occ)...
    ', MAD=' num2str(blank_mad_occ) ', n=' num2str(n) ')']};
legend(legendLabel);
shg

% Save data to struct
flyTracks.light_occupancy = light_occupancy;
flyTracks.light_occupancy_time = light_occupancy_time;
flyTracks.light_total_time = light_total_time;
flyTracks.light_avg_occ = light_avg_occ;
flyTracks.light_mad_occ = light_mad_occ;
flyTracks.blank_occupancy = blank_occupancy;
flyTracks.blank_occupancy_time = blank_occupancy_time;
flyTracks.blank_total_time = blank_total_time;
flyTracks.blank_avg_occ = blank_avg_occ;
flyTracks.blank_mad_occ = blank_mad_occ;
flyTracks.stim_duration = handles.exp_parameters.stim_duration;
flyTracks.div_size = handles.exp_parameters.divider_size;
flyTracks.stim_contrast = handles.exp_parameters.stim_contrast;

%% Clean up the workspace
strain(ismember(strain,' ')) = [];
save(strcat(handles.fpath,'\',t,'Slowphoto','_',strain,'.mat'),'flyTracks');

%% Display command to load data struct into workspace

disp('Execute the following command to load your data into the workspace:')
disp(['load(',char(39),strcat(handles.fpath,'\',t,'Optomotor','_',strain,'.mat'),char(39),');'])

%% Set MATLAB priority to Above Normal via Windows Command Line
cmd_str = 'wmic process where name="MATLAB.exe" CALL setpriority 32768';
[~,~] = system(cmd_str);

clearvars -except handles