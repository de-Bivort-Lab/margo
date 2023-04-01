function [expmt, handles] = setupCameras(expmt, handles)
%UNTITLED Summary of this function goes here

% query available cameras and camera info
expmt.meta.source = 'camera';
[expmt.hardware.cam,handles.cam_list] = refresh_cam_list(handles);  
cam_dir = [handles.gui_dir '/hardware/camera_calibration/'];
handles.cam_calibrate_menu.UserData = false;
expmt.hardware.cam.calibrate = false;

if exist(cam_dir,'dir')==7
    
    cam_files = recursiveSearch(cam_dir);
    var_names = cell(length(cam_files),1);
    for i=1:length(cam_files)
        vn = {who('-file', cam_files{i})};
        var_names(i) = vn;
        load(cam_files{i});
    end
    allvars = whos;
    
    if any(strcmp('cameraParameters',{allvars.class}))
        target_name = allvars(find(strcmp('cameraParameters', {allvars.class}), 1, 'first')).name;
        target_file = cellfun(@(x) strcmp(target_name, x), var_names, 'UniformOutput', false);
        target_file = target_file{find(~cellfun(@isempty, target_file), 1, 'first')};
        param_obj = load(cam_files{target_file}, target_name);
        expmt.hardware.cam.calibration = param_obj.(target_name);
    end
    
end

end

