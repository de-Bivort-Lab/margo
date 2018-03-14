

% Calculate threshold for distance to end of maze arms for turn scoring
mazeLengths=mean([widths heights],2);
armThresh=mazeLengths.*0.2;


%% Calculate coordinates of end of each maze arm

arm_coords=zeros(size(ROI_coords,1),2,6);   % Placeholder
w=ROI_bounds(:,3);                          % width of each ROI
h=ROI_bounds(:,4);                          % height of each ROI
% Offsets to shift arm coords from edge of ROI bounding box
xShift=w.*0.15;                             
yShift=h.*0.15;

% Coords 1-3 are for upside-down Ys
arm_coords(:,:,1)=[ROI_coords(:,1)+xShift ROI_coords(:,4)-yShift];
arm_coords(:,:,2)=[centers(:,1) ROI_coords(:,2)+yShift];
arm_coords(:,:,3)=[ROI_coords(:,3)-xShift ROI_coords(:,4)-yShift];

% Coords 4-6 are for right-side up Ys
arm_coords(:,:,4)=[ROI_coords(:,1)+xShift ROI_coords(:,2)+yShift];
arm_coords(:,:,5)=[centers(:,1) ROI_coords(:,4)-yShift];
arm_coords(:,:,6)=[ROI_coords(:,3)-xShift ROI_coords(:,2)+yShift];

%% Set experiment parameters

% Time stamp variables
tempCount=1;
turntStamp=zeros(size(ROI_coords,1),1);

previous_refUpdater=0;                          % Compared to current_refUpdater to update the reference at correct freq.
write=logical(0);                               % Data written to hard drive when true

display=logical(1);                             % Updates display every 2s when true
previous_arm=zeros(size(ROI_coords,1),1);


%% Run Experiment
shg
tic
pt=0; % Initialize pause time

