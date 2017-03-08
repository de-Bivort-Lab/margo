clearvars -except handles
colormap('gray')

%% Set MATLAB to High Priority via Windows Command Line
cmd_str = 'wmic process where name="MATLAB.exe" CALL setpriority 128';
[~,~] = system(cmd_str);

%% Define parameters - adjust parameters here to fix tracking and ROI segmentation errors

% Experimental parameters
exp_duration=handles.exp_duration;
exp_duration=exp_duration*60;
referenceStackSize=handles.ref_stack_size;   % Number of images to keep in rolling reference
referenceFreq=handles.ref_freq;              % Seconds between reference images
referenceTime = 60;                          % Seconds over which intial reference images are taken
% Tracking parameters
imageThresh=get(handles.threshold_slider,'value');    % Difference image threshold for detecting centroids
speedThresh=35;                              % Maximum allow pixel speed (px/s);

% ROI detection parameters
ROI_thresh=get(handles.threshold_slider,'value')/255;    % Binary image threshold from zero (black) to one (white) for segmentation  
sigma=0.47;                                 % Sigma expressed as a fraction of the image height
kernelWeight=0.34;                          % Scalar weighting of kernel when applied to the image

% Looming stimulus parameters
dr=20;                                       % change in radius (pixels/frame)
loom_int=1.5;                               % interval between looming stimuli (min)
num_loom=1;                                 % number of looms per trial

%% Save labels and create placeholder files for data

