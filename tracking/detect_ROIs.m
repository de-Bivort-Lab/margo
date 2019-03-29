function [ROI_bounds,ROI_coords,ROI_widths,ROI_heights,binaryimage] = detect_ROIs(ROI_image,ROI_thresh)
        
        binaryimage = ROI_image > ROI_thresh;                       % Show only the red channel
        % get region properties
        cc = bwconncomp(binaryimage, 8);
        area = cellfun(@numel,cc.PixelIdxList);
        
        oob = area < 100;
        if any(oob)
            cc.PixelIdxList(oob) = [];
            cc.NumObjects = cc.NumObjects - sum(oob);
        end
        improps=regionprops(cc, 'BoundingBox');
        ROI_bounds = cat(1,improps.BoundingBox);

        if isempty(ROI_bounds)
            ROI_coords = [];
            ROI_widths = [];
            ROI_heights = [];
            return;
        end
        % Find ROIs that are too large or too small
        ROI_widths = ROI_bounds(:,3);
        ROI_heights = ROI_bounds(:,4);
        median_W=median(ROI_widths);
        median_H=median(ROI_heights);
        exclude_W=abs(ROI_widths-median_W)>0.5*median_W;
        exclude_H=abs(ROI_heights-median_H)>0.5*median_H;
        excludedROIs=exclude_W|exclude_H;

        % Remove ROIs above or below size threshold;
        ROI_heights=ROI_heights(~excludedROIs,:);
        ROI_widths=ROI_widths(~excludedROIs,:);
        ROI_bounds=ROI_bounds(~excludedROIs,:);

        % Assign ROI coords and increase ROI size by 10 on each side
        ROI_coords=zeros(size(ROI_bounds));
        ROI_coords(:,1) = ROI_bounds(:,1);                          % ROI x-coordinate 1
        ROI_coords(:,2) = ROI_bounds(:,2);                          % ROI y-coordinate 1
        ROI_coords(:,3) = ROI_bounds(:,1) + ROI_bounds(:,3);        % ROI x-coordinate 2
        ROI_coords(:,4) = ROI_bounds(:,2) + ROI_bounds(:,4);        % ROI y-coordinate 2

        % Limit coordinates to size of the screen
        ROI_coords(ROI_coords<0)=0.5;
        ROI_coords(ROI_coords(:,4)>size(binaryimage,1),4)=size(binaryimage,1);
        ROI_coords(ROI_coords(:,3)>size(binaryimage,2),3)=size(binaryimage,2);
       
end
