function [trackDat,expmt] = autoFrame(trackDat,expmt,gui_handles)

% query frame from camera/video


% Take single frame
switch expmt.source
    
    case 'camera'

    % grab frame from camera
    trackDat.im = peekdata(expmt.camInfo.vid,1);

    case 'video'
        
        % get next frame from video file
        [trackDat.im, expmt.video] = nextFrame(expmt.video,gui_handles);

        % stop expmt when last frame of last video is reached
        if isfield(expmt.video,'fID')
            trackDat.lastFrame = feof(expmt.video.fID);
        elseif ~hasFrame(expmt.video.vid) && expmt.video.ct == expmt.video.nVids
            trackDat.lastFrame = true;
        end
end

% ensure that image is mono
if size(trackDat.im,3)>1
    trackDat.im=trackDat.im(:,:,2);
end
    


% adjust image for lens distortion if camera calibration parameters exist
if strcmp(expmt.source,'camera') && ...
        isfield(expmt.camInfo,'calibration') && ...
        gui_handles.cam_calibrate_menu.UserData
    [trackDat.im,~] = undistortImage(trackDat.im,expmt.camInfo.calibration);
end