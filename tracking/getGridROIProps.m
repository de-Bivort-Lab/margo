function expmt = getGridROIProps(grid_struct, n, expmt, gui_handles)

% initialize ROI properties
gridVec = [];
centers = [];
ROI_coords = [];
shape = [];
bounds = [];
mazeOri = [];
tform = [];
grid = [];
c = [];
r = [];

% iterate over all grids
for i=1:n
    
    x = grid_struct(i).XData;
    y = grid_struct(i).YData;
    centers = [centers; mean(x(1:4,:))' mean(y(1:4,:))'];

    % save vectors for tracking
    nRow = grid_struct(i).nRows;
    nCol = grid_struct(i).nCols;
    scale = grid_struct(i).scale;
    pos = getPosition(grid_struct(i).hp);
    grid_struct(i).polypos = pos;
    [~,~,gv] = getGridVertices(pos(:,1),pos(:,2),nRow,nCol, scale);
    gridVec = [gridVec;gv];

    % Reset the accept threshold button
    set(gui_handles.accept_ROI_thresh_pushbutton,'value',0);

    ROI_coords = [ROI_coords; x(1,:)' y(1,:)' x(3,:)' y(3,:)'];
    bounds = [bounds; x(1,:)' y(1,:)' x(3,:)'-x(1,:)' y(3,:)'-y(1,:)'];
    mazeOri = logical([mazeOri; false(nRow*nCol,1)]);
    grid = [grid; repmat(i,nRow*nCol,1)];
    colIdx = repmat(1:nCol,nRow,1)';
    c = [c; colIdx(:)];
    rowIdx = repmat(1:nRow,nCol,1);
    r = [r; rowIdx(:)];
    tmp_shape = cell(nRow*nCol,1);
    tmp_shape(:) = {grid_struct(i).shape};
    shape = [shape; tmp_shape];
    
    tmp_tform = cell(nRow*nCol,1);
    if ~isempty(grid_struct(i).tform)
        tmp_tform = grid_struct(i).tform';
    end
    tform = [tform;tmp_tform];
    delete(grid_struct(i).hp);
end


% assign outputs
expmt.meta.roi.shape = shape;
expmt.meta.roi.vec = gridVec;
expmt.meta.roi.row = r;
expmt.meta.roi.col = c;
expmt.meta.roi.grid = grid;
expmt.meta.roi.corners = ROI_coords;
expmt.meta.roi.bounds = bounds;
expmt.meta.roi.centers = centers;
expmt.meta.roi.orientation = mazeOri;
expmt.meta.roi.tform = tform;