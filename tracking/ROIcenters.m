function [xCenters,yCenters]=ROIcenters(binaryimage,ROI_coords)

%% Calculate ROI center coordinates

xCenters=zeros(size(ROI_coords,1),1);
yCenters=zeros(size(ROI_coords,1),1);
roi = round(ROI_coords);
%{
% For each ROI
    for i=1:size(ROI_coords,1)

        % Extract image subset for the current ROI
        ROI_image=...
            binaryimage(ROI_coords(i,2):ROI_coords(i,4),ROI_coords(i,1):ROI_coords(i,3));

        % Calculate center of mass in x and y
        xCenters(i)=sum((sum(ROI_image,1)./sum(sum(ROI_image))).*(1:size(ROI_image,2)))+ROI_coords(i,1);
        yCenters(i)=sum((sum(ROI_image,2)./sum(sum(ROI_image))).*(1:size(ROI_image,1))')+ROI_coords(i,2);
    end
%}

cROI = num2cell(roi,2);
[xCenters,yCenters] = cellfun(@(k) roi_cen(k,binaryimage), cROI);


function [x,y] = roi_cen(c,bim)

        % Extract image subset for the current ROI
        rim = bim(c(2):c(4),c(1):c(3));

        % Calculate center of mass in x and y
        t = sum(rim(:));
        x=sum(sum(rim,1)./t.*(1:size(rim,2)))+c(1);
        y=sum(sum(rim,2)./t.*(1:size(rim,1))')+c(2);

