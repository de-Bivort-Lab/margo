
function [ROI_cen, blob_num] = assignROI(raw_cen, expmt)


ROI_num = cellfun(@(x) subAssignROI(x,expmt.meta.roi.corners),...
     num2cell(raw_cen,2),'UniformOutput',false);
ROI_num = cat(1,ROI_num{:});
blob_num = 1:size(raw_cen,1);
 
ROI_cen = arrayfun(@(x) raw_cen(ROI_num==x,:), 1:expmt.meta.roi.n,...
            'UniformOutput',false)';
blob_num = arrayfun(@(x) blob_num(ROI_num==x), 1:expmt.meta.roi.n,...
            'UniformOutput',false)';

% assign ROIs to centroids
function ROI_num = subAssignROI(cen,b)

    % get the bounds for each ROI at
    % current x and y position
    xL = cen(1) > b(:,1);
    xR = cen(1) < b(:,3);
    yT = cen(2) > b(:,2);
    yB = cen(2) < b(:,4);
    % identify matching ROI, if any    

    in_bounds = xL & xR & yT & yB;
    ROI_num = find(in_bounds);   
    
