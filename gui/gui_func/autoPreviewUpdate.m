function autoPreviewUpdate(~,event,hImage)

% query the active display mode
gui_handles = getappdata(hImage,'gui_handles');
expmt = getappdata(hImage,'expmt');

% get the image
im = event.Data;
if size(im,3)>1
    im = im(:,:,2);
end

% adjust image for lens distortion if camera calibration parameters exist
if strcmp(expmt.meta.source,'camera') && ...
        isfield(expmt.hardware.cam,'calibration') && ...
        gui_handles.cam_calibrate_menu.UserData
    [im,~] = undistortImage(im,expmt.hardware.cam.calibration);
end

disp_menu = gui_handles.display_menu;
if ~ischar(disp_menu.UserData) || strcmpi(disp_menu.UserData,'none')
    disp_menu.UserData = 'raw';
end
active_display = disp_menu.UserData;

switch active_display

    % raw image
    case 'raw'         
        hImage.CData = im;
        hImage.Parent.CLim = [0 255];
        if strcmp(hImage.CDataMapping,'direct')
            hImage.CDataMapping = 'scaled';
        end

    % difference image
    case 'difference'
        if isfield(expmt.meta.vignette,'im') && isfield(expmt.meta.ref,'im')
            hImage.CData = (expmt.meta.ref.im-expmt.meta.vignette.im) - ...
                (im-expmt.meta.vignette.im);
            if strcmp(hImage.CDataMapping,'scaled')
                hImage.CDataMapping = 'direct';
                hImage.Parent.CLim = [0 255];
            end
        else
            set_display_mode(disp_menu,'difference','Disable',true);
        end

    % threshold image
    case 'threshold'
        
        if isfield(expmt.meta.vignette,'im') && isfield(expmt.meta.ref,'im')
            hImage.CData = (expmt.meta.ref.im-expmt.meta.vignette.im)-(im-expmt.meta.vignette.im)...
                > gui_handles.track_thresh_slider.Value;
            hImage.Parent.CLim = [0 1];
            if strcmp(hImage.CDataMapping,'direct')
                hImage.CDataMapping = 'scaled';
                hImage.Parent.CLim = [0 1];
            end
        else
            set_display_mode(disp_menu,'threshold','Disable',true);
        end
    % composite threshold image    
    case 'composite'
        if isfield(expmt.meta.vignette,'im') && isfield(expmt.meta.ref,'im')
            hImage.CData = (expmt.meta.ref.im-expmt.meta.vignette.im)-(im-expmt.meta.vignette.im)...
                > gui_handles.track_thresh_slider.Value;
            hImage.Parent.CLim = [0 1];
            if strcmp(hImage.CDataMapping,'direct')
                hImage.CDataMapping = 'scaled';
                hImage.Parent.CLim = [0 1];
            end
        else
            set_display_mode(disp_menu,'composite','Disable',true);
        end
    % reference image
    case 'reference'
        if isfield(expmt.meta.ref,'im')
            hImage.CData = expmt.meta.ref.im;
            hImage.Parent.CLim = [0 max(im(:))];
            if strcmp(hImage.CDataMapping,'direct')
                hImage.CDataMapping = 'scaled';
            end
        else
            set_display_mode(disp_menu,'reference','Disable',true);
        end
end

drawnow limitrate