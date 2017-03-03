function [mazeOri]=getMazeOrientation(binaryimage,ROI_coords)

%% Horizontally bisect the ROI in top and bottom half and sum across the rows for orienation

%(upside down Y = 0, right-side up = 1)

nROIs=size(ROI_coords,1);
mazeOri=zeros(nROIs,1);
roi = round(ROI_coords);

% For each ROI
for i=1:nROIs
    
    % Extract image subset for the current ROI
    tempImage=binaryimage(roi(i,2):roi(i,4),roi(i,1):roi(i,3));
    
    % Calculate vertical midpoint
    yCenter=round(size(tempImage,1)/2);
    x = size(tempImage,1);
    
    % Sum the number of pixels in top and bottom halfs
    top=sum(sum(tempImage(1:yCenter,:)));
    bot=sum(sum(tempImage(yCenter:x,:)));
    
    if top>bot
        mazeOri(i) = true; % More pixels in top-half = rightside-up Y
    elseif bot>top
        mazeOri(i) = false; % More pixels in bottom-half = upside-down Y
    end
end

mazeOri = boolean(mazeOri);
        




        

