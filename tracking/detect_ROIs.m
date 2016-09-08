function [ROI_bounds,ROI_coords,ROI_widths,ROI_heights,binaryimage] = detect_ROIs(ROI_image,ROI_thresh)

warning('off');
        
        %imagedata = imread('ROI test image.jpg');
        
        binaryimage = im2bw(ROI_image, ROI_thresh);        % Show only the red channel
        
        
        improps = regionprops(binaryimage,'Area','BoundingBox'); % Extract the Area and Bounding Box for binary image
        improps=improps([improps.Area]>100);                     % Establish lower bound on the area of blobs

        blob_count = length(improps);                            % Count blobs in image
        BoundingBoxes = [improps.BoundingBox];
        BoundingBoxes = reshape(BoundingBoxes,[4 blob_count])';   % Reshape bounding boxes to 4 x blob_count array
        ROI_bounds=BoundingBoxes;
       
       % Find ROIs that are too large or too small
       ROI_widths = ROI_bounds(:,3);
       ROI_heights = ROI_bounds(:,4);
       median_W=median(ROI_widths);
       median_H=median(ROI_heights);
       exclude_W=abs(ROI_widths-median_W)>0.3*median_W;
       exclude_H=abs(ROI_heights-median_H)>0.3*median_H;
       excludedROIs=exclude_W|exclude_H;
       
       % Remove ROIs above or below size threshold;
       ROI_heights=ROI_heights(~excludedROIs,:);
       ROI_widths=ROI_widths(~excludedROIs,:);
       ROI_bounds=ROI_bounds(~excludedROIs,:);
       
       % Assign ROI coords and increase ROI size by 10 on each side
       ROI_coords=zeros(size(ROI_bounds));
       ROI_coords(:,1) = ROI_bounds(:,1);                                   % ROI x-coordinate 1
       ROI_coords(:,2) = ROI_bounds(:,2);                                   % ROI y-coordinate 1
       ROI_coords(:,3) = ROI_bounds(:,1) + ROI_bounds(:,3);                 % ROI x-coordinate 2
       ROI_coords(:,4) = ROI_bounds(:,2) + ROI_bounds(:,4);                 % ROI y-coordinate 2
       
       % Limit coordinates to size of the screen
       ROI_coords(ROI_coords<0)=0.5;
       ROI_coords(ROI_coords(:,4)>size(binaryimage,1),4)=size(binaryimage,1);
       ROI_coords(ROI_coords(:,3)>size(binaryimage,2),3)=size(binaryimage,2);

        %% Exclude ROIs that are too far to the left or right edge of the image
        width=size(binaryimage,2);
        minEdge=ROI_coords(:,1)<0.1*width;
        maxEdge=ROI_coords(:,3)>0.93*width;
        exclude=minEdge|maxEdge;
        ROI_coords(exclude,:)=[];
        ROI_bounds(exclude,:)=[];
       
end
