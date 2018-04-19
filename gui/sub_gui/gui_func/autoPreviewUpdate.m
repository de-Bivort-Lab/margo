function autoPreviewUpdate(obj,event,hImage)

% query the active display mode
gui_handles = getappdata(hImage,'gui_handles');
expmt = getappdata(hImage,'expmt');

% adjust image for lens distortion if camera calibration parameters exist
if strcmp(expmt.source,'camera') && ...
        isfield(expmt.camInfo,'calibration') && ...
        gui_handles.cam_calibrate_menu.UserData
    [event.Data,~] = undistortImage(event.Data,expmt.camInfo.calibration);
end

switch gui_handles.display_menu.UserData

    % raw image
    case 1         
        hImage.CData = event.Data;
        hImage.Parent.CLim = [0 max(event.Data(:))];
        if strcmp(hImage.CDataMapping,'direct')
            hImage.CDataMapping = 'scaled';
        end

    % difference image
    case 2
        if isfield(expmt,'ref') && isfield(expmt.vignette,'im')
        hImage.CData = ...
            (expmt.ref.im-expmt.vignette.im)-(event.Data-expmt.vignette.im);
            if strcmp(hImage.CDataMapping,'scaled')
                hImage.CDataMapping = 'direct';
                hImage.Parent.CLim = [0 255];
            end
        else
            gui_handles.display_menu.UserData = 1;
            gui_handles.display_menu.Children(5).Checked= 'on';
            gui_handles.display_menu.Children(4).Checked= 'off';
            gui_handles.display_menu.Children(4).Enable = 'off';
        end

    % threshold image
    case 3 
        
        if isfield(expmt,'ref') && isfield(expmt.vignette,'im')
            hImage.CData = (expmt.ref.im-expmt.vignette.im)-(event.Data-expmt.vignette.im)...
                > gui_handles.track_thresh_slider.Value;
            hImage.Parent.CLim = [0 1];
            if strcmp(hImage.CDataMapping,'direct')
                hImage.CDataMapping = 'scaled';
                hImage.Parent.CLim = [0 1];
            end
        else
            gui_handles.display_menu.UserData = 1;
            gui_handles.display_menu.Children(5).Checked= 'on';
            gui_handles.display_menu.Children(3).Checked= 'off';
            gui_handles.display_menu.Children(3).Enable = 'off';
        end

    % reference image
    case 4
        if isfield(expmt,'ref')
            hImage.CData = expmt.ref.im;
            hImage.Parent.CLim = [0 max(event.Data(:))];
            if strcmp(hImage.CDataMapping,'direct')
                hImage.CDataMapping = 'scaled';
            end
        else
            gui_handles.display_menu.UserData = 1;
            gui_handles.display_menu.Children(5).Checked= 'on';
            gui_handles.display_menu.Children(2).Checked= 'off';
            gui_handles.display_menu.Children(2).Enable = 'off';
        end
end

drawnow limitrate