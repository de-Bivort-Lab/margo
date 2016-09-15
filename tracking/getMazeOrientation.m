function [mazeOri]=getMazeOrientation(binaryimage,ROI_coords)

%% Horizontally bisect the ROI in top and bottom half and sum across the rows for orienation

%(upside down Y = 0, right-side up = 1)

nROIs=size(ROI_coords,1);
mazeOri=zeros(nROIs,1);

% For each ROI
for i=1:nROIs
    
    % Extract image subset for the current ROI
    tempImage=binaryimage(ROI_coords(i,2):ROI_coords(i,4),ROI_coords(i,1):ROI_coords(i,3));
    
    % Calculate vertical midpoint
    yCenter=round(size(tempImage,1)/2);
    x = size(tempImage,1);
    
    % Sum the number of pixels in top and bottom halfs
    top=sum(sum(tempImage(1:yCenter,:)));
    bot=sum(sum(tempImage(yCenter:x,:)));
    
    if top>bot
        mazeOri(i)=1; % More pixels in top-half = rightside-up Y
    elseif bot>top
        mazeOri(i)=0; % More pixels in bottom-half = upside-down Y
    end
end
        




        

