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

% Optomotor stimulus parameters
stim_int=handles.exp_parameters.stim_int;                   % interval between stimuli (min)
stim_duration=handles.exp_parameters.stim_duration;         % duration of the pinwheel per trial (min)

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
rotID = [handles.fpath '\' t strain '_' treatment '_StimRotation.dat'];         % File ID for stimulus state
 
dlmwrite(cenID, []);                          % create placeholder ASCII file
dlmwrite(oriID, []);                         % create placeholder ASCII file
dlmwrite(stimID, []);                         % create placeholder ASCII file
dlmwrite(rotID, []);                         % create placeholder ASCII file

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
ROI_image=imagedata(:,:,2);

% Update threshold value
ROI_thresh=get(handles.threshold_slider,'value')/255;

% Build a kernel to smooth vignetting
gaussianKernel=buildGaussianKernel(size(ROI_image,2),size(ROI_image,1),sigma,gaussWeight);
ROI_image=(uint8(double(ROI_image).*gaussianKernel));

% Extract ROIs from thresholded image
[ROI_bounds,ROI_coords,ROI_widths,ROI_heights,binaryimage] = detect_ROIs(ROI_image,ROI_thresh);

% Create orientation vector for mazes (upside down Y = 0, right-side up = 1)
mazeOri=logical(zeros(size(ROI_coords,1),1));

% Calculate coords of ROI centers
[xCenters,yCenters]=ROIcenters(binaryimage,ROI_coords);
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
bg_color=[1 1 1];          
scrProp=initialize_projector(bg_color);
pause(1);

%% Automatically average out flies from reference image

refImage=imagedata(:,:,2);                              % Assign reference image
lastCentroid=centers;                                   % Create placeholder for most recent non-NaN centroids
referenceCentroids=zeros(size(ROI_coords,1),2,10);      % Create placeholder for cen. coords when references are taken
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
                nRefs(i)=sum(sum(referenceCentroids(i,:,:)>0));
                referenceCentroids(i,:,mod(nRefs(i)+1,10))=lastCentroid(i,:);
                newRef=imagedata(ROI_coords(i,2):ROI_coords(i,4),ROI_coords(i,1):ROI_coords(i,3));
                oldRef=refImage(ROI_coords(i,2):ROI_coords(i,4),ROI_coords(i,1):ROI_coords(i,3));
                nRefs(i)=sum(sum(referenceCentroids(i,:,:)>0));                                         % Update num Refs
                averagedRef=newRef.*(1/nRefs(i))+oldRef.*(1-(1/nRefs(i)));               % Weight new reference by 1/nRefs
                refImage(ROI_coords(i,2):ROI_coords(i,4),ROI_coords(i,1):ROI_coords(i,3))=averagedRef;
            end
        end
        
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

load('C:\Users\werkh\OneDrive\Documents\MATLAB\DecathlonScripts\projectorTracker\projector_fit.mat');

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

% Determine stimulus size
pinwheel_size=round(nanmean(nanmean([stim_coords(:,3)-stim_coords(:,1) stim_coords(:,4)-stim_coords(:,2)]))*4);
nCycles = handles.exp_parameters.num_cycles;            % num dark-light cycles in 360 degrees
mask_r = handles.exp_parameters.mask_r;                 % radius of center circle dark mask (as fraction of stim_size)
ang_vel = handles.exp_parameters.ang_per_frame;         % angular velocity of stimulus (degrees/frame)
subim_r = floor(pinwheel_size/2*sqrt(2)/2);

% Initialize the stimulus image
pinwheel=initialize_pinwheel(pinwheel_size,pinwheel_size,nCycles,mask_r);
imcenter=[size(pinwheel,1)/2+0.5 size(pinwheel,2)/2+0.5];
subim_bounds = [imcenter(2)-subim_r imcenter(1)-subim_r imcenter(2)+subim_r imcenter(1)+subim_r];
stim_sz_x = subim_bounds(3)-subim_bounds(1)+1;
stim_sz_y = subim_bounds(4)-subim_bounds(2)+1;


% Initialize source rect and scaling factors
base_srcRect=[0 0 stim_sz_x/2 stim_sz_y/2];
centered_srcRect=CenterRectOnPointd(base_srcRect,stim_sz_x/2,stim_sz_y/2);
src_scaling_factor=NaN(size(centers));
src_scaling_factor(:,1)=(stim_sz_x/2)./(stim_coords(:,3)-stim_coords(:,1));
src_scaling_factor(:,2)=(stim_sz_y/2)./(stim_coords(:,4)-stim_coords(:,2));

%% Run Experiment

clearvars numbers oldRef ROI_image subtractedData
pinwheelTex = Screen('MakeTexture', scrProp.window, pinwheel);

tic
delay=0.0001;
pt=0; % Initialize pause time
stim_timer=zeros(size(ROI_coords,1),1);
stim_tStamp=zeros(size(ROI_coords,1),1);
stim_ON=logical(stim_timer);
stim_count=0;                                                           % Counter for number of looming stim displayed each stimulation period
angle=0;                                                                % Initialize stimulus starting angle to 0
local_spd = NaN(15,size(ROI_coords,1));
lastOrientation=NaN(size(ROI_coords,1),1);
stim_ct=0;
pinwheelTex_pos = Screen('MakeTexture', scrProp.window, pinwheel);          % Placeholder for pinwheel textures positively rotating
pinwheelTex_neg = Screen('MakeTexture', scrProp.window, pinwheel);         % Placeholder for pinwheel textures negatively rotating
rot_dir = boolean(ones(size(ROI_coords,1),1));                              % Direction of rotation for the pinwheel

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
            dlmwrite(stimID, stim_ON, '-append');
            dlmwrite(rotID, rot_dir, '-append');
            

        end
        
        % Calculate radial distance for each fly
        r=sqrt((lastCentroid(:,1)-centers(:,1)).^2 + (lastCentroid(:,2)-centers(:,2)).^2);
        
        % Update which stimuli (if any) need to be turned on
        local_spd(mod(ct-1,15)+1,:)=speed;
        moving = nanmean(local_spd)'>1;
        in_center = r < (ROI_widths./4);
        interval_exceeded = tElapsed-stim_timer > stim_int;
        
        % Activate the stimulus when flies are: moving, away from the 
        % edges, have exceeded the mandatory wait time between subsequent
        % presentations, and are not already being presented with a stimulus
        activate_stim = moving & in_center & interval_exceeded & ~stim_ON;
        rot_dir(activate_stim)=rand(sum(activate_stim),1)>0.5;      % Randomize the rotational direction
        stim_ON(activate_stim)=boolean(1);                          % Set stim status to ON
        stim_tStamp(activate_stim)=tElapsed;                        % Record the time
        
        if tElapsed < 0
            stim_ON=boolean(zeros(size(ROI_coords,1),1));
        end
        
        if any(stim_ON)
            
            stim_ct=stim_ct+1;
            
            % Rotate stim image and generate stim texture
            pos_rotim=imrotate(pinwheel,angle,'bilinear','crop');
            pos_rotim=pos_rotim(subim_bounds(2):subim_bounds(4),subim_bounds(1):subim_bounds(3));
            neg_rotim=imrotate(pinwheel,-angle,'bilinear','crop');
            neg_rotim=neg_rotim(subim_bounds(2):subim_bounds(4),subim_bounds(1):subim_bounds(3));

            % Calculate the displacement from the ROI center in projector space
            proj_centroid=NaN(sum(stim_ON),2);
            proj_centroid(:,1)=Fx(lastCentroid(stim_ON,1),lastCentroid(stim_ON,2));
            proj_centroid(:,2)=Fy(lastCentroid(stim_ON,1),lastCentroid(stim_ON,2));
            proj_displacement=[proj_centroid(:,1)-stim_centers(stim_ON,1) proj_centroid(:,2)-stim_centers(stim_ON,2)];
            proj_displacement=proj_displacement.*src_scaling_factor(stim_ON,:);
            src_rects=NaN(size(stim_coords(stim_ON,:)));
            src_rects(:,[1 3])=[centered_srcRect(1)-proj_displacement(:,1) centered_srcRect(3)-proj_displacement(:,1)];
            src_rects(:,[2 4])=[centered_srcRect(2)-proj_displacement(:,2) centered_srcRect(4)-proj_displacement(:,2)];
            
            Screen('Close', pinwheelTex_pos);
            Screen('Close', pinwheelTex_neg);
            pinwheelTex_pos = Screen('MakeTexture', scrProp.window, pos_rotim);
            pinwheelTex_neg = Screen('MakeTexture', scrProp.window, neg_rotim);

            % Pass textures to screen
            if any(rot_dir(stim_ON))
            Screen('DrawTextures', scrProp.window, pinwheelTex_pos, src_rects(rot_dir(stim_ON),:)', stim_coords(stim_ON & rot_dir,:)', [],...
            [], [], [],[], []);
            end
            if any(~rot_dir(stim_ON))
            Screen('DrawTextures', scrProp.window, pinwheelTex_neg, src_rects(~rot_dir(stim_ON),:)', stim_coords(stim_ON & ~rot_dir,:)', [],...
            [], [], [],[], []);
            end

            % Flip to the screen
            scrProp.vbl = Screen('Flip', scrProp.window, scrProp.vbl + (scrProp.waitframes - 0.5) * scrProp.ifi);

            % Advance the stimulus angle
            angle=angle+ang_vel;
            if angle >= 360
                angle=angle-360;
            end
        
        end
        
        % Turn off stimuli that have exceed the display duration
          stim_OFF = tElapsed-stim_tStamp >= stim_duration & stim_ON;
          stim_ON(stim_OFF) = logical(0);         % Set stim status to OFF
                    
        % Update stim timer for stimulus turned off
        if any(stim_OFF)
            
            % Reset the stimulus timer
            stim_timer(stim_OFF)=tElapsed;
        end
        
        % Update the display if the stimulus is not on
        if ~any(stim_ON)
           cla reset
           imagesc((imagedata-vignetteMat));
           hold on
           plot(lastCentroid(:,1),lastCentroid(:,2),'o','Color','r');
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
flyTracks.exp='Arena Circling';
flyTracks.ROI_coords=ROI_coords;
flyTracks.ROIcenters=centers;
flyTracks.nFlies = size(ROI_coords,1);
flyTracks.mazeOri=mazeOri;
flyTracks.labels = readtable(labelID);
flyTracks.filePath=cenID(1:end-12);

tmp = dlmread(cenID);
flyTracks.tStamps=tmp(mod(1:size(tmp,1),2)==0,1);
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
save(strcat(handles.fpath,t,'.mat'),'flyTracks');
tmpCen=[flyTracks.tStamps tmpCen];
cData = processCentroid(tmpCen,flyTracks.nFlies,flyTracks.ROI_coords);
flyCircles = avgAngle(cData,[cData(:).width]);

%% Calculate avg. local velocity over a one-minute sliding window

stepSize = floor(size(cData(1).speed,1)/120);
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

tElapsed=flyTracks.tStamps;
stim_status=boolean(dlmread(stimID));
stim_status=reshape(stim_status,flyTracks.nFlies,size(stim_status,1)/flyTracks.nFlies)';
rotDat=logical(dlmread(rotID));
rotDat=reshape(rotDat,flyTracks.nFlies,size(rotDat,1)/flyTracks.nFlies)';
opto = avgAngle_optomotor(cData,[cData(:).width],stim_status,~rotDat);
baseline = avgAngle_optomotor(cData,[cData(:).width],~stim_status,rotDat);
off_spd=NaN(flyTracks.nFlies,1);
on_spd=NaN(flyTracks.nFlies,1);
base_spd=NaN(flyTracks.nFlies,1);
speed=[cData(:).speed];
speed(speed<0.25)=0;
%plotArenaTraces(opto,tmpCen,flyTracks.ROI_coords)
%plotArenaTraces(baseline,tmpCen,flyTracks.ROI_coords)

for i=1:flyTracks.nFlies
    
    off_spd(i)=nanmean(speed(~stim_status(:,i),i));
    on_spd(i)=nanmean(speed(stim_status(:,i),i));
    base_spd(i)=nanmean(speed(tElapsed<30*60,i));
end

[iOFFr,iOFFc]=find(diff(stim_status)==-1);
iOFFr=iOFFr+1;
nTrials=NaN(flyTracks.nFlies,1);

for i=1:flyTracks.nFlies
    nTrials(i)=sum(iOFFc==i);
end


[iONr,iONc]=find(diff(stim_status)==1);
iONr=iONr+1;
[iOFFr,iOFFc]=find(diff(stim_status)==-1);
iOFFr=iOFFr+1;

% Stimulus triggered averaging of each stimulus bout
win_sz=stim_duration;     % Size of the window on either side of the stimulus in sec
win_start=NaN(size(iONr,1),flyTracks.nFlies);
win_stop=NaN(size(iOFFr,1),flyTracks.nFlies);
tElapsed=flyTracks.tStamps;
nTrials=NaN(flyTracks.nFlies,1);

%{
% Start by finding tStamps
for i=1:flyTracks.nFlies
    disp(i)
    tStamps=tElapsed(iONr(iONc==i));
    tON=tStamps-win_sz;
    tOFF=tStamps+win_sz;
    [v,start] = min(abs(repmat(tElapsed,1,length(tON))-repmat(tON',size(tElapsed,1),1))); 
    [v,stop] = min(abs(repmat(tElapsed,1,length(tON))-repmat(tOFF',size(tElapsed,1),1)));
    win_start(1:length(tStamps),i)=start;
    win_stop(1:length(tStamps),i)=stop;
end

clearvars tElapsed iONc iONr iOFFc iOFFr

win_start(sum(~isnan(win_start),2)==0,:)=[];
win_stop(sum(~isnan(win_stop),2)==0,:)=[];
nPts=max(max(win_stop-win_start));
da=NaN(nPts,size(win_start,1),flyTracks.nFlies);
%turning=dlmread(oriID);
%turning=diff(turning);
%turning=[zeros(1,size(turning,2));turning];
%}
turning=[cData(:).turning];
turn_distance = [cData(:).turn_distance];
turn_distance(rotDat&stim_status)=-turn_distance(rotDat&stim_status);
tmp_tdist = turn_distance;
tmp_tdist(~stim_status)=NaN;
tmp_r = nansum(tmp_tdist);
tmp_tot = nansum(abs(tmp_tdist));
opto_bias = tmp_r./tmp_tot;
%turning(rotDat&stim_status)=-turning(rotDat&stim_status);
speed=[cData(:).speed];
%turning(speed<0.2)=0;
%speed(speed<0.2)=0;
t0=nPts/2;
off_spd=NaN(flyTracks.nFlies,1);
on_spd=NaN(flyTracks.nFlies,1);

%{
for i=1:flyTracks.nFlies
    
    off_spd(i)=nanmean(speed(~stim_status(:,i),i));
    on_spd(i)=nanmean(speed(stim_status(:,i),i));
    
% Integrate change in heading angle over the entire stimulus bout
    for j=1:sum(~isnan(win_start(:,i)))
        tmpTurn=turning(win_start(j,i):win_stop(j,i),i);
        tmpTurn(tmpTurn > pi*0.95 | tmpTurn < -pi*0.95)=0;
        if ~isempty(tmpTurn)
            tmpTurn=interp1(1:length(tmpTurn),tmpTurn,linspace(1,length(tmpTurn),nPts));
            if nanmean(speed(win_start(j,i):win_stop(j,i),i))>0.03
            da(1:t0,j,i)=cumsum(tmpTurn(1:t0));
            da(t0+1:end,j,i)=cumsum(tmpTurn(t0+1:end));
            end
        end
    end
end
%}


active=nTrials>40;

%% Generate plots
%{
figure();
optoplots=squeeze(nanmean(da,2));
clearvars da tmpTurn win_start win_stop
flyTracks.optoplots=optoplots;
flyTracks.nTrials=nTrials;
flyTracks.tScore=optoplots(end,:);
flyTracks.off_spd=off_spd;
flyTracks.on_spd=on_spd;
flyTracks.stim_duration=stim_duration;
[v,p]=sort(mean(optoplots(t0+1:end,:)));
p_optoplots=optoplots(:,p);
p_cormap=cormap(p,:);
hold on
for i=1:flyTracks.nFlies
    plot(smooth(p_optoplots(:,i),10),'Color',cormap(i,:),'linewidth',2);
end

axis([0 size(optoplots,1) min(min(optoplots)) max(max(optoplots))]);
hold on
plot(nanmean(optoplots(:,active),2),'k-','LineWidth',3);
plot([t0 t0],[min(min(optoplots)) max(max(optoplots))],'k--','LineWidth',2);
hold off
set(gca,'Xtick',linspace(1,size(optoplots,1),7),'XtickLabel',linspace(-win_sz,win_sz,7));
ylabel('cumulative d\theta (rad)')
xlabel('time to stimulus onset')
title('Change in heading direction before and after optomotor stimulus')
%}
    
flyTracks.nTrials=nTrials;
flyTracks.optoMu = [opto(:).mu]';
flyTracks.baseMu = [baseline(:).mu]';
flyTracks.off_spd=off_spd;
flyTracks.on_spd=on_spd;
flyTracks.stim_duration=stim_duration;
flyTracks.active=active;

%% Clean up the workspace
strain(ismember(strain,' ')) = [];
save(strcat(handles.fpath,'\',t,'Optomotor','_',strain,'.mat'),'flyTracks');

%% Display command to load data struct into workspace

disp('Execute the following command to load your data into the workspace:')
disp(['load(',char(39),strcat(handles.fpath,'\',t,'Optomotor','_',strain,'.mat'),char(39),');'])

%% Set MATLAB priority to Above Normal via Windows Command Line
cmd_str = 'wmic process where name="MATLAB.exe" CALL setpriority 32768';
[~,~] = system(cmd_str);

clearvars -except handles