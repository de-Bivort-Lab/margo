function expmt = guiInitializeVideo(expmt, gui_handles)

    expmt.meta.video.nFrames = floor(expmt.meta.video.nFrames);
    gui_handles.edit_video_dir.String = expmt.meta.video.fdir;
    gui_handles.vid_select_popupmenu.String = expmt.meta.video.fnames;
    gui_handles.edit_time_remaining.String = num2str(expmt.meta.video.nFrames);
    expmt.parameters.target_rate = expmt.meta.video.vid.FrameRate;
    
    % set downstream UI panel Enable status
    gui_handles.tracking_uipanel.ForegroundColor = [0 0 0];
    set(findall(gui_handles.tracking_uipanel, ...
        '-property', 'Enable'), 'Enable', 'on');
    gui_handles.distance_scale_menu.Enable = 'on';
    gui_handles.vignette_correction_menu.Enable = 'on';
    gui_handles.vid_select_popupmenu.Enable = 'on';
    gui_handles.vid_preview_togglebutton.Enable = 'on';
    gui_handles.select_video_label.Enable = 'on';
    
    reInitialize(expmt);

    gui_notify('cam settings confirmed',gui_handles.disp_note);

    if ~isfield(expmt.meta.roi,'n')
        gui_handles.track_thresh_slider.Enable = 'off';
        gui_handles.accept_track_thresh_pushbutton.Enable = 'off';
        gui_handles.reference_pushbutton.Enable = 'off';
        gui_handles.track_thresh_label.Enable = 'off';
        gui_handles.disp_track_thresh.Enable = 'off';
    end

    if ~isfield(expmt.meta.ref,'im')
        gui_handles.sample_noise_pushbutton.Enable = 'off';
    end
    
    im = nextFrame(expmt.meta.video, gui_handles);
    if size(im,3) > 1
        im = im(:,:,1);
    end   
    if ~isfield(gui_handles,'hImage') || ~isfield(gui_handles.hImage,'CData')
        gui_handles.hImage = imagesc(im,'Parent',gui_handles.axes_handle);
        set(gui_handles.axes_handle,'XTick',[],'YTick',[]);
        colormap(gui_handles.axes_handle,'gray');
        drawnow
    else
        gui_handles.hImage.CData = im;
        colormap(gui_handles.axes_handle,'gray');
        drawnow
    end
    
    vid_scrub = gui_handles.vid_scrubber_slider;
    vid_scrub.Value = 1;
    vid_scrub.Min = 1;
    vid_scrub.Max = expmt.meta.video.nFrames;
    stp = [1 50]./expmt.meta.video.nFrames;
    stp(stp>0.5) = 0.5;
    vid_scrub.SliderStep = stp;
    vid_scrub.Visible = 'on';
    ax_pos = gui_handles.axes_handle.Position([1 3]);
    vid_scrub.Position(1:3) = [ax_pos(1) gui_handles.bottom_uipanel.Position(2) ax_pos(2)];
    