while toc < exp_duration
    
        % Grab new time stamp
        current_tStamp = toc-pt;
        tElapsed=tElapsed+current_tStamp-previous_tStamp;
        set(handles.edit_frame_rate,'String',num2str(round(1/(current_tStamp-previous_tStamp))));
        previous_tStamp=current_tStamp;
        ct=ct+1;
        tempCount=tempCount+1;

        % Get framerate delay to slow acquisition
        delay=str2double(get(handles.edit_frame_delay,'String'));
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
        
        % Correct image for vignetting
        diffImage=(refImage-vignetteMat)-(imagedata-vignetteMat);           
        
        % update reference image and ROI_positions at the reference frequency and print time remaining 
        current_refUpdater=mod(toc,ref_freq);
        aboveThresh(mod(ct,10)+1)=sum(sum(diffImage>imageThresh));
        pixDev(mod(ct,10)+1)=(nanmean(aboveThresh)-pixMean)/pixStd;
        
        % Only gather centroids and record turns if noise is below
        % threshold
        if pixDev(mod(ct,10)+1)<8

            % Extract image properties and exclude centroids not satisfying
            % size criteria
            props=regionprops((diffImage>imageThresh),propFields);
            validCentroids=([props.Area]>4&[props.Area]<120);
            cenDat=reshape([props(validCentroids).Centroid],2,length([props(validCentroids).Centroid])/2)';
            
            % Match centroids to ROIs by finding nearest ROI center
            [lastCentroid,centStamp]=...
                matchCentroids2ROIs(cenDat,centers,speedThresh,distanceThresh,lastCentroid,centStamp,tElapsed);

            % Determine if fly has changed to a new arm
            [current_arm,previous_arm,changedArm,rightTurns,turntStamp]=...
                detectArmChange(lastCentroid,arm_coords,previous_arm,mazeOri,armThresh,turntStamp,tElapsed);

            turnArm=NaN(size(ROI_coords,1),1);
            turnArm(changedArm)=current_arm(changedArm);
            
            % Write data to the hard drive
            dlmwrite(cenID, [[ct;tElapsed] lastCentroid'], '-append');
            dlmwrite(turnID, turnArm', '-append');
        end

        % Update the display every 30 frames
        if mod(ct,30)==0
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
            currentDev=mean(pixDev)
        end
        
        % If noise in the image goes more than 6 std above mean, wipe the
        % old references and create new ones            

        if current_refUpdater<previous_refUpdater||mean(pixDev)>8
            
            % If noise is above threshold: reset reference stack,
            % aboveThresh, and pixDev
            % Otherwise, just update the stack with a new reference
            if mean(pixDev)>10
               refStack=repmat(imagedata,1,1,ref_stack_size);
               refImage=uint8(mean(refStack,3));
               aboveThresh=ones(10,1)*pixMean;
               pixDev=ones(10,1);
               disp('NOISE THRESHOLD REACHED, REFERENCES RESET')
            else
               % Update reference
               refCount=refCount+1;
               refStack(:,:,mod(refCount,ref_stack_size)+1)=imagedata;
               refImage=uint8(mean(refStack,3));
               % Update vignette offset matrix with better reference
               vignetteMat=filterVignetting(refImage,binaryimage,ROI_coords);
            end       
        end 
        previous_refUpdater=current_refUpdater;
   
    if get(handles.pause_togglebutton, 'Value') == 1;
        p1 = toc;
        waitfor(handles.pause_togglebutton, 'Value', 0)
        pt = toc-p1+pt;
    end
    
end

%% Pull in ASCII data, format into matrices

disp('Experiment Complete')
disp('Importing Data - may take a few minutes...')

% Initialize data struct
flyTracks=[];
flyTracks.exp='Y-maze';
flyTracks.nFlies = size(ROI_coords,1);

% Import time stamp, orientation, turn, and centroid data and store in
% struct
flyTracks.rightTurns=dlmread(turnID);
flyTracks.mazeOri=mazeOri;
flyTracks.labels = readtable(labelID);

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

flyTracks.centroid=centroid;

%% Find index of first turn for each fly and discard to eliminate tracking artifacts

turns=flyTracks.rightTurns;
[r,c]=find(~isnan(turns));
c=[0;c];
t1rows=r(find(diff(c)));
c(1)=[];
t1cols=unique(c);

for i=1:length(t1cols)
    turns(t1rows(i),t1cols(i))=NaN;
end

% Update turn data with false turns discarded
flyTracks.rightTurns=turns;

%% Calculate turn probability
numTurns=sum(~isnan(turns));
flyTracks.numTurns=numTurns;
flyTracks.tSeq=NaN(max(flyTracks.numTurns),flyTracks.nFlies);

%{
Start by converting arm number turn sequence into compressed right turn
sequence by taking difference between subsequent maze arms. For either orientation 
of a maze, arms are 1 to 3 left to right. For example, for a rightside-up Y, 
right turns would be 1-3=-2, 3-2=1, and 2-1=1. The opposite is true for the
opposite orientation of a maze. In the output, tSeq, Right turns = 1, Left
turns = 0.
%}
for i=1:flyTracks.nFlies
    tSeq=flyTracks.rightTurns(~isnan(flyTracks.rightTurns(:,i)),i);
    tSeq=diff(tSeq);
    if flyTracks.mazeOri(i)
        flyTracks.tSeq(1:length(tSeq),i)=tSeq==1|tSeq==-2;
    elseif ~flyTracks.mazeOri(i)
        flyTracks.tSeq(1:length(tSeq),i)=tSeq==-1|tSeq==2;
    end
end

% Calculate right turn probability from tSeq
flyTracks.rBias=nansum(flyTracks.tSeq)./nansum(~isnan(flyTracks.tSeq));

%% Save data to struct
strain(ismember(strain,' ')) = [];
save(strcat(handles.fpath,'\',t,'Ymaze','_',strain,'.mat'),'flyTracks');


%% Plot histograms of the data

inc=0.05;
bins=-inc/2:inc:1+inc/2;   % Bins centered from 0 to 1 

c=histc(flyTracks.rBias(flyTracks.numTurns>40),bins); % histogram
mad(flyTracks.rBias(flyTracks.numTurns>40))           % MAD of right turn prob
c=c./(sum(c));
c(end)=[];
plot(c,'Linewidth',2);
set(gca,'Xtick',(1:length(c)),'XtickLabel',0:inc:1);
axis([0 length(bins) 0 max(c)+0.05]);

% Generate legend labels
strain='';
treatment='';
if iscellstr(flyTracks.labels{1,1})
    strain=flyTracks.labels{1,1}{:};
end
if iscellstr(flyTracks.labels{1,3})
    treatment=flyTracks.labels{1,3}{:};
end
legend([strain ' ' treatment ' (u=' num2str(mean(flyTracks.rBias(flyTracks.numTurns>40)))...
    ', n=' num2str(sum(flyTracks.numTurns>40)) ')']);
shg

%% Display command to load data struct into workspace

disp('Execute the following command to load your data into the workspace:')
disp(['load(',char(39),strcat(handles.fpath,'\',t,'Ymaze','_',strain,'.mat'),char(39),');'])

%% Set MATLAB priority to Above Normal via Windows Command Line
cmd_str = 'wmic process where name="MATLAB.exe" CALL setpriority 32768';
[~,~] = system(cmd_str);

clearvars -except handles