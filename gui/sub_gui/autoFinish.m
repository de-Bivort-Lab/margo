function expmt = autoFinish(trackDat, expmt, gui_handles)

            % set time string to zero
            switch expmt.source
                case 'camera'
                    gui_handles.edit_time_remaining.String = '00:00:00';
                case 'video'
                    gui_handles.edit_time_remaining.String = '-';
            end

            % record the dimensions of data in each recorded field
            for i = 1:length(trackDat.fields)
                expmt.(trackDat.fields{i}).dim = size(trackDat.(trackDat.fields{i}));
                expmt.(trackDat.fields{i}).precision = class(trackDat.(trackDat.fields{i}));
            end

            % store number of dropped frames for each object in master data struct
            expmt.drop_ct = trackDat.drop_ct;
            expmt.fields = trackDat.fields;
            expmt.nFrames = trackDat.ct;

            % close fileIDs
            allIDs = fopen('all');
            for i = 1:length(allIDs)                           
                fclose(allIDs(i));
            end
            
            % temporarily remove vid obj/source from struct for saving
            if isfield(expmt.camInfo,'vid')
                camcopy = expmt.camInfo;
                expmt.camInfo = rmfield(expmt.camInfo,'src');
                expmt.camInfo = rmfield(expmt.camInfo,'vid');
            end

            % re-save updated expmt data struct to file
            save([expmt.fdir expmt.fLabel '.mat'],'expmt');
            gui_notify(['experiment complete'],gui_handles.disp_note);
            
            if exist('camcopy','var')
                expmt.camInfo = camcopy;
            end
            
            if isfield(expmt,'projector')
                sca;                            % close any open projector windows
            end
            
end