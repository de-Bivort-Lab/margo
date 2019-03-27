function [gui_handles,hPatch]=drawGrid(grid_idx,gui_handles)

% get the current grid
roi_grid = gui_handles.add_ROI_pushbutton.UserData.grid(grid_idx);

axh = gui_handles.axes_handle;
instructions = {'- click and drag to place new grid -'...
    '- reposition grid corners after placement if necessary -'};
hNote = gui_axes_notify(axh, instructions);


% query the enable states of objects in the gui
on_objs = findobj('enable','on');
off_objs = findobj('enable','off');

% disable all gui features during camera initialization
set(findall(gui_handles.gui_fig, '-property', 'enable'), 'enable', 'off');

% get drawn rectangle from user outlining well plate boundary
roi = getrect();
if any(~roi(3:4))
    hPatch = [];
    set(on_objs,'Enable','on');
    cellfun(@delete,hNote);
    return
end

nRow = roi_grid.nRows;
nCol = roi_grid.nCols;

% get coordinates of vertices from rectangle bounds
polyPos = NaN(4,2);                                 
polyPos(1,:) = [sum(roi([1 3])) roi(2)];
polyPos(2,:) = [sum(roi([1 3])) sum(roi([2 4]))];
polyPos(3,:) = [roi(1) sum(roi([2 4]))];
polyPos(4,:) = [roi(1) roi(2)];

% sort coordinates from top left to bottom right
[xData,yData] = getGridVertices(polyPos(:,1),polyPos(:,2),nRow,nCol, roi_grid.scale);

% create interactible polygon
roi_grid.hp = impoly(gui_handles.axes_handle, polyPos);
roi_grid.hp.Deletable = false;
grid_props = struct(roi_grid.hp);
h_vertices = findall(grid_props.h_group,'Tag','impoly vertex');
context_menus = get(h_vertices,'UIContextMenu');
cellfun(@(hmenu) delete(hmenu), context_menus);

switch roi_grid.shape
    case 'Circular'
        [roi_grid.tform,circDat] = transformROI(xData,yData);
        hPatch = patch('Faces',1:size(xData,2),...
            'XData',circDat(:,:,1),'YData',circDat(:,:,2),'FaceColor','none',...
            'EdgeColor','r','Parent',gui_handles.axes_handle);
    case 'Quadrilateral'
        hPatch = patch('Faces',1:size(xData,2),...
            'XData',xData,'YData',yData,'FaceColor','none',...
            'EdgeColor','r','Parent',gui_handles.axes_handle);
end
uistack(hPatch,'down');

set(on_objs,'Enable','on');
cellfun(@delete,hNote);

% reassign grid
gui_handles.add_ROI_pushbutton.UserData.grid(grid_idx) = roi_grid;