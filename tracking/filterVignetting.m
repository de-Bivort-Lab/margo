function vignetteMat=filterVignetting(refImage,dimROI)

% Normalize the intensity of all the mazes to the maximum intensity
% of the dimmest ROI. Using that intensity value, this function generates
% a subtraction matrix that is subtracted off of each image. This
% dramatically improves the ability to apply a single threshold value to
% the image when detecting ROIs or tracking objects


tmpIm=refImage(dimROI(2):dimROI(4),dimROI(1):dimROI(3));    % Reference image for the dimROI
lumOffset=median(median(tmpIm));                            % Find max intensity inside the ROI

% Create subtraction matrix which is everything above the maximum intensity
vignetteMat=refImage-lumOffset;      