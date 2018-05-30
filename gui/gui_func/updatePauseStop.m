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
            expmt.Finish = false;
            
            % delete master data struct
            delete([expmt.fdir expmt.fLabel '.mat']);
            
            % close fileIDs
            for i = 1:length(trackDat.fields)                           
                fclose(expmt.(trackDat.fields{i}).fID);
                delete(expmt.(trackDat.fields{i}).path);
            end
            
            switch expmt.source
                case 'camera'
                    trackDat.t = 0;
                    tPrev = toc;
                    updateTime(trackDat, tPrev, expmt, gui_handles);
                case 'video'
                    gui_handles.edit_time_remaining.String = '-';
            end
            
            % delete the experiment directory
            if isfield(expmt,'rawdir')
                rmdir(expmt.rawdir);
            end
            rmdir(expmt.fdir);
            
            df = {'date' 'fLabel'};
            expmt = rmfield(expmt,df);
            
        case 'Exit'
            
            exit = false;           
    end
end

tPrev = toc;