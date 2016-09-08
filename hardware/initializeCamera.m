function out=initializeCamera(camInfo)

vid = videoinput(camInfo.AdaptorName,camInfo.DeviceIDs{1},camInfo.ActiveMode{:});
src = getselectedsource(vid);
src.Exposure = camInfo.Exposure;
src.Gain = camInfo.Gain;
src.Shutter = camInfo.Shutter;
src.WhiteBalanceRBMode = 'Off';
src.Gamma = 1.4;

triggerconfig(vid,'manual');

% Create the image object in which you want to display 
% the video preview data. Make the size of the image
% object match the dimensions of the video frames.

vidRes = vid.VideoResolution;
nBands = vid.NumberOfBands;

out=vid;
