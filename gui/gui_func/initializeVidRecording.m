function expmt = initializeVidRecording(expmt,gui_handles)

% initialize video recording file if record video menu item is checked

expmt.meta.VideoData.path = ...
    [expmt.meta.path.dir expmt.meta.path.name '_VideoData'];

switch gui_handles.vid_compress_menu.Checked
    case 'on'
        expmt.meta.VideoData.obj = VideoWriter(expmt.meta.VideoData.path,'MPEG-4');
    case 'off'
        expmt.meta.VideoData.obj = VideoWriter(expmt.meta.VideoData.path,'Grayscale AVI');
end
expmt.meta.VideoData.FrameRate = expmt.parameters.target_rate;
open(expmt.meta.VideoData.obj);

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

expmt.meta.VideoData.prcn = prcn;
expmt.meta.VideoData.sign = sign;
expmt.meta.VideoData.res = res;



