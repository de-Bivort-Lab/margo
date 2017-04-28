function expmt = getVideoInput(expmt,gui_handles)

if strcmp(expmt.source,'camera') && isfield(expmt.camInfo,'vid')
    
    if ~isvalid(expmt.camInfo.vid) || strcmp(expmt.camInfo.vid.Running,'off')
    
        % Clear old video objects
        imaqreset
        pause(0.2);

        % Create camera object with input parameters
        expmt.camInfo = initializeCamera(expmt.camInfo);
        start(expmt.camInfo.vid);
        pause(0.1);
    
    elseif strcmp(expmt.camInfo.vid.Previewing,'on')
        
        stoppreview(expmt.camInfo.vid);
        pause(0.001);
        
        if size(gui_handles.hImage.CData,3) > 1
            gui_handles.hImage = imagesc(gui_handles.axes_handle,gui_handles.hImage.CData(:,:,2));
        else
            gui_handles.hImage = imagesc(gui_handles.axes_handle,gui_handles.hImage.CData);
        end
        gui_handles.Cam_preview_togglebutton.String='Start preview';
        gui_handles.Cam_preview_togglebutton.BackgroundColor = [1 1 1];
        gui_handles.Cam_preview_togglebutton.Value = 0;
        
    end
        
        
elseif strcmp(expmt.source,'video') 
    
    % set current file to first file in list
    gui_handles.vid_select_popupmenu.Value = 1;
    
    if isfield(expmt.video,'fID')
        
        % ensure that the current position of the file is set to 
        % the beginning of the file (bof) + an offset of 32 bytes
        % (the first 32 bytes store info on resolution and precision)
        fseek(expmt.video.fID, 32, 'bof');
        
    else
        
        % open video object from file
        expmt.video.vid = ...
            VideoReader([expmt.video.fdir ...
            expmt.video.fnames{gui_handles.vid_select_popupmenu.Value}]);

        % get file number in list
        expmt.video.ct = gui_handles.vid_select_popupmenu.Value;

        % estimate duration based on video duration
        gui_handles.edit_exp_duration.Value = expmt.video.total_duration * 1.15 / 3600;
        
    end
    
end