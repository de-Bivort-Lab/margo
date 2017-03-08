clearvars -except handles
colormap('gray')

%% Set MATLAB to High Priority via Windows Command Line
cmd_str = 'wmic process where name="MATLAB.exe" CALL setpriority 128';
[~,~] = system(cmd_str);

%% Define parameters - adjust parameters here to fix tracking and ROI segmentation errors

% Experimental parameters
exp_duration=handles.expDuration;
referenceStackSize=handles.refStack;        % Number of images to keep in rolling reference
referenceFreq=handles.refTime;              % Seconds between reference images
referenceTime = 60;                        % Seconds over which intial reference images are taken
% Tracking parameters
imageThresh=get(handles.slider2,'value');                             % Difference image threshold for detecting centroids
speedThresh=35;                              % Maximum allow pixel speed (px/s);

% ROI detection parameters
ROI_thresh=get(handles.slider1,'value');    % Binary image threshold from zero (black) to one (white) for segmentation  
sigma=0.47;                                 % Sigma expressed as a fraction of the image height
kernelWeight=0.34;                          % Scalar weighting of kernel when applied to the image

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
 
dlmwrite(cenID, []);                          % create placeholder ASCII file
dlmwrite(turnID, []);                         % create placeholder ASCII file

%% Setup the camera and video object
imaqreset
pause(0.5);
% Camera mode set to 8-bit with 664x524 resolution
vid = initializeCamera('pointgrey',1,'F7_BayerRG8_664x524_Mode1');
pause(0.5);

% Initialize the psychtoolbox window and query projector properties
scrProp=initialize_projector;
pause(1);

%% Grab image for ROI detection and segment out ROIs
stop=get(handles.togglebutton10,'value');

while stop~=1;
tic
stop=get(handles.togglebutton10,'value');

% Take single frame
imagedata=peekdata(vid,1);
% Extract red channel
ROI_image=imagedata(:,:,2);

% Update threshold value
ROI_thresh=get(handles.slider1,'value');

% Build a kernel to smooth vignetting
gaussianKernel=buildGaussianKernel(size(ROI_image,2),size(ROI_image,1),sigma,kernelWeight);
ROI_image=(uint8(double(ROI_image).*gaussianKernel));

% Extract ROIs from thresholded image
[ROI_bounds,ROI_coords,ROI_widths,ROI_heights,binaryimage] = detect_ROIs(ROI_image,ROI_thresh);

% Create orientation vector for mazes (upside down Y = 0, right-side up = 1)
mazeOri=logical(zeros(size(ROI_coords,1),1));

% Calculate coords of ROI centers
[xCenters,yCenters]=optoROIcenters(binaryimage,ROI_coords);
centers=[xCenters,yCenters];

% Define a permutation vector to sort ROIs from top-right to bottom left
[ROI_coords,mazeOri,ROI_bounds,centers]=optoSortROIs(ROI_coords,mazeOri,centers,ROI_bounds);

set(handles.edit7,'String',num2str(size(ROI_bounds,1)));


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


    
set(handles.edit8,'String',num2str(round(1/toc)));
end

% Reset the accept threshold button
set(handles.togglebutton10,'value',0);

%% Automatically average out flies from reference image

refImage=imagedata(:,:,2);                              % Assign reference image
lastCentroid=centers;                                   % Create placeholder for most recent non-NaN centroids
referenceCentroids=zeros(size(ROI_coords,1),2,10);      % Create placeholder for cen. coords when references are taken
propFields={'Centroid';'Area'};           % Define fields for regionprops
nRefs=zeros(size(ROI_coords,1),1);                      % Reference number placeholder
numbers=1:size(ROI_coords,1);                           % Numbers to display while tracking
centStamp=zeros(size(ROI_coords,1),1);
vignetteMat=decFilterVignetting(refImage,binaryimage,ROI_coords);

% Set maximum allowable distance to center of ROI as the long axis of the
% ROI + some error
w=median(ROI_bounds(:,3));
h=median(ROI_bounds(:,4));
distanceThresh=sqrt(w^2+h^2)/2;  

%title('Reference Acquisition In Progress - Press any key to continue')
shg

% Time stamp placeholders
tElapsed=0;
tic
previous_tStamp=toc;
current_tStamp=0;

