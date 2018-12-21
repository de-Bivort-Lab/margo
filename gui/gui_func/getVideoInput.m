function expmt = getVideoInput(expmt,gui_handles)

warning off MATLAB:subscripting:noSubscriptsSpecified
if strcmp(expmt.meta.source,'camera') && isfield(expmt.hardware.cam,'vid')
    
    if ~isvalid(expmt.hardware.cam.vid) || strcmp(expmt.hardware.cam.vid.Running,'off')
    
        % Clear old video objects
        imaqreset
        pause(0.2);

        % Create camera object with input parameters
        expmt.hardware.cam = initializeCamera(expmt.hardware.cam);
        start(expmt.hardware.cam.vid);
        pause(0.1);
    
    elseif strcmp(expmt.hardware.cam.vid.Previewing,'on')
        
        if ~isfield(gui_handles,'hImage') && ~ishghandle(gui_handles.hImage)
            gui_handles.hImage = findobj(gui_handles.axes_handle,'-depth',1,'Type','Image');
        end
        im = gui_handles.hImage.CData;    
        prev_btn = gui_handles.Cam_preview_togglebutton;
        prev_btn.Value = false;
        feval(prev_btn.Callback,prev_btn,[]);
        drawnow
        pause(0.05);
        
    end
        
        
elseif strcmp(expmt.meta.source,'video') 
    
    % set current file to first file in list
    gui_handles.vid_select_popupmenu.Value = 1;
    
    if isfield(expmt.meta,'video')
        
        % open video object from file
        expmt.meta.video.vid = ...
            VideoReader([expmt.meta.video.fdir ...
            expmt.meta.video.fnames{gui_handles.vid_select_popupmenu.Value}]);

        % get file number in list
        expmt.meta.video.ct = gui_handles.vid_select_popupmenu.Value;

        % estimate duration based on video duration
        gui_handles.edit_exp_duration.Value = ...
            expmt.meta.video.total_duration * 1.15 / 3600;
        
    end
    
end