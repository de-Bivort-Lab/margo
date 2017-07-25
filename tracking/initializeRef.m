function [expmt] = initializeRef(gui_handles,expmt)


clearvars -except gui_handles expmt

gui_notify('initializing reference',gui_handles.disp_note);

gui_fig = gui_handles.gui_fig;
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','image');   % image handle

if isempty(imh)
        % Take single frame
    switch expmt.source
        case 'camera'
            trackDat.im = peekdata(expmt.camInfo.vid,1);
        case 'video'
            [trackDat.im, expmt.video] = nextFrame(expmt.video,gui_handles);
    end
    imh = imagesc(trackDat.im);
elseif strcmp(imh.CDataMapping,'direct')
   imh.CDataMapping = 'scaled';
end

% enable display adjustment and set set the view to thresholded by default
colormap('gray');
set(gui_handles.display_menu.Children,'Enable','on');
set(gui_handles.display_menu.Children,'Checked','off');
set(gui_handles.display_threshold_menu,'Checked','on');
gui_handles.display_menu.UserData = 3;

gui_handles.accept_track_thresh_pushbutton.Value = 0;

%% Setup the camera and/or video object

expmt = getVideoInput(expmt,gui_handles);

%% Assign parameters and placeholders

% Initialize reference with single image
if strcmp(expmt.source,'camera')
    expmt.ref = peekdata(expmt.camInfo.vid,1);
else
    [expmt.ref, expmt.video] = nextFrame(expmt.video,gui_handles);
end

if size(expmt.ref,3)>2
    expmt.ref=expmt.ref(:,:,2);                         
end
pause(0.1);

% Reference vars
nROIs = size(expmt.ROI.corners, 1);  % total number of ROIs
ref_cen=zeros(nROIs, 2, 10);         % placeholder for cen. coords where references are taken
nRefs=zeros(nROIs, 1);               % Reference number placeholder
rois = round(expmt.ROI.corners);     % temporarily round ROI coords for indexing

% tracking vars
trackDat.fields={'Centroid';'Area'};            % Define fields for regionprops
trackDat.Centroid=expmt.ROI.centers;             % placeholder for most recent non-NaN centroids
trackDat.tStamp=zeros(nROIs,1);
trackDat.ct = 0;


% Set maximum allowable distance to center of ROI as the long axis of the ROI
widths=(expmt.ROI.bounds(:,3));
heights=(expmt.ROI.bounds(:,4));
w=median(widths);
h=median(heights);
gui_fig.UserData.distance_thresh=round(sqrt(w^2+h^2)/2*0.9*10)/10 * expmt.parameters.mm_per_pix;
gui_handles.edit_dist_thresh.String = num2str(gui_fig.UserData.distance_thresh);

% set min distance from previous ref locations before acquiring new ref for any given object
min_dist = gui_fig.UserData.distance_thresh * 0.2;    


%% initialize display objects

clean_gui(gui_handles.axes_handle);
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','Image');
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
tPrev = toc - gui_handles.edit_exp_duration.Value*3600 + 60;

while trackDat.t < expmt.parameters.duration*3600 &&...
        ~gui_handles.accept_track_thresh_pushbutton.Value
    
    % update time stamps and frame rate
    [trackDat, tPrev] = updateTime(trackDat, tPrev, expmt, gui_handles);

    % query next frame and optionally correct lens distortion
    [trackDat,expmt] = autoFrame(trackDat,expmt,gui_handles);

    % track objects and sort to ROIs
    [trackDat] = autoTrack(trackDat,expmt,gui_handles);

    % Average in new ref for each fly > min_dist from previous reference locations
    for i=1:nROIs

        % Calculate distance to previous locations where references were taken
        tCen = repmat(trackDat.Centroid(i,:),size(ref_cen,3),1);
        d = abs(sqrt(dot((tCen-squeeze(ref_cen(i,:,:))'),(squeeze(ref_cen(i,:,:))'-tCen),2)));

        % Create a new reference image for the ROI if fly is greater than distance thresh
        % from previous reference locations
        if ~any(d < min_dist) && ~any(isnan(trackDat.Centroid(i,:)))

            nRefs(i)=sum(sum(ref_cen(i,:,:)>0));                                % update nrefs
            ref_cen(i,:,mod(nRefs(i)+1,10))=trackDat.Centroid(i,:);
            newRef=trackDat.im(rois(i,2):rois(i,4),rois(i,1):rois(i,3));        % grab new ref from im
            oldRef=expmt.ref(rois(i,2):rois(i,4),rois(i,1):rois(i,3));          % save prev ref
            nRefs(i)=sum(sum(ref_cen(i,:,:)>0));                                % Update num Refs
            averagedRef=newRef.*(1/nRefs(i))+oldRef.*(1-(1/nRefs(i)));          % Weight new reference by 1/nRefs
            expmt.ref(rois(i,2):rois(i,4),rois(i,1):rois(i,3)) = averagedRef;
            
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
       tcen = num2cell(trackDat.Centroid,2);
       arrayfun(@updateText,hText',tcen);
       
    end
    
    drawnow limitrate
    
end

%% Reset UI properties
trackDat.t = 0;
tic
tPrev = toc;
[trackDat, tPrev] = updateTime(trackDat, tPrev, expmt, gui_handles);

% Reset accept reference button
set(gui_handles.accept_track_thresh_pushbutton,'value',0);

% disable display control
set(gui_handles.display_menu.Children,'Enable','off');
set(gui_handles.display_menu.Children,'Checked','off');
gui_handles.display_raw_menu.Checked = 'on';
gui_handles.display_menu.UserData = 1;

% Set time to zero
if strcmp(expmt.source,'camera')
    updateTimeString(0, gui_handles.edit_time_remaining);
end

function updateText(h,pos)

h.Position = pos{:};