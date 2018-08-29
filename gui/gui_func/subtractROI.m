function roi = subtractROI(roi, idx)

roi.bounds(idx,:) = [];
roi.centers(idx,:) = [];
roi.orientation(idx,:) = [];
roi.corners(idx,:) = [];
roi.pixIdx(idx) = [];
roi.n = roi.n - numel(idx);
if isfield(roi,'num_traces')
    roi.num_traces(idx) = [];
end

switch roi.mode
    case 'auto'
        tol = expmt.parameters.roi_tol;
        [roi.centers, roi.corners, roi.bounds] = ...
            sortROIs(tol, roi.centers, roi.corners, roi.bounds);
        roi.orientation = getMazeOrientation(roi.im, roi.corners); 
    case 'grid'
        roi.col(idx) = [];
        roi.row(idx) = [];
        roi.shape(idx) = [];
        roi.grid(idx) = [];
        roi.vec(idx,:,:) = [];
        if isfield(roi,'tform')
            roi.tform(idx) = [];
        end
end