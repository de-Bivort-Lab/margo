function [expmt] = sampleNoise(gui_handles, expmt)
% 
% Samples the background noise distribution prior to imaging for the
% purpose of determining when to force reset background reference images.
% For the sampling to accurate, it is important for the tracking during the
% sampling period to be clean (ie. majority of the tracked objects appear
% above the imaging threshold with few above-threshold pixels due to
% noise).

gui_fig = gui_handles.gui_fig;
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','image');   % image handle


%% Sampling Parameters

pixDistSize=100;                    % Num values to record in p
pixelDist=NaN(pixDistSize,1);       % Distribution of total number of pixels above image threshold

% tracking vars
trackDat.lastCen=expmt.ROI.centers;     % placeholder for most recent non-NaN centroids
trackDat.fields={'Centroid';'Area'};     % Define fields for regionprops
trackDat.tStamp = zeros(size(expmt.ROI.centers(:,1),1),1);
trackDat.t=0;
trackDat.ct = 0;

%% Initalize camera and axes

if strcmp(expmt.camInfo.vid.Running,'off')
    % Clear old video objects
    imaqreset
    pause(0.2);

    % Create camera object with input parameters
    expmt.camInfo = initializeCamera(expmt.camInfo);
    vid = expmt.camInfo.vid;
    start(vid);
    pause(0.1);
else
    vid = expmt.camInfo.vid;
end

%% Sample noise

% initialize display objects
cla reset
res = vid.videoResolution;
blank = zeros(res(2),res(1));
imh = imagesc(blank);
set(gca,'Xtick',[],'Ytick',[]);
clearvars hCirc
hold on
hCirc = plot(expmt.ROI.centers(:,1),expmt.ROI.centers(:,2),'o','Color',[1 0 0]);
hold off

tic
tPrev = toc;

while trackDat.ct < pixDistSize;

        % update time stamps and frame rate
        [trackDat, tPrev] = updateTime(trackDat, tPrev, gui_handles);

        % Get centroids and sort to ROIs
        trackDat.im=peekdata(vid,1);
        if size(trackDat.im,3)>1
            trackDat.im=trackDat.im(:,:,2);
        end
        
        % track objects and sort to ROIs
        [trackDat] = autoTrack(trackDat,expmt,gui_handles);
        
        %Update display if display tracking is ON
        if gui_handles.display_menu.UserData ~= 5
            
            % update the display
            updateDisplay(trackDat, expmt, imh, gui_handles);

           % Draw last known centroid for each ROI and update ref. number indicator
           hCirc.XData = trackDat.lastCen(:,1);
           hCirc.YData = trackDat.lastCen(:,2);
           
        end
        drawnow


       % Create distribution for num pixels above imageThresh
       % Image statistics used later during acquisition to detect noise
       pixelDist(mod(trackDat.ct,pixDistSize)+1) = nansum(nansum(trackDat.im > gui_handles.track_thresh_slider.Value));
   
end

% Record stdDev and mean without noise
pixStd=nanstd(pixelDist);
pixMean=nanmean(pixelDist);    

% Assign outputs
expmt.noise.dist = pixelDist;
expmt.noise.std = nanstd(pixelDist);
expmt.noise.mean = nanmean(pixelDist);

