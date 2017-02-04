function [expmt] = initializeRef(handles,expmt)


clearvars -except handles expmt

% enable display adjustment and set set the view to thresholded by default
colormap('gray');
set(handles.display_raw_menu,'Enable','on');
set(handles.display_difference_menu,'Enable','on');
set(handles.display_threshold_menu,'Enable','on');
set(handles.display_reference_menu,'checked','on');
set(handles.display_none_menu,'Enable','on');
handles.display_menu.UserData = 3;

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

%% Assign parameters and placeholders

ref = peekdata(vid,1);
if size(ref,3)>2
    ref=ref(:,:,2);                         % Assign reference image
end
pause(0.1);

nROIs = size(expmt.ROI.corners, 1);
lastCentroid=expmt.ROI.centers;             % placeholder for most recent non-NaN centroids
referenceCentroids=zeros(nROIs, 2, 10);     % placeholder for cen. coords where references are taken
propFields={'Centroid';'Area'};             % Define fields for regionprops
nRefs=zeros(nROIs, 1);                      % Reference number placeholder
centStamp=zeros(nROIs,1);
vignetteMat=filterVignetting(ref,expmt.ROI.im,expmt.ROI.corners);

% Set maximum allowable distance to center of ROI as the long axis of the ROI
widths=(expmt.ROI.bounds(:,3));
heights=(expmt.ROI.bounds(:,4));
w=median(widths);
h=median(heights);
expmt.parameters.distanceThresh=sqrt(w^2+h^2)/2*0.95;

% set min distance from previous ref locations before acquiring new ref for any given object
min_dist = expmt.parameters.distanceThresh * 0.2;    

% Calculate threshold for distance to end of maze arms for turn scoring
mazeLengths=mean([widths heights],2);
expmt.parameters.armThresh=mazeLengths*0.2;

%% Collect reference until timeout OR "accept reference" GUI press

% initialize display objects
cla reset
res = vid.videoResolution;
blank = zeros(res(2),res(1));
axh = imagesc(blank);
set(gca,'Xtick',[],'Ytick',[]);
clearvars hCirc hText
hsv_base = 360;
hsv_targ = 240;
color_scale = 1 - hsv_targ/hsv_base;
hold on
for i = 1:nROIs
    hCirc(i) = plot(expmt.ROI.corners(i,1),expmt.ROI.corners(i,2),'o','Color',[1 0 0],'LineWidth',3);
    hText(i) = text(expmt.ROI.centers(i,1),expmt.ROI.centers(i,2),num2str(i),'Color','m');
end
hold off

% Time stamp placeholders
tElapsed=0;
tic
previous_tStamp=toc;
current_tStamp=0; 

while toc<60 && get(handles.accept_track_thresh_pushbutton,'value')~=1
    
    % Update image threshold value from GUI
    imageThresh=get(handles.track_thresh_slider,'value');
    
    % Update tStamps
    current_tStamp=toc;
    set(handles.edit_frame_rate,'String',num2str(round(1/(current_tStamp-previous_tStamp))));
    tElapsed=tElapsed+current_tStamp-previous_tStamp;
    previous_tStamp=current_tStamp;
    
    % Report time remaining to reference timeout to GUI
    timeRemaining = round(60 - toc);
    updateTimeString(timeRemaining, handles.edit_time_remaining);

    % Grab image and sort tracked objects to ROIs
    
    imagedata=peekdata(vid,1);

    if size(imagedata,3)>2
        imagedata=imagedata(:,:,2);
    end
    diffim=(ref-vignetteMat)-(imagedata-vignetteMat);

    % Extract regionprops and record centroid for blobs with (11 > area > 30) pixels
    props=regionprops((diffim>imageThresh),propFields);
    validCentroids=([props.Area]>4&[props.Area]<120);
    cenDat=reshape([props(validCentroids).Centroid],2,length([props(validCentroids).Centroid])/2)';

    % Match centroids to ROIs by finding nearest ROI center
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
    

    % Average in new ref for each fly > min_dist from previous reference locations
    
    for i=1:nROIs

        % Calculate distance to previous locations where references were taken
        tCen=repmat(lastCentroid(i,:),size(referenceCentroids,3),1);
        d=abs(sqrt(dot((tCen-squeeze(referenceCentroids(i,:,:))'),(squeeze(referenceCentroids(i,:,:))'-tCen),2)));

        % Create a new reference image for the ROI if fly is greater than distance thresh
        % from previous reference locations
        if ~any(d < min_dist) && ~any(isnan(lastCentroid(i,:)))

            nRefs(i)=sum(sum(referenceCentroids(i,:,:)>0));
            referenceCentroids(i,:,mod(nRefs(i)+1,10))=lastCentroid(i,:);
            newRef=imagedata(expmt.ROI.corners(i,2):expmt.ROI.corners(i,4),expmt.ROI.corners(i,1):expmt.ROI.corners(i,3));
            oldRef=ref(expmt.ROI.corners(i,2):expmt.ROI.corners(i,4),expmt.ROI.corners(i,1):expmt.ROI.corners(i,3));
            nRefs(i)=sum(sum(referenceCentroids(i,:,:)>0));                                         % Update num Refs
            averagedRef=newRef.*(1/nRefs(i))+oldRef.*(1-(1/nRefs(i)));               % Weight new reference by 1/nRefs
            ref(expmt.ROI.corners(i,2):expmt.ROI.corners(i,4),expmt.ROI.corners(i,1):expmt.ROI.corners(i,3))=averagedRef;
            
            % Update color indicator
            
            hsv_color = [1-color_scale*nRefs(i)/size(referenceCentroids,3) 1 1];
            hCirc(i).Color = hsv2rgb(hsv_color);

        end
    end
    
    %handles.display_menu.UserData
    % Update display
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
       for i=1:nROIs
           hText(i).Position = [lastCentroid(i,1) lastCentroid(i,2)];
       end
    end
    drawnow
    
end

%% Reset UI properties

% Reset accept reference button
set(handles.accept_track_thresh_pushbutton,'value',0);

% disable display control
set(handles.display_raw_menu,'Enable','off');
set(handles.display_difference_menu,'Enable','off');
set(handles.display_threshold_menu,'Enable','off');
set(handles.display_reference_menu,'checked','off');
set(handles.display_none_menu,'Enable','off');

% Set time to zero
updateTimeString(0, handles.edit_time_remaining);

% assign outputs
expmt.ref = ref;
expmt.vignetteMat = vignetteMat;