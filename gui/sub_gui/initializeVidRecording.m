function [trackDat,expmt] = initializeVidRecording(trackDat,expmt,gui_handles)

% initialize video recording file if record video menu item is checked
trackDat.fields = [trackDat.fields;{'VideoData'};{'VideoIndex'}];

expmt.VideoData.path = ...
    [expmt.fdir expmt.fLabel '_VideoData.bin'];

expmt.VideoData.fID = fopen(expmt.VideoData.path,'w');

expmt.VideoIndex.path = ...
    [expmt.fdir expmt.fLabel '_VideoIndex.bin'];
    fopen(expmt.VideoIndex.path,'w');
    
expmt.VideoIndex.fID = fopen(expmt.VideoIndex.path,'w');

% query resolution and precision and save to first four values to video file
im = peekdata(expmt.camInfo.vid,1);
res = [size(im,1);size(im,2)];
c = class(im);

switch c
    case 'uint8'
        prcn = 8;
        sign = 0;
    case 'int8'
        prcn = 8;
        sign = 1;
    case 'uint16'
        prcn = 16;
        sign = 0;
    case 'int16'
        prcn = 16;
        sign = 1;
    otherwise
        prcn = 0;
        sign = 0;
end

fwrite(expmt.VideoData.fID,[res;prcn;sign],'double');