t = datestr(clock,'mm-dd-yyyy-HH-MM-SS_');
labels = cell2table(labelMaker(handles.labels),'VariableNames',{'Strain' 'Sex' 'Treatment' 'ID' 'Day'});
strain=labels{1,1}{:};
treatment=labels{1,3}{:};
labelID = [handles.fpath '\' t strain '_' treatment '_labels.dat'];     % File ID for label data
writetable(labels, labelID);

% Create placeholder files
cenID = [handles.fpath '\' t strain '_' treatment '_Centroid.dat'];            % File ID for centroid data
turnID = [handles.fpath '\' t strain '_' treatment '_RightTurns.dat'];         % File ID for turn data
stimID = [handles.fpath '\' t strain '_' treatment '_StimStatus.dat'];         % File ID for stimulus state
 
dlmwrite(cenID, []);                          % create placeholder ASCII file
dlmwrite(turnID, []);                         % create placeholder ASCII file
dlmwrite(stimID, []);                         % create placeholder ASCII file

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
gaussianKernel=buildGaussianKernel(size(ROI_image,2),size(ROI_image,1),sigma,kernelWeight);
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
%Screen('BlendFunction', scrProp.window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
pause(1);

%% Automatically average out flies from reference image

refImage=imagedata(:,:,2);                              % Assign reference image
lastCentroid=centers;                                   % Create placeholder for most recent non-NaN centroids
referenceCentroids=zeros(size(ROI_coords,1),2,10);      % Create placeholder for cen. coords when references are taken
propFields={'Centroid';'Area'};           % Define fields for regionprops
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
shg
%title('Displaying Tracking for 120s - Please check tracking and ROIs')
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

stim_size=round(nanmean(nanmean([stim_coords(:,3)-stim_coords(:,1) stim_coords(:,4)-stim_coords(:,2)]))*4);
base_srcRect=[0 0 stim_size/2 stim_size/2]
centered_srcRect=CenterRectOnPointd(base_srcRect,stim_size/2,stim_size/2);
src_scaling_factor=NaN(size(centers));
src_scaling_factor(:,1)=(stim_size/2)./(stim_coords(:,3)-stim_coords(:,1));
src_scaling_factor(:,2)=(stim_size/2)./(stim_coords(:,4)-stim_coords(:,2));

%% Run Experiment
shg
tic
delay=0.0001;
pt=0; % Initialize pause time
loom_timer=0;
stim_ON=logical(0);
stim_r=round(logspace(0,log10((stim_size-10)/2),10));
%stim_r=round(ones(1000,1)*0.05*stim_size);
loom_index=1;
stim_count=0;                 % Counter for number of looming stim displayed each stimulation period
loom_int=loom_int*60;           % Convert the stim interval from min to sec

while toc < exp_duration
    
        % Grab new time stamp
        current_tStamp = toc-pt;
        tElapsed=tElapsed+current_tStamp-previous_tStamp;
        set(handles.edit_frame_rate,'String',num2str(round(1/(current_tStamp-previous_tStamp))));
        ifi=current_tStamp-previous_tStamp;
        previous_tStamp=current_tStamp;
        ct=ct+1;
        tempCount=tempCount+1;

        % Get framerate delay to slow acquisition
        %delay=str2double(get(handles.edit9,'String'));
        delay=delay/1000;
        pause(delay);
    
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
            centStamp(update_centroid)=tElapsed;
            speed = zeros(1,size(ROI_coords,1));
            speed(update_centroid)=spd(~above_spd_thresh);
            end
            
            % Write data to the hard drive
            dlmwrite(cenID, [[ct;ifi] lastCentroid'], '-append');
            dlmwrite(stimID, stim_ON, '-append');
            

        end
        
        % Check loom timer and display stimuli
        if tElapsed-loom_timer > loom_int && ~stim_ON
            stim_ON=logical(1);
            disp('STIM TURNED ON')
        end
        
        if stim_ON
                % Initialize circle
                circImage=ones(stim_size);
                circCenter=size(circImage)/2;
                circBounds=[circCenter(2)-stim_r(loom_index) circCenter(1)-stim_r(loom_index) ...
                    circCenter(2)+stim_r(loom_index)-1 circCenter(1)+stim_r(loom_index)-1];
                circMask=~(Circle(stim_r(loom_index)));
                circImage(circBounds(2):circBounds(4),circBounds(1):circBounds(3))=circMask;
                circTex = Screen('MakeTexture', scrProp.window, circImage);
                
                % Calculate the distance from the center in projector space
                proj_centroid=NaN(size(lastCentroid));
                proj_centroid(:,1)=Fx(lastCentroid(:,1),lastCentroid(:,2));
                proj_centroid(:,2)=Fy(lastCentroid(:,1),lastCentroid(:,2));
                proj_displacement=[proj_centroid(:,1)-stim_centers(:,1) proj_centroid(:,2)-stim_centers(:,2)];
                proj_displacement=proj_displacement.*src_scaling_factor;
                src_rects=NaN(size(stim_coords));
                src_rects(:,[1 3])=[centered_srcRect(1)-proj_displacement(:,1) centered_srcRect(3)-proj_displacement(:,1)];
                src_rects(:,[2 4])=[centered_srcRect(2)-proj_displacement(:,2) centered_srcRect(4)-proj_displacement(:,2)];
                
                % Pass textures to screen
                Screen('DrawTextures', scrProp.window, circTex, src_rects', stim_coords', [],...
                [], [], [],[], []);
            
                % Flip to the screen
                % Flip our drawing to the screen
                scrProp.vbl = Screen('Flip', scrProp.window, scrProp.vbl + (scrProp.waitframes - 0.5) * scrProp.ifi);
                
                % Advance the radius of the spot
                loom_index=loom_index+1;
                if loom_index > length(stim_r)
                    stim_count=stim_count+1;
                    loom_index=1;
                end
                if stim_count==num_loom
                    stim_ON=logical(0);         % Set stim status to OFF
                    stim_count=0;
                    
                    % Draw blank white screen and flip it to the projector
                    Screen('FillRect',scrProp.window,[1 1 1],scrProp.windowRect);
                    scrProp.vbl = Screen('Flip', scrProp.window, scrProp.vbl + (scrProp.waitframes - 0.5) * scrProp.ifi);
                    
                    % Reset the stimulus timer
                    loom_timer=tElapsed;
                end
        end
        
        % Update the display every 30 frames
        if mod(ct,30)==0
           %cla reset
           imagesc((imagedata-vignetteMat));
           hold on
           plot(lastCentroid(:,1),lastCentroid(:,2),'o','Color','r');
           hold off
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
    
end

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
clearvars xCen yCen min

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

%% Discard the first turn in every maze
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

%% Analyze Escape Response

stim_status=boolean(dlmread(stimID));
tElapsed=cumsum(flyTracks.tStamps);
ifi=flyTracks.tStamps;
speed=[cData(:).speed]./repmat(ifi,1,flyTracks.nFlies);
speed=[cData(:).speed];
%speed(speed==0)=NaN;
%speed(speed<0.05)=0;

[iONr,iONc]=find(diff(stim_status)==1);
iONr=iONr+1;
[iOFFr,iOFFc]=find(diff(stim_status)==-1);
iOFFr=iOFFr+1;

% Stimulus triggered averaging of each stimulus bout
win_sz=0.5;     % Size of the window on either side of the stimulus in sec
win_start=NaN(size(iONr,1),1);
win_stop=NaN(size(iOFFr,1),1);

% Start by finding tStamps
tStamps=tElapsed(iONr);
tON=tStamps-win_sz;
tOFF=tStamps+win_sz;
[v,start] = min(abs(repmat(tElapsed,1,length(tON))-repmat(tON',size(tElapsed,1),1))); 
[v,stop] = min(abs(repmat(tElapsed,1,length(tON))-repmat(tOFF',size(tElapsed,1),1)));
win_start(1:length(tStamps))=start;
win_stop(1:length(tStamps))=stop;

clearvars iONc iOFFc iOFFr

win_start(sum(~isnan(win_start),2)==0,:)=[];
win_stop(sum(~isnan(win_stop),2)==0,:)=[];
nPts=max(max(win_stop-win_start));
spd_dat=NaN(nPts,size(win_start,1),flyTracks.nFlies);
t0=nPts/2;
peak_spd=NaN(size(win_start,1),flyTracks.nFlies);
peak_index=NaN(size(win_start,1),flyTracks.nFlies);

for i=1:flyTracks.nFlies    
% Integrate change in speed over the entire stimulus bout
    for j=1:sum(~isnan(win_start(:)))
        tmpSpd=speed(win_start(j):win_stop(j),i);
        tmp_peak_spd=max(tmpSpd(length(tmpSpd)*0.49:end));
        if tmp_peak_spd > 3
            [peak_spd(j,i),peak_index(j,i)]=max(tmpSpd);
            peak_index(j,i)=peak_index(j,i)+win_start(j)-1;
            tmpSpd=interp1(1:length(tmpSpd),tmpSpd,linspace(1,length(tmpSpd),nPts));
            spd_dat(:,j,i)=tmpSpd;
        end
    end
end

%% Watch escape movies

figure();
centroid=flyTracks.centroid;
title('Escape Response Movies')
ROI_coords=flyTracks.ROI_coords;
w=ROI_coords(:,3)-ROI_coords(:,1);
h=ROI_coords(:,4)-ROI_coords(:,2);
r=mean([w h],2)./2;
colormap('gray')
hold on
fly_pos=plot([],[],'ro','Linewidth',2);
trace=plot([],[],'ro','Linewidth',2);
stim_symbol=plot([],[],'ro','Linewidth',2);
pk_trace=plot([],[],'ro','Linewidth',2);
t_disp=plot([],[],'ro','Linewidth',2);
trial_num=plot([],[],'ro','Linewidth',2);
shg
for i=2:flyTracks.nFlies
    
    image(zeros(h(i)+1,w(i)+1));
    fly_num=text(w(i)*0.05,h(i)*0.1,['fly ' num2str(i)],'Color','r');
    rectangle('Position',[1 1 w(i) h(i)],'Curvature',[1 1],'Edgecolor',[1 0 0]);
    
    % For each trial
    for j=1:sum(~isnan(win_start(:)))
        
        % If the frame is valid
        if ~isnan(peak_spd(j,i))
            delete(trial_num);
            delete(stim_symbol);
            delete(pk_trace);
            trial_num=text(w(i)*0.1,h(i)*0.1,['- trial ' num2str(j)],'Color','r');
            
            % For each frame in the trial
            for k=1:win_stop(j)-win_start(j)
                pause(1/60);
                f = win_start(j)+k-1;
                s = win_start(j)-1;
                    if f==iONr(j);
                        stim_symbol=plot(w(i)*0.9,h(i)*0.9,'wo','Linewidth',4);
                    end
                delete(trace);
                delete(fly_pos);
                trace=plot(centroid(s:f,1,i)-ROI_coords(i,1),centroid(s:f,2,i)-ROI_coords(i,2),'Color',[1 1 1],'Linewidth',1);
                fly_pos=plot(centroid(f,1,i)-ROI_coords(i,1),centroid(f,2,i)-ROI_coords(i,2),'ro','Linewidth',2); 
                
                if peak_index(j,i)==f
                    pk_trace=plot(centroid(f-1:f+1,1,i)-ROI_coords(i,1),centroid(f-1:f+1,2,i)-ROI_coords(i,2),'Color',[1 0 0],'Linewidth',2);
                end
                
                delete(t_disp);
                t_disp=text(w(i)*0.1,h(i)*0.9,num2str(round((tElapsed(f)-tElapsed(iONr(j)))*1000)),'Color',[1 1 1],'FontSize',14);   
                drawnow
                
            end
        end
    end
end

%% Generate plots

figure();
escapeplots=squeeze(nanmean(spd_dat,2));
escapeplots=escapeplots-repmat(mean(escapeplots,1),size(escapeplots,1),1);
flyTracks.escapeplots=escapeplots;
flyTracks.nTrials=size(spd_dat,2);
hold on
ymin=0;
ymax=0;
for i=1:size(escapeplots,2)
    tmp_smoothed=smooth(escapeplots(:,i),0.0001*size(escapeplots,1));
    if min(tmp_smoothed)<ymin
        ymin=min(tmp_smoothed);
    end
    if max(tmp_smoothed)>ymax
        ymax=max(tmp_smoothed);
    end
    plot(tmp_smoothed);
end
axis([0 size(escapeplots,1) ymin ymax]);
splot=smooth(nanmean(escapeplots,2),0.0001*size(escapeplots,1));
plot(splot,'k-','LineWidth',3);
plot([t0 t0],[ymin ymax],'k--','LineWidth',2);
hold off
set(gca,'Xtick',linspace(1,size(escapeplots,1),7),'XtickLabel',linspace(-win_sz,win_sz,7));
ylabel('speed')
xlabel('time to stimulus onset')
title('Change in speed before and after looming stimulus')

% Individual plots
figure()
for i=1:size(escapeplots,2)
    tmp_smoothed=smooth(escapeplots(:,i),0.05*size(escapeplots,1));
    if min(tmp_smoothed)<ymin
        ymin=min(tmp_smoothed);
    end
    if max(tmp_smoothed)>ymax
        ymax=max(tmp_smoothed);
    end
    subplot(4,4,i);
    plot(tmp_smoothed);
    hold on
    plot([t0 t0],[min(tmp_smoothed) max(tmp_smoothed)],'k--','LineWidth',2);
    hold off
end


%% Clean up the workspace
strain(ismember(strain,' ')) = [];
save(strcat(handles.fpath,'\',t,'_Escape','_',strain,'.mat'),'flyTracks');

%% Display command to load data struct into workspace

disp('Execute the following command to load your data into the workspace:')
disp(['load(',char(39),strcat(handles.fpath,'\',t,'Circling','_',strain,'.mat'),char(39),');'])

%% Set MATLAB priority to Above Normal via Windows Command Line
cmd_str = 'wmic process where name="MATLAB.exe" CALL setpriority 32768';
[~,~] = system(cmd_str);

clear


clearvars -except handles