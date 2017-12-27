function [expmt]=gridROIs(gui_handles, expmt)
%
% A manual alternative to the standard automated ROI setting function (autoROIs)
% that works by assuming a regular grid-like structure to the ROIs. Takes
% number of rows and columns to produce a regularly spaced grid inside of a
% user drawn rectangle. NOTE: This function is specifically intended for
% use with a 96-well plate where automated ROI detection is difficult but
% the arenas have a very rigidly defined structure.


clearvars -except gui_handles expmt
colormap('gray')

gui_notify('running ROI detection',gui_handles.disp_note);
gui_handles.auto_detect_ROIs_pushbutton.Enable = 'off';

%% Define parameters - adjust parameters here to fix tracking and ROI segmentation errors

gui_fig = gui_handles.gui_fig;

% ROI detection parameters 
sigma=0.47;                                 % Sigma expressed as a fraction of the image height
kernelWeight=0.34;                          % Scalar weighting of kernel when applied to the image

%% Setup the camera and/or video object

expmt = getVideoInput(expmt,gui_handles);

%% Grab image for ROI detection and segment out ROIs

clean_gui(gui_handles.axes_handle);
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','Image');

switch expmt.source
    case 'camera'
        trackDat.im = peekdata(expmt.camInfo.vid,1);
    case 'video'
        [trackDat.im, expmt.video] = nextFrame(expmt.video,gui_handles);
end

% Extract green channel if image is RGB
if size(trackDat.im,3) > 1
    trackDat.im=trackDat.im(:,:,2);
end

if isempty(imh)
    imh = imagesc(trackDat.im);
elseif strcmp(imh.CDataMapping,'direct')
   imh.CDataMapping = 'scaled';
end


gui_handles.accept_ROI_thresh_pushbutton.Value = 0;
clearvars hRect hText

hRect(1) = rectangle('Position',[0 0 0 0],'EdgeColor','r');
hText(1) = text(0,0,'1','Color','b');

% get drawn rectangle from user outlining well plate boundary
roi = getrect();
nRow = 8;
nCol = 12;

% get coordinates of vertices from rectangle bounds
polyPos = NaN(4,2);                                 
polyPos(1,:) = [sum(roi([1 3])) roi(2)];
polyPos(2,:) = [sum(roi([1 3])) sum(roi([2 4]))];
polyPos(3,:) = [roi(1) sum(roi([2 4]))];
polyPos(4,:) = [roi(1) roi(2)];

% create interactible polygon
hPoly = impoly(gui_handles.axes_handle, polyPos);

% generate grid of well coordinates from polygon
centers=NaN(nRow*nCol,2);
x = (roi(1):roi(3)/(nCol+1):sum(roi([1 3])))';
x = x(2:length(x)-1);
centers(:,1) = repmat(x,nRow,1);
y = (roi(2):roi(4)/(nRow+1):sum(roi([2 4])))';
y = y(2:length(y)-1);

% sort coordinates from top left to bottom right
centers(:,2) = sort(repmat(y,nCol,1));
[centers] = find96WellPlate(polyPos(:,1),polyPos(:,2));
r = median(diff(centers(:,1)))/2;
bounds = centerRect(centers,r);

% draw circles over wells
for i = 1:size(centers,1)
    hCirc(i) = rectangle(gui_handles.axes_handle,'Position',bounds(i,:),...
        'EdgeColor',[1 0 0],'Curvature',[1 1],'LineWidth',1.5);
end    
uistack(hCirc,'down');

% initialize timer
tic
trackDat.t=0;
tPrev = toc;
trackDat.tStamp = zeros(size(centers,1),1);

%% initiate positioning loop


while ~gui_handles.accept_ROI_thresh_pushbutton.Value
    
    tic
    stop=get(gui_handles.accept_ROI_thresh_pushbutton,'value');
    pause(0.1);


    % query next frame and optionally correct lens distortion
    [trackDat,expmt] = autoFrame(trackDat,expmt,gui_handles);
    
    % Extract green channel if image is RGB
    if size(trackDat.im,3) > 1
        trackDat.im=trackDat.im(:,:,2);
    end
    
    % get ui rectangle position and infer well centers and radii
    pos = getPosition(hPoly);
    centers = find96WellPlate(pos(:,1),pos(:,2));
    r = median(abs(diff(centers(:,1))))/2;
    
    % update circle positions in the axes
    bounds = centerRect(centers,r);
    db = num2cell(bounds,2);
    arrayfun(@updateCircles,hCirc',db);
    
    % update the display
    updateDisplay(trackDat, expmt, imh, gui_handles);
    drawnow limitrate

    % Report frames per sec to GUI
    set(gui_handles.edit_frame_rate,'String',num2str(round(1/toc)));
    
end

%%

gui_notify([num2str(size(centers,1)) ' ROIs detected'],gui_handles.disp_note);

% Reset the accept threshold button
set(gui_handles.accept_ROI_thresh_pushbutton,'value',0);

ROI_coords = [bounds(:,1) bounds(:,2) sum(bounds(:,[1 3]),2) sum(bounds(:,[2 4]),2)];
mazeOri = false(size(centers,1),1);

% create a vignette correction image if mode is set to auto
if strcmp(expmt.vignette.mode,'auto') && ~isempty(ROI_coords)
    expmt.vignette.im = filterVignetting(trackDat.im,ROI_coords(end,:));
end

delete(hPoly);
delete(hCirc);

% assign outputs
if ~isempty(ROI_coords)
    expmt.ROI.corners = ROI_coords;
    expmt.ROI.centers = centers;
    expmt.ROI.orientation = mazeOri;
    expmt.ROI.bounds = bounds;
    expmt.ROI.im = trackDat.im;
end

gui_handles.auto_detect_ROIs_pushbutton.Enable = 'on';


function updateCircles(h,bounds)

h.Position = bounds{:};
