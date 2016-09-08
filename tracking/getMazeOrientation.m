function [mazeOri]=getMazeOrientation(binaryimage,ROI_coords)

%% Horizontally bisect the ROI in top and bottom half and sum across the rows for orienation

% 1=upside down

nROIs=length(ROI_coords);
mazeOri=zeros(nROIs,1);

for i=1:nROIs
    tempImage=binaryimage(ROI_coords(i,2):ROI_coords(i,4),ROI_coords(i,1):ROI_coords(i,3));
    yCenter=round(size(tempImage,2)/2);
    top=sum(sum(tempImage(yCenter-12:yCenter,:)));
    bot=sum(sum(tempImage(yCenter:yCenter+12,:)));
    
    if top>bot
        mazeOri(i)=1;
    elseif bot>top
        mazeOri(i)=0;
    end
end
        

