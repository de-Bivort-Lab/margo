function old = load_settings(old, new, handles)

% update tracking parameters and related gui objects
handles.edit_ref_depth.Value = old.parameters.ref_depth;
handles.edit_ref_depth.String = num2str(old.parameters.ref_depth);
handles.edit_ref_freq.Value = old.parameters.ref_freq;
handles.edit_ref_freq.String = num2str(old.parameters.ref_freq);
handles.edit_exp_duration.Value = old.parameters.duration;
handles.edit_exp_duration.String = num2str(old.parameters.duration);
handles.ROI_thresh_slider.Value = old.parameters.roi_thresh;
handles.disp_ROI_thresh.String = num2str(round(old.parameters.roi_thresh));
handles.track_thresh_slider.Value = old.parameters.track_thresh;
handles.disp_track_thresh.String = num2str(round(old.parameters.track_thresh));
handles.edit_area_minimum.String = num2str(round(old.parameters.area_min));
handles.edit_area_maximum.String = num2str(round(old.parameters.area_max));
handles.edit_target_rate.String = num2str(round(old.parameters.target_rate));

if isfield(old.meta.path,'full')
    handles.save_path.String = old.meta.path.full;
end

% update experiment selection
handles.exp_select_popupmenu.Value = ...
    find(strcmp(handles.exp_select_popupmenu.String,old.meta.name));
old.meta.initialize = true;
old.meta.finish = true;

% update video/camera source
switch old.meta.source
    case 'camera'
        handles.time_remaining_text.String = 'time remaining';
        handles.edit_time_remaining.String = '00:00:00';

        if strcmp(handles.cam_uipanel.Visible,'off')
            handles.cam_uipanel.Visible = 'on';
        end
        if strcmp(handles.vid_uipanel.Visible,'on')
            handles.vid_uipanel.Visible = 'off';
        end
        
    case 'video'
        handles.time_remaining_text.String = 'frames remaining';
        handles.edit_time_remaining.String = '-';
        
        % update video panel UI controls
        if isfield(old.meta,'video') && isfield(old.meta.video,'fdir')
            handles.edit_video_dir.String = old.meta.video.fdir;
        end       
        if isfield(old.meta,'video') && isfield(old.meta.video,'fnames')
            handles.vid_select_popupmenu.String = old.meta.video.fnames;
            handles.vid_select_popupmenu.Value = 1;
            set(handles.vid_uipanel.Children,'Enable','on');
            old.meta.video.vid = ...
                VideoReader([old.meta.video.fdir old.meta.video.fnames{1}]);
            old = guiInitializeVideo(old, handles);
            feval(handles.gui_fig.SizeChangedFcn, handles.gui_fig, []);
        end
        if strcmp(handles.vid_uipanel.Visible,'off')
            handles.vid_uipanel.Visible = 'on';
            handles.vid_uipanel.Position = handles.cam_uipanel.Position;
        end
        if strcmp(handles.cam_uipanel.Visible,'on')
            handles.cam_uipanel.Visible = 'off';
        end
end


% update calibration UI
if isfield(old.hardware.cam,'calibrate') && old.hardware.cam.calibrate
    handles.cam_calibrate_menu.UserData = true;
    handles.cam_calibrate_menu.Checked = 'on';
else
    handles.cam_calibrate_menu.UserData = false;
    handles.cam_calibrate_menu.Checked = 'off';
end


old.hardware = new.hardware;        % assign current values for hardware settings
old = reInitialize(old);                   % remove fields that must be re-defined each expmt

% query camera calibration
cam_dir = [handles.gui_dir '/hardware/camera_calibration/'];
cam_file = [cam_dir 'cam_params.mat'];
if exist(cam_dir,'dir')==7 && exist(cam_file,'file')==2 
    load(cam_file);
    old.hardware.cam.calibration = cameraParams;   
end

% update gui enable states
set(findall(handles.run_uipanel, '-property', 'enable'), 'enable', 'off');

switch old.meta.source
    case 'camera'
        % set all downstream panels to disabled until cam settings are confirmed
        handles.exp_uipanel.ForegroundColor = [.5   .5  .5];
        set(findall(handles.exp_uipanel, '-property', 'enable'), 'enable', 'off');
        handles.tracking_uipanel.ForegroundColor = [.5   .5  .5];
        set(findall(handles.tracking_uipanel, '-property', 'enable'), 'enable', 'off');
        handles.run_uipanel.ForegroundColor = [.5   .5  .5];
        set(findall(handles.run_uipanel, '-property', 'enable'), 'enable', 'off');
        
    case 'video'
        % disable all downstream panels
        handles.exp_uipanel.ForegroundColor = [.5   .5  .5];
        set(findall(handles.exp_uipanel, '-property', 'enable'), 'enable', 'off');
        handles.tracking_uipanel.ForegroundColor = [.5   .5  .5];
        set(findall(handles.tracking_uipanel, '-property', 'enable'), 'enable', 'off');
        handles.run_uipanel.ForegroundColor = [.5   .5  .5];
        set(findall(handles.run_uipanel, '-property', 'enable'), 'enable', 'off');
        
        % enable ROI detection controls if video object exists
        if isfield(old.meta.video,'vid')
            handles.ROI_thresh_slider.Enable = 'on';
            handles.tracking_uipanel.ForegroundColor = [0 0 0];
            handles.accept_ROI_thresh_pushbutton.Enable = 'on';
            handles.disp_ROI_thresh.Enable = 'on';
            handles.ROI_thresh_label.Enable = 'on';
            handles.auto_detect_ROIs_pushbutton.Enable = 'on';
            handles.text45.Enable = 'on';
            handles.text46.Enable = 'on';
            handles.edit_target_rate.Enable = 'on';
            handles.edit_area_minimum.Enable = 'on';
            handles.edit_area_maximum.Enable = 'on';
        end         
        
end


