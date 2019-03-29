function [expmt]=gridROIs(gui_handles, expmt)
%
% A manual alternative to the standard automated ROI setting function (autoROIs)
% that works by assuming a regular grid-like structure to the ROIs. Takes
% number of rows and columns to produce a regularly spaced grid inside of a
% user drawn rectangle. NOTE: This function is specifically intended for
% use with a 96-well plate where automated ROI detection is difficult but
% the arenas have a very rigidly defined structure.

warning off MATLAB:structOnObject
clearvars -except gui_handles expmt
colormap('gray')

gui_notify('running ROI detection',gui_handles.disp_note);
gui_handles.auto_detect_ROIs_pushbutton.Enable = 'off';
gui_handles.grid_ROI_uipanel.Position(1) = gui_handles.bottom_uipanel.Position(1);
gui_handles.grid_ROI_uipanel.Position(2) = gui_handles.bottom_uipanel.Position(2);
gui_handles.grid_ROI_uipanel.Visible = 'on';
height = gui_handles.bottom_uipanel.Position(4) + ...
    gui_handles.run_uipanel.Position(4) + gui_handles.exp_uipanel.Position(4);
gui_handles.grid_ROI_uipanel.Position(4) = height;
y_shift = height - gui_handles.text48.Position(2) - ...
    gui_handles.add_ROI_pushbutton.Position(4)*2;
gui_handles.grid_ROI_uipanel.UserData(2) = gui_handles.grid_ROI_uipanel.Position(2);
all_ctls = findobj(gui_handles.grid_ROI_uipanel,'-depth',2,'Type','uicontrol');
for i=1:numel(all_ctls)
    all_ctls(i).Position(2) =  all_ctls(i).Position(2) + y_shift;
end
hAdd = gui_handles.add_ROI_pushbutton;


% Setup the camera and/or video object
expmt = getVideoInput(expmt,gui_handles);

%% Grab image for ROI detection and segment out ROIs

clean_gui(gui_handles.axes_handle);
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','Image');

switch expmt.meta.source
    case 'camera'
        trackDat.im = peekdata(expmt.hardware.cam.vid,1);
    case 'video'
        [trackDat.im, expmt.meta.video] = nextFrame(expmt.meta.video,gui_handles);
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
gui_handles.axes_handle.CLim = [0 255];

% reset accept ROI pushbutton if necessary
gui_handles.accept_ROI_thresh_pushbutton.Value = 0;

%% initialize grids

delete(findobj('Type','Patch'));
nGrids = gui_handles.add_ROI_pushbutton.UserData.nGrids;
if nGrids > 0 && ~isempty(hAdd.UserData.grid(1).polypos)
    % re-initialize interactible polygons
    for i=1:nGrids
        xdat = hAdd.UserData.grid(i).XData;
        ydat = hAdd.UserData.grid(i).YData;
        switch hAdd.UserData.grid(i).shape
            case 'Circular'
                [hAdd.UserData.grid(i).tform,circDat] = transformROI(xdat,ydat);
                hPatch(i) = patch('Faces',1:size(xdat,2),...
                    'XData',circDat(:,:,1),'YData',circDat(:,:,2),'FaceColor','none',...
                    'EdgeColor','r','Parent',gui_handles.axes_handle);
            case 'Quadrilateral'
                hPatch(i) = patch('Faces',1:size(xdat,2),...
                    'XData',xdat,'YData',ydat,'FaceColor','none',...
                    'EdgeColor','r','Parent',gui_handles.axes_handle);
        end
        hAdd.UserData.grid(i).hp  = impoly(gui_handles.axes_handle, ...
            hAdd.UserData.grid(i).polypos);
        hAdd.UserData.grid(i).hp.Deletable = false;
        grid_props = struct(hAdd.UserData.grid(i).hp);
        h_vertices = findall(grid_props.h_group,'Tag','impoly vertex');
        context_menus = get(h_vertices,'UIContextMenu');
        cellfun(@(hmenu) delete(hmenu), context_menus);
    end
else
    % prompt user to draw new rectangle
    [gui_handles,hPatch]=drawGrid(1,gui_handles); 
    if isempty(hPatch)
        % hide the grid settings panel
        gui_handles.grid_ROI_uipanel.Visible = 'off';
        return
    else
        gui_handles.add_ROI_pushbutton.UserData.nGrids = 1;
        nGrids = 1;
    end
end

old_dim = cell(nGrids,1);
old_coords = cell(nGrids,1);
for i=1:nGrids
    nRow = hAdd.UserData.grid(1).nRows;
    nCol = hAdd.UserData.grid(1).nCols;
    old_dim(i) = {[nRow nCol]};
    old_coords(i) = {getPosition(gui_handles.add_ROI_pushbutton.UserData.grid(i).hp)};
    old_shape(i) = {hAdd.UserData.grid(i).shape};
    old_scale(i) = hAdd.UserData.grid(i).scale;
end

% initialize timer
trackDat.t=0;

%% initiate positioning loop


