function [mazeOri]=getMazeOrientation(binaryimage,ROI_coords)

%% Horizontally bisect the ROI in top and bottom half and sum across the rows for orienation

%(upside down Y = 0, right-side up = 1)

nROIs=size(ROI_coords,1);
mazeOri=zeros(nROIs,1);
roi = round(ROI_coords);
cROI = num2cell(roi,2);
mazeOri = cellfun(@(k) sum_halves(k,binaryimage), cROI);



function ori = sum_halves(roi_coords,bim)

    % Extract image subset for the current ROI
    tempImage=bim(roi_coords(2):roi_coords(4),roi_coords(1):roi_coords(3));
    
    % Calculate vertical midpoint
    yCenter=round(size(tempImage,1)/2);
    x = size(tempImage,1);
    
    % Sum the number of pixels in top and bottom halfs
    top=sum(sum(tempImage(1:yCenter,:)));
    bot=sum(sum(tempImage(yCenter:x,:)));
    
    if top>=bot
        ori = true; % More pixels in top-half = rightside-up Y
    elseif bot>top
        ori = false; % More pixels in bottom-half = upside-down Y
    end
    ori = logical(ori);
    

        




        

