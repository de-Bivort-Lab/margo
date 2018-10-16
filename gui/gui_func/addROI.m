function roi = addROI(roi, new_corners)

% append roi and re-sort
corners = [roi.corners; new_corners];
[x,y] = ROIcenters(roi.im,corners);
centers = [x,y];
tol = expmt.parameters.roi_tol;
[~,~,~,p] = sortROIs(tol, centers, corners, corners);
corners = corners(p,:);
centers = centers(p,:);
num_traces = [roi.num_traces; expmt.parameters.traces_per_roi];
num_traces = num_traces(p);

bounds = [corners(:,1:2) diff(corners(1:3)) diff(corners(2:4))];
orientation = getMazeOrientation(roi.im, corners);

roi.corners = corners;
roi.centers = centers;
roi.bounds = bounds;
roi.orientation = orientation;
roi.num_traces = num_traces;
roi.n = roi.n + 1;