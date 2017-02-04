function [expmt] = sampleNoise(handles, expmt)
% 
% Samples the background noise distribution prior to imaging for the
% purpose of determining when to force reset background reference images.
% For the sampling to accurate, it is important for the tracking during the
% sampling period to be clean (ie. majority of the tracked objects appear
% above the imaging threshold with few above-threshold pixels due to
% noise).


%% Sampling Parameters

ct=1;                               % Frame counter
pixDistSize=100;                    % Num values to record in p
pixelDist=NaN(pixDistSize,1);       % Distribution of total number of pixels above image threshold
lastCentroid=expmt.ROI.centers;     % placeholder for most recent non-NaN centroids
propFields={'Centroid';'Area'};     % Define fields for regionprops

tElapsed=0;

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
axh = imagesc(blank);
set(gca,'Xtick',[],'Ytick',[]);
clearvars hCirc
hold on
hCirc = plot(expmt.ROI.centers(:,1),expmt.ROI.centers(:,2),'o','Color',[1 0 0]);
hold off

tic
previous_tStamp = toc;
centStamp = zeros(size(expmt.ROI.centers(:,1),1),1);

while ct < pixDistSize;
        
        % Grab image thresh from GUI slider
        imageThresh=get(handles.track_thresh_slider,'value');

        % Update time stamps
        current_tStamp=toc;
        tElapsed=tElapsed+current_tStamp-previous_tStamp;
        previous_tStamp=current_tStamp;
        
        
        % Update number of frames remaining
        set(handles.edit_frame_rate, 'String', num2str(pixDistSize-ct));

        % Get centroids and sort to ROIs
        imagedata=peekdata(vid,1);
        imagedata=imagedata(:,:,2);
        diffim=(expmt.ref-expmt.vignetteMat)-(imagedata-expmt.vignetteMat);
        props=regionprops((diffim>imageThresh),propFields);

        % Match centroids to ROIs by finding nearest ROI center
        validCentroids=([props.Area]>4&[props.Area]<120);
        cenDat=reshape([props(validCentroids).Centroid],2,length([props(validCentroids).Centroid])/2)';

        % Match centroids to last known centroid positions
        [cen_permutation,update_centroid]=matchCentroids2ROIs(cenDat,lastCentroid,expmt.ROI.centers,expmt.parameters.distanceThresh);

        % Apply speed threshold to centroid tracking
        if any(update_centroid)
            d = sqrt([cenDat(cen_permutation,1)-lastCentroid(update_centroid,1)].^2 + [cenDat(cen_permutation,2)-lastCentroid(update_centroid,2)].^2);
            dt = tElapsed-centStamp(update_centroid);
            speed = d./dt;
            above_spd_thresh = speed > expmt.parameters.speed_thresh;
            cen_permutation(above_spd_thresh)=[];
            update_centroid=find(update_centroid);
            update_centroid(above_spd_thresh)=[];
        end

        % Use permutation vector to sort raw centroid data and update
        % vector to specify which centroids are reliable and should be updated
        lastCentroid(update_centroid,:)=cenDat(cen_permutation,:);
        centStamp(update_centroid) = tElapsed;

       %Update display if display tracking is ON
        if handles.display_menu.UserData ~= 5
           switch handles.display_menu.UserData
                case 1
                    axh.CData = imagedata;
                case 2
                    axh.CData = diffim;
                case 3
                    axh.CData = diffim>imageThresh;
               case 4
                    axh.CData = ref;
           end

           % Draw last known centroid for each ROI and update ref. number indicator
           hCirc.XData = lastCentroid(:,1);
           hCirc.YData = lastCentroid(:,2);
        end
        drawnow


       % Create distribution for num pixels above imageThresh
       % Image statistics used later during acquisition to detect noise
       pixelDist(mod(ct,pixDistSize)+1)=nansum(nansum(imagedata>imageThresh));
       ct=ct+1;
   
end

% Record stdDev and mean without noise
pixStd=nanstd(pixelDist);
pixMean=nanmean(pixelDist);    

% Assign outputs
expmt.noise.dist = pixelDist;
expmt.noise.std = nanstd(pixelDist);
expmt.noise.mean = nanmean(pixelDist);

