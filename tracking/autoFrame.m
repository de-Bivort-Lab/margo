function [trackDat,expmt] = autoFrame(trackDat,expmt,gui_handles)

% query frame from camera/video


% Take single frame
switch expmt.meta.source
    
    case 'camera'

    % grab frame from camera
    trackDat.im = peekdata(expmt.hardware.cam.vid,1);

    case 'video'
        
        % get next frame from video file
        [trackDat.im, expmt.meta.video] = nextFrame(expmt.meta.video,gui_handles);

        % stop expmt when last frame of last video is reached
        if isfield(expmt.meta.video,'fID')
            trackDat.lastFrame = feof(expmt.meta.video.fID);
        elseif ~hasFrame(expmt.meta.video.vid) &&...
                expmt.meta.video.ct == expmt.meta.video.nVids
            trackDat.lastFrame = true;
        end
end

% ensure that image is mono
if size(trackDat.im,3)>1
    trackDat.im=trackDat.im(:,:,2);
end
 

% adjust image for lens distortion if camera calibration parameters exist
if strcmp(expmt.meta.source,'camera') && ...
        isfield(expmt.hardware.cam,'calibration') && ...
        gui_handles.cam_calibrate_menu.UserData
    [trackDat.im,~] = undistortImage(trackDat.im,expmt.hardware.cam.calibration);
end
