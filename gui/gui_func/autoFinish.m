function expmt = autoFinish(expmt, gui_handles)

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

            % set time string to zero
            switch expmt.meta.source
                case 'camera'
                    gui_handles.edit_time_remaining.String = '00:00:00';
                case 'video'
                    gui_handles.edit_time_remaining.String = '-';
                    gui_handles.edit_video_dir.String = '';
                    gui_handles.vid_select_popupmenu.Value = 1;
                    gui_handles.vid_select_popupmenu.String =...
                        'No video files detected';
                    gui_handles.vid_select_popupmenu.Enable = 'off';
                    gui_handles.vid_preview_togglebutton.Enable = 'off';
            end
   
            % temporarily remove vid obj/source from struct for saving
            if isfield(expmt.hardware.cam,'vid')
                camcopy = expmt.hardware.cam;
                expmt.hardware.cam = rmfield(expmt.hardware.cam,'src');
                expmt.hardware.cam = rmfield(expmt.hardware.cam,'vid');
            end

            % re-save updated expmt data struct to file
            save([expmt.meta.path.dir expmt.meta.path.name '.mat'],'expmt','-v7.3');
            gui_notify('experiment complete',gui_handles.disp_note);
            
            if exist('camcopy','var')
                expmt.hardware.cam = camcopy;
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
                    updateTimeString(tRemain, gui_handles.edit_time_remaining);
                case 'video'
                    gui_handles.edit_time_remaining.String = '-';
            end
            
            % delete the experiment directory
            if exist(expmt.meta.path.dir,'dir')==7
                rmdir(expmt.meta.path.dir,'s');
            end
            
            detach(expmt);
            expmt.meta.data = [];
            expmt.meta.path.name = [];
            
end