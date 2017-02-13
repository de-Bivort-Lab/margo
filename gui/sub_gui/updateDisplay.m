function updateDisplay(trackDat, expmt, im_handle, gui_handles)

% query the active display mode
active_disp = gui_handles.display_menu.UserData;

    switch active_disp

        % raw image
        case 1         
            im_handle.CData = trackDat.im;

        % difference image
        case 2
            if isfield(expmt,'ref') && isfield(expmt,'vignetteMat')
            im_handle.CData = ...
                (expmt.ref-expmt.vignetteMat)-(trackDat.im-expmt.vignetteMat);
            else
                gui_handles.display_menu.UserData = 1;
                gui_handles.display_menu.Children(5).checked = 'on';
                gui_handles.display_menu.Children(4).checked = 'off';
                gui_handles.display_menu.Children(4).enable = 'off';
            end

        % threshold image
        case 3 
            if isfield(expmt,'ref') && isfield(expmt,'vignetteMat')
                thresh = gui_handles.track_thresh_slider.Value;
                diffim = (expmt.ref-expmt.vignetteMat)-(trackDat.im-expmt.vignetteMat);
                im_handle.CData = diffim > thresh;
            else
                gui_handles.display_menu.UserData = 1;
                gui_handles.display_menu.Children(5).checked = 'on';
                gui_handles.display_menu.Children(3).checked = 'off';
                gui_handles.display_menu.Children(3).enable = 'off';
            end

        % reference image
        case 4
            if isfield(expmt,'ref')
                im_handle.CData = expmt.ref;
            else
                gui_handles.display_menu.UserData = 1;
                gui_handles.display_menu.Children(5).checked = 'on';
                gui_handles.display_menu.Children(2).checked = 'off';
                gui_handles.display_menu.Children(2).enable = 'off';
            end
    end