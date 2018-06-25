function [expmt,tPrev,exit] = updatePauseStop(trackDat,expmt,gui_handles)

pause(0.005);
exit = false;

if gui_handles.stop_pushbutton.UserData.Value
    
    gui_handles.stop_pushbutton.UserData.Value = false;
    
    t = 'Save or delete data?';
    msg = ['Stop experiment selected!' ... 
        ' Save data collected up to this point or delete files from this experiment.' ... 
        'Close this window to disregard this message and resume the experiment.'];
    answer = warningbox_subgui('title',t,'string',msg,'buttons',{'Save' 'Delete'});

    switch answer
        case 'Save'
            
            exit = true;
            
            % wrap up expmt and save struct
            expmt = autoFinish(trackDat, expmt, gui_handles);
            
        case 'Delete'
            
            % set expmt function to return
            exit = true;
            expmt.meta.finish = false;
            
            % delete master data struct
            delete([expmt.meta.path.dir expmt.meta.path.name '.mat']);
            
            % close fileIDs
            for i = 1:length(trackDat.fields)                           
                fclose(expmt.data.(trackDat.fields{i}).fID);
                delete(expmt.data.(trackDat.fields{i}).path);
            end
            
            switch expmt.meta.source
                case 'camera'
                    trackDat.t = 0;
                    trackDat.tPrev = toc;
                    autoTime(trackDat, expmt, gui_handles);
                case 'video'
                    gui_handles.edit_time_remaining.String = '-';
            end
            
            % delete the experiment directory
            if exist(expmt.meta.path.dir,'dir')==7
                rmdir(expmt.meta.path.dir,'s');
            end
            
            expmt.meta.data = [];
            expmt.meta.path.name = [];
            
        case 'Exit'
            
            exit = false;           
    end
end

tPrev = toc;