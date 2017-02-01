function out=initializeCamera(camInfo)

vid = videoinput(camInfo.AdaptorName,camInfo.DeviceIDs{1},camInfo.ActiveMode{:});
src = getselectedsource(vid);

if isfield(src,'Exposure')
    src.Exposure = camInfo.Exposure;
end

if isfield(src,'Gain')
    src.Gain = camInfo.Gain;
end

if isfield(src,'Shutter')
    src.Shutter = camInfo.Shutter;
end

if isfield(src,'WhiteBalanceRBMode')
    src.WhiteBalanceRBMode = 'Off';
end

if isfield(src,'Gamma')
    src.Gamma = 1.4;
end

triggerconfig(vid,'manual');

% Create the image object in which you want to display 
% the video preview data. Make the size of the image
% object match the dimensions of the video frames.

vidRes = vid.VideoResolution;
nBands = vid.NumberOfBands;

out=vid;
