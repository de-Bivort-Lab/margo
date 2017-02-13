function [expmt] = initializeRef(gui_handles,expmt)


clearvars -except gui_handles expmt

gui_fig = gui_handles.gui_fig;
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','image');   % image handle

% enable display adjustment and set set the view to thresholded by default
colormap('gray');
set(gui_handles.display_raw_menu,'Enable','on');
set(gui_handles.display_difference_menu,'Enable','on');
set(gui_handles.display_threshold_menu,'Enable','on');
set(gui_handles.display_reference_menu,'checked','on');
set(gui_handles.display_none_menu,'Enable','on');
gui_handles.display_menu.UserData = 3;

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

% Initialize reference with single image
expmt.ref = peekdata(vid,1);
if size(expmt.ref,3)>2
    expmt.ref=expmt.ref(:,:,2);                         
end
pause(0.1);

% Reference vars
nROIs = size(expmt.ROI.corners, 1);  % total number of ROIs
ref_cen=zeros(nROIs, 2, 10);         % placeholder for cen. coords where references are taken
nRefs=zeros(nROIs, 1);               % Reference number placeholder

% tracking vars
trackDat.fields={'Centroid';'Area'};            % Define fields for regionprops
trackDat.lastCen=expmt.ROI.centers;             % placeholder for most recent non-NaN centroids
trackDat.tStamp=zeros(nROIs,1);
trackDat.ct = 0;
expmt.vignetteMat=filterVignetting(expmt.ref,expmt.ROI.im,expmt.ROI.corners);

% Set maximum allowable distance to center of ROI as the long axis of the ROI
widths=(expmt.ROI.bounds(:,3));
heights=(expmt.ROI.bounds(:,4));
w=median(widths);
h=median(heights);
gui_fig.UserData.distance_thresh=round(sqrt(w^2+h^2)/2*0.95*10)/10;

% set min distance from previous ref locations before acquiring new ref for any given object
min_dist = gui_fig.UserData.distance_thresh * 0.2;    

% Calculate threshold for distance to end of maze arms for turn scoring
mazeLengths=mean([widths heights],2);
expmt.parameters.armThresh=mazeLengths*0.2;


%% initialize display objects

cla reset                           % clear axes
res = vid.videoResolution;          % video resolution
blank = zeros(res(2),res(1));       % initialize to blank
imh = imagesc(blank);               % image handle
set(gca,'Xtick',[],'Ytick',[]);     % turn off tick marks
clearvars hCirc hText

% Initialize color variables
hsv_base = 360;                         % hsv red
hsv_targ = 240;                         % hsv blue
color_scale = 1 - hsv_targ/hsv_base;

% initialize 
hold on
for i = 1:nROIs
    hCirc(i) = plot(expmt.ROI.corners(i,1),expmt.ROI.corners(i,2),'o','Color',[1 0 0],'MarkerFaceColor',[1 0 0],'LineWidth',2);
    hText(i) = text(expmt.ROI.centers(i,1),expmt.ROI.centers(i,2),num2str(i),'Color','m');
end
hold off


%% Collect reference until timeout OR "accept reference" GUI press

% Time stamp placeholders
trackDat.t = 0;
tic
tPrev=toc;

while toc<60 && get(gui_handles.accept_track_thresh_pushbutton,'value')~=1
    
    % update time stamps and frame rate
    [trackDat, tPrev] = updateTime(trackDat, tPrev, gui_handles);

    % Grab image
    trackDat.im = peekdata(vid,1);
    if size(trackDat.im,3)>2
        trackDat.im = trackDat.im(:,:,2);
    end

    % track objects and sort to ROIs
    [trackDat] = autoTrack(trackDat,expmt,gui_handles);

    % Average in new ref for each fly > min_dist from previous reference locations
    for i=1:nROIs

        % Calculate distance to previous locations where references were taken
        tCen = repmat(trackDat.lastCen(i,:),size(ref_cen,3),1);
        d = abs(sqrt(dot((tCen-squeeze(ref_cen(i,:,:))'),(squeeze(ref_cen(i,:,:))'-tCen),2)));

        % Create a new reference image for the ROI if fly is greater than distance thresh
        % from previous reference locations
        if ~any(d < min_dist) && ~any(isnan(trackDat.lastCen(i,:)))

            nRefs(i)=sum(sum(ref_cen(i,:,:)>0));
            ref_cen(i,:,mod(nRefs(i)+1,10))=trackDat.lastCen(i,:);
            newRef=trackDat.im(expmt.ROI.corners(i,2):expmt.ROI.corners(i,4),expmt.ROI.corners(i,1):expmt.ROI.corners(i,3));
            oldRef=expmt.ref(expmt.ROI.corners(i,2):expmt.ROI.corners(i,4),expmt.ROI.corners(i,1):expmt.ROI.corners(i,3));
            nRefs(i)=sum(sum(ref_cen(i,:,:)>0));                                         % Update num Refs
            averagedRef=newRef.*(1/nRefs(i))+oldRef.*(1-(1/nRefs(i)));               % Weight new reference by 1/nRefs
            expmt.ref(expmt.ROI.corners(i,2):expmt.ROI.corners(i,4),expmt.ROI.corners(i,1):expmt.ROI.corners(i,3))=averagedRef;
            
            % Update color indicator
            
            hsv_color = [1-color_scale*nRefs(i)/size(ref_cen,3) 1 1];
            hCirc(i).Color = hsv2rgb(hsv_color);
            hCirc(i).MarkerFaceColor = hsv2rgb(hsv_color);

        end
    end
    
    % Update display
    if gui_handles.display_menu.UserData ~= 5
        
        % update the display
        updateDisplay(trackDat, expmt, imh, gui_handles);
       
       % Draw last known centroid for each ROI and update ref. number indicator
       for i=1:nROIs
           hText(i).Position = trackDat.lastCen(i,:);
       end
       
    end
    
    drawnow
    
end

%% Reset UI properties

% Reset accept reference button
set(gui_handles.accept_track_thresh_pushbutton,'value',0);

% disable display control
set(gui_handles.display_raw_menu,'Enable','off');
set(gui_handles.display_difference_menu,'Enable','off');
set(gui_handles.display_threshold_menu,'Enable','off');
set(gui_handles.display_reference_menu,'checked','off');
set(gui_handles.display_none_menu,'Enable','off');

% Set time to zero
updateTimeString(0, gui_handles.edit_time_remaining);