while ~gui_handles.accept_ROI_thresh_pushbutton.Value
    
    tic
    % query next frame and optionally correct lens distortion
    [trackDat,expmt] = autoFrame(trackDat,expmt,gui_handles);
    
    % force user to draw grid if last grid is deleted
    if gui_handles.add_ROI_pushbutton.UserData.nGrids == 0
        if ~isempty(hPatch)
            delete(hPatch(length(hPatch)));
            hPatch = hPatch(1:length(hPatch)-1);
        end
        delete(gui_handles.add_ROI_pushbutton.UserData.grid(1).hp);

        % prompt user to draw new rectangle
        [gui_handles,hPatch]=drawGrid(1,gui_handles); 
        if isempty(hPatch)
            % hide the grid settings panel
            gui_handles.grid_ROI_uipanel.Visible = 'off';
            gui_handles.accept_ROI_thresh_pushbutton.Value = 1;
        else
            gui_handles.add_ROI_pushbutton.UserData.nGrids = 1;
                nRow = hAdd.UserData.grid(1).nRows;
            nCol = hAdd.UserData.grid(1).nCols;
            old_dim(1) = {[nRow nCol]};
            old_coords(1) = {getPosition(gui_handles.add_ROI_pushbutton.UserData.grid(1).hp)};
            old_shape(1) = {hAdd.UserData.grid(1).shape};
            old_scale(1) = hAdd.UserData.grid(1).scale;
        end
    % check for addition or subtraction of grids
    elseif nGrids > gui_handles.add_ROI_pushbutton.UserData.nGrids
        delete(hPatch(length(hPatch)));
        hPatch = hPatch(1:length(hPatch)-1);
    elseif nGrids < gui_handles.add_ROI_pushbutton.UserData.nGrids
        
        % draw new grid
        [gui_handles, hp]=...
            drawGrid(gui_handles.add_ROI_pushbutton.UserData.nGrids,gui_handles);
        
        if ~isempty(hp)
            nGrids = gui_handles.add_ROI_pushbutton.UserData.nGrids;
            hPatch(nGrids) = hp;
            
            % initialize starting row/col dimensions and interactible polygon coords
            old_dim(nGrids) = ...
                {[hAdd.UserData.grid(nGrids).nRows ...
                hAdd.UserData.grid(nGrids).nCols]};
            old_coords(nGrids) = ...
                {getPosition(...
                    gui_handles.add_ROI_pushbutton.UserData.grid(nGrids).hp)};
            old_shape(nGrids) = {hAdd.UserData.grid(nGrids).shape};
            old_scale(nGrids) = hAdd.UserData.grid(nGrids).scale;
        else
            gui_handles = update_grid_UI(gui_handles,'subtract');
        end
    end
    nGrids = gui_handles.add_ROI_pushbutton.UserData.nGrids;
    
    % update data for all grids
    for i=1:nGrids
    
        % get ui rectangle position and infer well centers and radii
        pos = getPosition(gui_handles.add_ROI_pushbutton.UserData.grid(i).hp);
        nRow = hAdd.UserData.grid(i).nRows;
        nCol = hAdd.UserData.grid(i).nCols;
        scale = hAdd.UserData.grid(i).scale;
        [XData,YData] = getGridVertices(pos(:,1),pos(:,2),nRow,nCol, scale);
        hAdd.UserData.grid(i).XData = XData;
        hAdd.UserData.grid(i).YData = YData;

        if any(old_dim{i}~=[nRow nCol]) || ...
                ~strcmp(hAdd.UserData.grid(i).shape,old_shape{i}) || ...
                old_scale(i) ~= scale
            
            % remove old patch and draw now one if dimensions change
            delete(hPatch(i));
            switch hAdd.UserData.grid(i).shape
                case 'Circular'
                    [hAdd.UserData.grid(i).tform,circDat] = transformROI(XData,YData);
                    hPatch(i) = patch('Faces',1:size(XData,2),...
                        'XData',circDat(:,:,1),'YData',circDat(:,:,2),'FaceColor','none',...
                        'EdgeColor','r','Parent',gui_handles.axes_handle);
                case 'Quadrilateral'
                    hPatch(i) = patch('Faces',1:size(XData,2),...
                        'XData',XData,'YData',YData,'FaceColor','none',...
                        'EdgeColor','r','Parent',gui_handles.axes_handle);
            end
            uistack(hPatch(i),'down');
            
            % update current dimensions
            old_dim(i) = {[nRow nCol]};
            old_shape(i) = {hAdd.UserData.grid(i).shape};
            old_scale(i) = hAdd.UserData.grid(i).scale;
        
        elseif any(old_coords{i}(:)~=pos(:))
            old_coords(i) = {pos};
            switch hAdd.UserData.grid(i).shape
                case 'Circular'
                    [hAdd.UserData.grid(i).tform,circDat] = transformROI(XData,YData);
                    hPatch(i).XData = circDat(:,:,1);
                    hPatch(i).YData = circDat(:,:,2);
                case 'Quadrilateral'
                    hPatch(i).XData = XData;
                    hPatch(i).YData = YData;
            end
        end
        
    end
    
    % update the display
    autoDisplay(trackDat, expmt, imh, gui_handles);

    % Report frames per sec to GUI
    set(gui_handles.edit_frame_rate,'String',num2str(round(1/toc)));
    drawnow limitrate
    
end

%%

% hide the grid settings panel
gui_handles.grid_ROI_uipanel.Visible = 'off';
expmt = getGridROIProps(hAdd.UserData.grid, nGrids, expmt, gui_handles);
delete(hPatch);
expmt.meta.roi.im = trackDat.im;

% create a vignette correction image if mode is set to auto
if strcmp(expmt.meta.vignette.mode,'auto') && ~isempty(expmt.meta.roi.corners)
    expmt.meta.vignette.im = ...
        filterVignetting(expmt,expmt.meta.roi.corners(end,:),trackDat.im);
end

% set sort mode to bounds
expmt.parameters.sort_mode = 'bounds';

gui_handles.auto_detect_ROIs_pushbutton.Enable = 'on';
gui_notify([num2str(size(expmt.meta.roi.centers,1)) ' ROIs detected'],gui_handles.disp_note);


