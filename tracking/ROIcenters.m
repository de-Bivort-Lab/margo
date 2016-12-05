function [xCenters,yCenters]=ROIcenters(grayscale_im,binaryimage,ROI_coords)

%% Calculate ROI center coordinates

xCenters=zeros(size(ROI_coords,1),1);
yCenters=zeros(size(ROI_coords,1),1);
masked_im = grayscale_im;
masked_im(~binaryimage)=0;

% For each ROI
    for i=1:size(ROI_coords,1)

        % Extract image subset for the current ROI
        ROI_image=...
            binaryimage(ROI_coords(i,2):ROI_coords(i,4),ROI_coords(i,1):ROI_coords(i,3));

        % Calculate center of mass in x and y
        xCenters(i)=sum((sum(ROI_image,1)./sum(sum(ROI_image))).*(1:size(ROI_image,2)))+ROI_coords(i,1);
        yCenters(i)=sum((sum(ROI_image,2)./sum(sum(ROI_image))).*(1:size(ROI_image,1))')+ROI_coords(i,2);
    end
end