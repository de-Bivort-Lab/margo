function [frameRate,camInfo]=estimateFrameRate(camInfo)

% Estimates the current acquisition rate of an active video object when
% "frameRate" is not an accesible field of the device

if ~isfield(camInfo,'vid') || strcmp(camInfo.vid.Running,'off')
    imaqreset;
    camInfo = initializeCamera(camInfo);
    start(camInfo.vid);
    pause(0.1);
end

nFrames = 10;
tStamps = NaN(nFrames,1);
prev_im = peekdata(camInfo.vid,1);
prev_im = prev_im(:,:,1);
fCount=0;


tic
tElapsed = 0;
tPrev = toc;

while tElapsed < 1 && any(isnan(tStamps))
    tCurr = toc;
    tElapsed = tElapsed + tCurr - tPrev;
    tPrev = tCurr;
    im = peekdata(camInfo.vid,1);
    im = im(:,:,1);
    if ~(isempty(im)||isempty(prev_im)) && any(any(im~=prev_im))
        fCount=fCount+1;
        tStamps(fCount)=tCurr;
    end
    prev_im = im;
end

frameRate=1/median(diff(tStamps(~isnan(tStamps))));
if isnan(frameRate)
    frameRate = 30;
end