function roi = addROI(roi, new_corners, expmt)

% append roi and re-sort
corners = [roi.corners; new_corners];
[x,y] = ROIcenters(roi.im,corners);
centers = [x,y];
bounds = [corners(:,1:2) diff(corners(:,[1 3]),1,2) diff(corners(:,[2 4]),1,2)];
tol = expmt.parameters.roi_tol;
[~,~,~,p] = sortROIs(tol, centers, corners, bounds);
corners = corners(p,:);
centers = centers(p,:);
bounds = bounds(p,:);
num_traces = [roi.num_traces; expmt.parameters.traces_per_roi];
num_traces = num_traces(p);


orientation = getMazeOrientation(roi.im, corners);

roi.corners = corners;
roi.centers = centers;
roi.bounds = bounds;
roi.orientation = orientation;
roi.num_traces = num_traces;
roi.n = roi.n + 1;
roi.pixIdx = getBoundsPixels(corners,size(roi.im));


if isfield(expmt.meta.ref,'cen')
    
    % add reference and noise info for roi if set
    expmt.meta.ref.cen = [expmt.meta.ref.cen;{NaN(size(expmt.meta.ref.cen{1}))}];
    expmt.meta.ref.ct = [expmt.meta.ref.ct; 0];
    expmt.meta.ref.last_update = [expmt.meta.ref.last_updated; 0];
    
    % permute values to new order
    expmt.meta.ref.cen = expmt.meta.ref.cen(p);
    expmt.meta.ref.ct = expmt.meta.ref.ct(p);
    expmt.meta.ref.last_update = expmt.meta.ref.last_update(p);
end

if isfield(expmt.meta.noise,'roi_dist')
    % randomly sample observed distribution
    all_vals = expmt.meta.noise.roi_dist(~isnan(expmt.meta.noise.roi_dist));
    rand_idx = randi(numel(all_vals),[size(expmt.meta.noise.roi_dist,1) 1]);
    expmt.meta.noise.roi_dist = cat(2,expmt.meta.noise.roi_dist,all_vals(rand_idx));
    expmt.meta.noise.roi_dist(:,p);
end


function pL = getBoundsPixels(corners,dim)

 corners = [floor(corners(1:2)) ceil(corners(3:4))];
 corners(corners==0) = 1;
 [x,y] = meshgrid(corners(1):corners(3),corners(2):corners(4));
 pL = [x(:) y(:)];
 pL = sub2ind(dim,pL(:,2), pL(:,1));