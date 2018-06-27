function [trackDat,expmt] = initializeVidRecording(trackDat,expmt,gui_handles)

% initialize video recording file if record video menu item is checked
trackDat.fields = [trackDat.fields;{'VideoIndex'}];

expmt.VideoData.path = ...
    [expmt.meta.path.dir expmt.meta.path.name '_VideoData.avi'];

switch gui_handles.vid_compress_menu.Checked
    case 'on'
        expmt.VideoData.obj = VideoWriter(expmt.VideoData.path,'MPEG-4');
    case 'off'
        expmt.VideoData.obj = VideoWriter(expmt.VideoData.path,'Grayscale AVI');
end
expmt.VideoData.FrameRate = expmt.parameters.target_rate;
open(expmt.VideoData.obj);


expmt.VideoIndex.path = ...
    [expmt.meta.path.dir expmt.meta.path.name '_VideoIndex.bin'];
    fopen(expmt.VideoIndex.path,'w');
    
expmt.VideoIndex.fID = fopen(expmt.VideoIndex.path,'w');

% query resolution and precision and save to first four values to video file
im = peekdata(expmt.hardware.cam.vid,1);
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

%fwrite(expmt.VideoData.fID,[res;prcn;sign],'double');
expmt.VideoData.prcn = prcn;
expmt.VideoData.sign = sign;
expmt.VideoData.res = res;



