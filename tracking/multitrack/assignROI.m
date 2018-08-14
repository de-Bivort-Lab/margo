
function ROI_num = assignROI(raw_cen, expmt)

if strcmp(expmt.parameters.roi_mode,'grid')
    % find candidate ROIs for each centroid
    ROI_num = arrayfun(@(x) grid_AssignROI(...
        x,expmt.meta.roi.vec,expmt.meta.roi.shape,expmt.meta.roi.tform),...
        num2cell(raw_cen,2),'UniformOutput',false);
else
    switch expmt.parameters.sort_mode  
        case 'bounds'
            ROI_num = cellfun(@(x) ...
                bounds_AssignROI(x,expmt.meta.roi.corners),...
                num2cell(raw_cen,2),'UniformOutput',false);
        case 'distance'
            ROI_num = distance_assignROI(raw_cen, expmt.meta.roi.centers);   
    end
end
            



% assign ROIs to centroids
function ROI_num = bounds_AssignROI(cen,b)

% get the bounds for each ROI at
% current x and y position
xL = cen(1) > b(:,1);
xR = cen(1) < b(:,3);
yT = cen(2) > b(:,2);
yB = cen(2) < b(:,4);
% identify matching ROI, if any    

in_bounds = xL & xR & yT & yB;
ROI_num = find(in_bounds);  
    
    
function ROI_num = grid_AssignROI(cen,gv,shape,tf)

% get the bounds for each ROI at
% current x and y position
cen=cen{1};
xL = cen(1) > gv(:,2,1).*cen(2) + gv(:,2,2);
xR = cen(1) < gv(:,4,1).*cen(2) + gv(:,4,2);
yT = cen(2) > gv(:,1,1).*cen(1) + gv(:,1,2);
yB = cen(2) < gv(:,3,1).*cen(1) + gv(:,3,2);

% identify matching ROI, if any
in_bounds = xL & xR & yT & yB;
ROI_num = find(in_bounds);

% use projective transform if roi shape is circular
iscirc = strcmp(shape(ROI_num),'Circular');
if any(iscirc)
    uc = cellfun(@(x) ...
        transformPointsForward(x,cen),...
        tf(ROI_num(iscirc)),'UniformOutput',false);
    uc = cat(1,uc{1});
    if sqrt((uc(1)-0.5).^2 + (uc(2)-0.5).^2) > 0.5
        ROI_num = [];
    end
end

if numel(ROI_num) > 1
    ROI_num = ROI_num(1);
end


function ROI_num = distance_assignROI(raw_cen, roi_centers)

tmp_raw = permute(repmat(raw_cen,1,1,size(roi_centers,1)),[3 2 1]);
tmp_roi = repmat(roi_centers,1,1,size(raw_cen,1));
dist = abs(sqrt(dot(tmp_raw - tmp_roi, tmp_roi - tmp_raw,2)));
[~,ROI_num] = min(dist);
ROI_num = num2cell(ROI_num);
    
