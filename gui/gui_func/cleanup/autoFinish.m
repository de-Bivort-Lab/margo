function expmt = autoFinish(expmt, handles)

    % close open data files
    fclose('all');
    
    % close .avi file if one exists
    if isfield(expmt.meta,'VideoData') && ...
            isfield(expmt.meta.VideoData,'obj') 
        close(expmt.meta.VideoData.obj);
    end
    
                
    try
        sca;               % close any open psychtoolbox windows
    catch
        % do nothing
    end
    
    if expmt.meta.finish

        [expmt, handles, camCopy] = cleanupCamera(expmt, handles);
        [expmt, handles, vidCopy] = cleanupVideo(expmt, handles);
        [expmt, handles, comCopy] = cleanupComDevices(expmt, handles);

        % re-save updated expmt data struct to file
        save([expmt.meta.path.dir expmt.meta.path.name '.mat'],'expmt','-v7.3');
        gui_notify('experiment complete',handles.disp_note);
        
        % Add device objects back to expmt after saving
        expmt.hardware.cam = camCopy;
        expmt.meta.video.vid = vidCopy;
        expmt.hardware.COM = comCopy;

        try
            attach(expmt);
        catch
        end
                
    else
        % delete master data struct
        delete([expmt.meta.path.dir expmt.meta.path.name '.mat']);
        
        % close fileIDs
        for i = 1:length(expmt.meta.fields) 
            f = expmt.meta.fields{i};
            delete(expmt.data.(f).path);
        end
        
        switch expmt.meta.source
            case 'camera'
                tRemain = expmt.parameters.duration * 3600;
                updateTimeString(tRemain, handles.edit_time_remaining);
            case 'video'
                handles.edit_time_remaining.String = '-';
        end
        
        % delete the experiment directory
        if exist(expmt.meta.path.dir,'dir')==7
            rmdir(expmt.meta.path.dir,'s');
        end
        
        detach(expmt);
        expmt.meta.data = [];
        expmt.meta.path.name = [];
                
    end
end


function [expmt, handles, comCopy] = cleanupComDevices(expmt, handles)
    comCopy = expmt.hardware.COM;
    if isfield(expmt.hardware.COM, "light")
        expmt.hardware.COM.light = [];
    end
    if isfield(expmt.hardware.COM, "aux")
        expmt.hardware.COM.aux = [];
    end
    if isfield(expmt.hardware.COM, "devices")
        expmt.hardware.COM.devices = {};
    end
end


function [expmt, handles, vidCopy] = cleanupVideo(expmt, handles)

    % set time string to zero
    if strcmpi(expmt.meta.source, "video")
        handles.edit_time_remaining.String = '-';
        handles.edit_video_dir.String = '';
        handles.vid_select_popupmenu.Value = 1;
        handles.vid_select_popupmenu.String = 'No video files detected';
        handles.vid_select_popupmenu.Enable = 'off';
        handles.vid_preview_togglebutton.Enable = 'off';
    end

    % temporarily remove vid obj/source from struct for saving
    if isfield(expmt.meta,'video') && isfield(expmt.meta.video,'vid')
        vidCopy = expmt.meta.video.vid;
        expmt.meta.video = rmfield(expmt.meta.video,'vid');
    end

end


function [expmt, handles, camCopy] = cleanupCamera(expmt, handles)

    % set time string to zero
    if strcmpi(expmt.meta.source, "camera")
        handles.edit_time_remaining.String = '00:00:00';
    end

    camCopy = expmt.hardware.cam;
    % temporarily remove vid obj/source from struct for saving
    if isfield(expmt.hardware.cam, 'vid')
        expmt.hardware.cam = rmfield(expmt.hardware.cam, 'vid');
    end

    if isfield(expmt.hardware.cam, 'src')
        expmt.hardware.cam = rmfield(expmt.hardware.cam, 'src');
    end

end

