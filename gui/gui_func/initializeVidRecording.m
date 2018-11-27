function expmt = initializeVidRecording(expmt,gui_handles)
% initialize video output file

% set output path
expmt.meta.VideoData.path = ...
    [expmt.meta.path.dir expmt.meta.path.name '_VideoData'];

% initialize video write object
if expmt.meta.video_out.compress
    expmt.meta.VideoData.obj = VideoWriter(expmt.meta.VideoData.path,'Motion JPEG AVI');
    expmt.meta.VideoData.obj.Quality = 75;
else
    expmt.meta.VideoData.obj = VideoWriter(expmt.meta.VideoData.path,'Grayscale AVI');
end
expmt.meta.VideoData.FrameRate = expmt.parameters.target_rate;
open(expmt.meta.VideoData.obj);

% query resolution and precision
im = expmt.meta.ref.im;
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



