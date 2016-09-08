function vignetteMat=filterVignetting(refImage,binaryimage,ROI_coords)

% Normalize the intensity of all the mazes to a periphal maze

dimROI=ROI_coords(end,:);       % Coordinates of the last ROI after sorting
tmpIm=refImage(dimROI(2):dimROI(4),dimROI(1):dimROI(3));    % Reference image for the dimROI
tmpBw=binaryimage(dimROI(2):dimROI(4),dimROI(1):dimROI(3)); % Binary ROI image

% Multiply reference by binary image to keep only pixels inside the maze
dimROI=tmpIm.*uint8(tmpBw);                                 
dimROI=double(dimROI);
dimROI(dimROI==0)=NaN;              % Set pixels outside of the maze arms to NaN
lumOffset=max(max(dimROI));         % Find max intensity inside the ROI

% Create subtraction matrix which is everything above the maximum intensity
vignetteMat=refImage-lumOffset;      