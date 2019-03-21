function [expmt,tPrev,exit] = updatePauseStop(trackDat,expmt,gui_handles)

if gui_handles.pause_togglebutton.Value && ...
        ~isfield(gui_handles.pause_togglebutton.UserData,'pause_note')
    gui_handles.pause_togglebutton.UserData.pause_note = ...
        gui_axes_notify(gui_handles.axes_handle, 'Tracking Paused');
end
pause(0.005);
exit = false;

if gui_handles.stop_pushbutton.UserData.Value
    
    gui_handles.stop_pushbutton.UserData.Value = false;
    
    t = 'Save or delete data?';
    msg = ['Stop experiment selected!' ... 
        ' Save data collected up to this point or delete files from this experiment.' ... 
        ' Close this window to disregard this message and resume the experiment.'];
    answer = warningbox_subgui('title',t,'string',msg,'buttons',{'Save' 'Delete'});

    switch answer
        case 'Save'
            
            exit = true;
            expmt.meta.finish = true;
            
        case 'Delete'
            
            % set expmt function to return
            exit = true;
            expmt.meta.finish = false;
            
            
        case 'Exit'
            
            exit = false;           
    end
end

tPrev = toc;
drawnow limitrate