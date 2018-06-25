function expmt = autoFinish(trackDat, expmt, gui_handles)

            % set time string to zero
            switch expmt.meta.source
                case 'camera'
                    gui_handles.edit_time_remaining.String = '00:00:00';
                case 'video'
                    gui_handles.edit_time_remaining.String = '-';
            end

            % store number of dropped frames for each object in master data struct
            expmt.meta.num_dropped = trackDat.drop_ct;
            expmt.meta.num_frames = trackDat.ct;
            
            % close .avi file if one exists
            if isfield(expmt,'VideoData') && isfield(expmt.VideoData,'obj') 
                close(expmt.VideoData.obj);
            end

            % close fileIDs
            allIDs = fopen('all');
            for i = 1:length(allIDs)                           
                fclose(allIDs(i));
            end
            
            % temporarily remove vid obj/source from struct for saving
            if isfield(expmt.hardware.cam,'vid')
                camcopy = expmt.hardware.cam;
                expmt.hardware.cam = rmfield(expmt.hardware.cam,'src');
                expmt.hardware.cam = rmfield(expmt.hardware.cam,'vid');
            end

            % re-save updated expmt data struct to file
            save([expmt.meta.path.dir expmt.meta.path.name '.mat'],'expmt','-v7.3');
            gui_notify(['experiment complete'],gui_handles.disp_note);
            
            if exist('camcopy','var')
                expmt.hardware.cam = camcopy;
            end
            
            if isfield(expmt,'projector')
                sca;                            % close any open projector windows
            end
            
end