% Collect reference until timeout OR "accept reference" GUI press
while toc<referenceTime&&get(handles.togglebutton11,'value')~=1
    
    % Update image threshold value from GUI
    imageThresh=get(handles.slider2,'value');
    
    % Update tStamps
    current_tStamp=toc;
    set(handles.edit8,'String',num2str(round(1/(current_tStamp-previous_tStamp))));
    tElapsed=tElapsed+current_tStamp-previous_tStamp;
    previous_tStamp=current_tStamp;
    
        % Report time remaining to reference timeout to GUI
        timeRemaining = round(referenceTime - toc);
        if timeRemaining < 60; 
            set(handles.edit6, 'String', ['00:00:' sprintf('%0.2d',timeRemaining)]);
            set(handles.edit6, 'BackgroundColor', [1 0.4 0.4]);
        elseif (3600 > timeRemaining) && (timeRemaining > 60);
            min = floor(timeRemaining/60);
            sec = rem(timeRemaining, 60);
            set(handles.edit6, 'String', ['00:' sprintf('%0.2d',min) ':' sprintf('%0.2d',sec)]);
            set(handles.edit6, 'BackgroundColor', [1 1 1]);
        elseif timeRemaining > 3600;
            hr = floor(timeRemaining/3600);
            min = floor(rem(timeRemaining, 3600)/60);
            sec = timeRemaining - hr*3600 - min*60;
            set(handles.edit6, 'String', [sprintf('%0.2d', hr) ':' sprintf('%0.2d',min) ':' sprintf('%0.2d',sec)]);
            set(handles.edit6, 'BackgroundColor', [1 1 1]);
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
        [lastCentroid,centStamp]=...
            optoMatchCentroids2ROIs(cenDat,centers,speedThresh,distanceThresh,lastCentroid,centStamp,tElapsed);
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
       drawnow

       
    if get(handles.togglebutton9, 'Value') == 1;
        waitfor(handles.togglebutton9, 'Value', 0)
    end

end

% Update vignette offset matrix with better reference
vignetteMat=decFilterVignetting(refImage,binaryimage,ROI_coords);

% Reset accept reference button
set(handles.togglebutton11,'value',0);

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
        imageThresh=get(handles.slider2,'value');

        % Update time stamps
        current_tStamp=toc;
        tElapsed=tElapsed+current_tStamp-previous_tStamp;
        set(handles.edit8,'String',num2str(round(1/(current_tStamp-previous_tStamp))));
        previous_tStamp=current_tStamp;

            timeRemaining = round(referenceTime - toc);
                
                set(handles.edit10, 'String', num2str(pixDistSize-ct));

               % Get centroids and sort to ROIs
               imagedata=peekdata(vid,1);
               imagedata=imagedata(:,:,2);
               imagedata=(refImage-vignetteMat)-(imagedata-vignetteMat);
               props=regionprops((imagedata>imageThresh),propFields);

               % Match centroids to ROIs by finding nearest ROI center
               validCentroids=([props.Area]>4&[props.Area]<120);
               cenDat=reshape([props(validCentroids).Centroid],2,length([props(validCentroids).Centroid])/2)';
               [lastCentroid,centStamp]=...
                    optoMatchCentroids2ROIs(cenDat,centers,speedThresh,distanceThresh,lastCentroid,centStamp,tElapsed);
                
               %Update display if display tracking is ON
               imshow(imagedata>imageThresh);
               hold on
               % Mark centroids
               plot(lastCentroid(:,1),lastCentroid(:,2),'o','Color','r');
               hold off
               drawnow

               
           % Create distribution for num pixels above imageThresh
           % Image statistics used later during acquisition to detect noise
           pixelDist(mod(ct,pixDistSize)+1)=nansum(nansum(imagedata>imageThresh));
           ct=ct+1;
   
   % Pause the script if the pause button is hit
   if get(handles.togglebutton9, 'Value') == 1;
      waitfor(handles.togglebutton9, 'Value', 0)    
   end

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

load('C:\Users\werkh\OneDrive\Documents\MATLAB\DecathlonScripts\Projector Box\projector_fit.mat');

%% Run Experiment
shg
tic
pt=0; % Initialize pause time

