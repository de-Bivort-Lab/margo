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
gui_handles.grid_ROI_uipanel.Position(1) = gui_handles.exp_uipanel.Position(1);
gui_handles.grid_ROI_uipanel.Position(2) = gui_handles.exp_uipanel.Position(2);
gui_handles.grid_ROI_uipanel.Visible = 'on';
hAdd = gui_handles.add_ROI_pushbutton;

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

% reset accept ROI pushbutton if necessary
gui_handles.accept_ROI_thresh_pushbutton.Value = 0;

%% initialize grids

delete(findobj('Type','Patch'));
for i=1:length(gui_handles.add_ROI_pushbutton.UserData.grid)-1
    gui_handles = update_grid_UI(gui_handles,'subtract');
end

% prompt user to draw new rectangle
[gui_handles,hPatch]=drawGrid(1,gui_handles);
nRow = hAdd.UserData.grid(1).nRows;
nCol = hAdd.UserData.grid(1).nCols;
old_dim = {[nRow nCol]};
old_coords = {getPosition(gui_handles.add_ROI_pushbutton.UserData.grid(1).hp)};
nGrids = gui_handles.add_ROI_pushbutton.UserData.nGrids;


% initialize timer
tic
trackDat.t=0;
tPrev = toc;
trackDat.tStamp = zeros(size(hPatch.XData,2),1);

%% initiate positioning loop


while ~gui_handles.accept_ROI_thresh_pushbutton.Value
    
    tic

    % query next frame and optionally correct lens distortion
    [trackDat,expmt] = autoFrame(trackDat,expmt,gui_handles);
    
    % check for addition or subtraction of grids
    if nGrids > gui_handles.add_ROI_pushbutton.UserData.nGrids
        delete(hPatch(length(hPatch)));
        hPatch = hPatch(1:length(hPatch)-1);
    elseif nGrids < gui_handles.add_ROI_pushbutton.UserData.nGrids
        
        % draw new grid
        [gui_handles,hPatch(nGrids+1)]=...
            drawGrid(gui_handles.add_ROI_pushbutton.UserData.nGrids,gui_handles);
        nGrids = gui_handles.add_ROI_pushbutton.UserData.nGrids;
        
        % initialize starting row/col dimensions and interactible polygon coords
        old_dim(nGrids) = ...
            {[hAdd.UserData.grid(nGrids).nRows hAdd.UserData.grid(nGrids).nCols]};
        old_coords(nGrids) = ...
            {getPosition(gui_handles.add_ROI_pushbutton.UserData.grid(nGrids).hp)};
    end
    nGrids = gui_handles.add_ROI_pushbutton.UserData.nGrids;
    
    % update data for all grids
    for i=1:nGrids
    
        % get ui rectangle position and infer well centers and radii
        pos = getPosition(gui_handles.add_ROI_pushbutton.UserData.grid(i).hp);
        nRow = hAdd.UserData.grid(i).nRows;
        nCol = hAdd.UserData.grid(i).nCols;
        [XData,YData] = getGridVertices(pos(:,1),pos(:,2),nRow,nCol);

        if any(old_dim{i}~=[nRow nCol])
            
            % remove old patch and draw now one if dimensions change
            delete(hPatch(i));
            hPatch(i) = patch('Faces',1:size(XData,2),'XData',XData,'YData',YData,...
            'FaceColor','none','EdgeColor','r','Parent',gui_handles.axes_handle);
            uistack(hPatch(i),'down');
            
            % update current dimensions
            old_dim(i) = {[nRow nCol]};
        
        elseif any(old_coords{i}(:)~=pos(:))
            old_coords(i) = {pos};
            hPatch(i).XData = XData;
            hPatch(i).YData = YData;
        end
        
    end
    
    % update the display
    updateDisplay(trackDat, expmt, imh, gui_handles);
    drawnow limitrate

    % Report frames per sec to GUI
    set(gui_handles.edit_frame_rate,'String',num2str(round(1/toc)));
    
end

%%

% hide the grid settings panel
gui_handles.grid_ROI_uipanel.Visible = 'off';

% save ROI coordinates for each grid
gridVec = [];
centers = [];
ROI_coords = [];
bounds = [];
mazeOri = [];
grid = [];
c = [];
r = [];
for i=1:nGrids
    
    x = hPatch(i).XData;
    y = hPatch(i).YData;
    centers = [centers; mean(x(1:4,:))' mean(y(1:4,:))'];
    gui_notify([num2str(size(centers,1)) ' ROIs detected'],gui_handles.disp_note);

    % save vectors for tracking
    nRow = hAdd.UserData.grid(i).nRows;
    nCol = hAdd.UserData.grid(i).nCols;
    hAdd.UserData.grid(i).XData = hPatch(i).XData;
    hAdd.UserData.grid(i).YData = hPatch(i).YData;
    pos = getPosition(hAdd.UserData.grid(i).hp);
    [~,~,gv] = getGridVertices(pos(:,1),pos(:,2),nRow,nCol);
    gridVec = [gridVec;gv];


    % Reset the accept threshold button
    set(gui_handles.accept_ROI_thresh_pushbutton,'value',0);

    ROI_coords = [ROI_coords; x(1,:)' y(1,:)' x(3,:)' y(3,:)'];
    bounds = [bounds; x(1,:)' y(1,:)' x(3,:)'-x(1,:)' y(3,:)'-y(1,:)'];
    mazeOri = [mazeOri; false(nRow*nCol,1)];
    grid = [grid; repmat(i,nRow*nCol,1)];
    colIdx = repmat(1:nCol,nRow,1)';
    c = [c; colIdx(:)];
    rowIdx = repmat(1:nRow,nCol,1);
    r = [r; rowIdx(:)];
    
    delete(hAdd.UserData.grid(i).hp);
    delete(hPatch(i));
    
    
end

% create a vignette correction image if mode is set to auto
if strcmp(expmt.vignette.mode,'auto') && ~isempty(ROI_coords)
    expmt.vignette.im = filterVignetting(trackDat.im,ROI_coords(end,:));
end

% set sort mode to bounds
gui_handles.gui_fig.UserData.sort_mode = 'bounds';

% assign outputs
if ~isempty(centers)
    expmt.ROI.vec = gridVec;
    expmt.ROI.row = r;
    expmt.ROI.col = c;
    expmt.ROI.grid = grid;
    expmt.ROI.corners = ROI_coords;
    expmt.ROI.bounds = bounds;
    expmt.ROI.centers = centers;
    expmt.ROI.orientation = mazeOri;
    expmt.ROI.im = trackDat.im;
end

gui_handles.auto_detect_ROIs_pushbutton.Enable = 'on';


function updateCircles(h,bounds)

h.Position = bounds{:};

function hcopy = initializeCircles(href,hparent)

hcopy = copyobj(href,hparent);
