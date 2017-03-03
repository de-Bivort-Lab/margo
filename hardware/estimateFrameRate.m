function [frameRate,camInfo]=estimateFrameRate(camInfo)

% Estimates the current acquisition rate of an active video object when
% "frameRate" is not an accesible field of the device

if ~isfield(camInfo,'vid') || strcmp(camInfo.vid.Running,'off')
    imaqreset;
    camInfo = initializeCamera(camInfo);
    start(camInfo.vid);
    pause(0.1);
end

nFrames = 20;
tStamps = NaN(nFrames,1);
prev_im = peekdata(camInfo.vid,1);
prev_im = prev_im(:,:,1);
fCount=0;

tic
while any(isnan(tStamps))
    tmp_tStamp = toc;
    im = peekdata(camInfo.vid,1);
    im = im(:,:,1);
    if ~(isempty(im)||isempty(prev_im)) && any(any(im~=prev_im))
        fCount=fCount+1;
        tStamps(fCount)=tmp_tStamp;
    end
    prev_im = im;
    clearvars im
end

frameRate=1/mean(diff(tStamps));