while toc < exp_duration
    
        % Grab new time stamp
        current_tStamp = toc-pt;
        tElapsed=tElapsed+current_tStamp-previous_tStamp;
        set(handles.edit8,'String',num2str(round(1/(current_tStamp-previous_tStamp))));
        previous_tStamp=current_tStamp;
        ct=ct+1;
        tempCount=tempCount+1;

        % Get framerate delay to slow acquisition
        delay=str2double(get(handles.edit9,'String'));
        delay=delay/1000;
        pause(delay);
    
        % Update clock in the GUI
        timeRemaining = round(exp_duration - toc);
        if timeRemaining < 60; 
            set(handles.edit6, 'String', ['00:00:' sprintf('%0.2d',timeRemaining)]);
            set(handles.edit6, 'BackgroundColor', [1 0.4 0.4]);
        elseif (3600 > timeRemaining) && (timeRemaining > 60);
            min = floor(timeRemaining/60);
            sec = rem(timeRemaining, 60);
            set(handles.edit6, 'String', ['00:' sprintf('%0.2d',min) ':' sprintf('%0.2d',sec)]);
            set(handles.edit6, 'BackgroundColor', [1 1 1]);
        elseif timeRemaining > 3600;
            hr = floor(timeRemaining/3600);
            min = floor(rem(timeRemaining, 3600)/60);
            sec = timeRemaining - hr*3600 - min*60;
            set(handles.edit6, 'String', [sprintf('%0.2d', hr) ':' sprintf('%0.2d',min) ':' sprintf('%0.2d',sec)]);
            set(handles.edit6, 'BackgroundColor', [1 1 1]);
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
            [lastCentroid,centStamp]=...
                optoMatchCentroids2ROIs(cenDat,centers,speedThresh,distanceThresh,lastCentroid,centStamp,tElapsed);
            
            proj_coords=[Fx(cenDat(:,1),cenDat(:,2)) Fy(cenDat(:,1),cenDat(:,2))];
            scrProp=drawCircle(proj_coords(:,1),proj_coords(:,2),2,[1 0 0],scrProp);
            
            % Write data to the hard drive
            dlmwrite(cenID, [[ct;tElapsed] lastCentroid'], '-append');

        end

        % Update the display every 30 frames
        if mod(ct,30)==0
           cla reset
           imagesc((imagedata-vignetteMat));
           hold on
           plot(lastCentroid(:,1),lastCentroid(:,2),'o','Color','r');
           hold off
           drawnow
        end

        % Display current noise level once/sec
        if mod(ct,round(60/delay))==0
            currentDev=mean(pixDev)
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
               vignetteMat=decFilterVignetting(refImage,binaryimage,ROI_coords);
            end         
        end 
        previous_refUpdater=current_refUpdater;
   
    if get(handles.togglebutton9, 'Value') == 1;
        p1 = toc;
        waitfor(handles.togglebutton9, 'Value', 0)
        pt = toc-p1+pt;
    end
    
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
xCen=mod(1:size(tmp,1),2)==1;
yCen=mod(1:size(tmp,1),2)==0;

for k = 1:flyTracks.nFlies
    centroid(:, 1, k) = tmp(xCen, k)';
    centroid(:, 2, k) = tmp(yCen, k)';
end

tmpCen=NaN(size(centroid,1),2*flyTracks.nFlies);
for i=1:size(centroid,3)
tmpCen(:,2*i-1:2*i)=centroid(:,:,i);
end

flyTracks.centroid=centroid;
clearvars centroid tmp xCen yCen
save(strcat('flyTracks',t,'.mat'),'flyTracks');
tmpCen=[flyTracks.tStamps tmpCen];
cData = flyBurHandData(tmpCen,flyTracks.nFlies,flyTracks.ROI_coords);
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

decPlotArenaTracesv2(flyCircles,tmpCen,flyTracks.ROI_coords)

%% Clean up the workspace
strain(ismember(strain,' ')) = [];
save(strcat(handles.fpath,'\',t,'Circling','_',strain,'.mat'),'flyTracks');

%% Display command to load data struct into workspace

disp('Execute the following command to load your data into the workspace:')
disp(['load(',char(39),strcat(handles.fpath,'\',t,'Circling','_',strain,'.mat'),char(39),');'])

%% Set MATLAB priority to Above Normal via Windows Command Line
cmd_str = 'wmic process where name="MATLAB.exe" CALL setpriority 32768';
[~,~] = system(cmd_str);

clear


clearvars -except handles