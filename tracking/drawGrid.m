function [gui_handles,hPatch]=drawGrid(grid_idx,gui_handles)

% get drawn rectangle from user outlining well plate boundary
roi = getrect();
nRow = gui_handles.add_ROI_pushbutton.UserData.grid(grid_idx).nRows;
nCol = gui_handles.add_ROI_pushbutton.UserData.grid(grid_idx).nCols;

% get coordinates of vertices from rectangle bounds
polyPos = NaN(4,2);                                 
polyPos(1,:) = [sum(roi([1 3])) roi(2)];
polyPos(2,:) = [sum(roi([1 3])) sum(roi([2 4]))];
polyPos(3,:) = [roi(1) sum(roi([2 4]))];
polyPos(4,:) = [roi(1) roi(2)];

% sort coordinates from top left to bottom right
[centers] = getGridCoords(polyPos(:,1),polyPos(:,2),nRow,nCol);
r = median(diff(centers(:,1)))/2;
gui_handles.add_ROI_pushbutton.UserData.grid(grid_idx).bounds = centerRect(centers,r);
gui_handles.add_ROI_pushbutton.UserData.grid(grid_idx).centers = centers;

% create interactible polygon
gui_handles.add_ROI_pushbutton.UserData.grid(grid_idx).hp = ...
    impoly(gui_handles.axes_handle, polyPos);

% draw circles over wells
bounds = gui_handles.add_ROI_pushbutton.UserData.grid(1).bounds;
centers = gui_handles.add_ROI_pushbutton.UserData.grid(1).bounds;

% initialize graphics objects for ROIs
hTemplate = rectangle(gui_handles.axes_handle,'Position',bounds(1,:),...
        'EdgeColor',[1 0 0],'Curvature',[1 1],'LineWidth',1.5);
ref_handle = repmat(hTemplate,length(centers),1);
handle_parent = repmat(hTemplate.Parent,length(centers),1);
newCirc = arrayfun(@copyobj,ref_handle,handle_parent,'UniformOutput',false);
newCirc = cat(1,newCirc{:});
delete(hTemplate);
hCirc = newCirc;
clear handle_parent ref_handle newCirc

figure;
patch('Faces',1:size(xData,2),'XData',xData,'YData',yData,...
    'FaceColor','none','EdgeColor','r');
uistack(hCirc,'down');