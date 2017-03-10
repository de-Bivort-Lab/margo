function [trackDat,tPrev] = updateTime(trackDat, tPrev, expmt, gui_handles)
    
    % calculate the interframe interval (ifi)
    tCurrent = toc;
    ifi = tCurrent - tPrev;
    tPrev=tCurrent;

    %wait if necessary to achieve the target frame rate
    if nargin > 2
        while ifi < 1/gui_handles.gui_fig.UserData.target_rate
            tCurrent = toc;
            ifi = ifi + tCurrent - tPrev;
            tPrev=tCurrent;
        end
    end    
    
    % update time variables
    trackDat.t = trackDat.t + ifi;
    trackDat.ifi = ifi;
    if isfield(trackDat,'t_ref')
        trackDat.t_ref = trackDat.t_ref + ifi;
    end
    
    if strcmp(expmt.source,'camera')
        
        % report time remaining to reference timeout to GUI
        tRemain = round(gui_handles.edit_exp_duration.Value * 3600 - trackDat.t);
        updateTimeString(tRemain, gui_handles.edit_time_remaining);
        
    else
        
        frames_remaining = expmt.video.nFrames - trackDat.ct;
        gui_handles.edit_time_remaining.String = num2str(frames_remaining);
        
    end
    
        % update frame rate in the gui
    gui_handles.edit_frame_rate.String = num2str(round((1/ifi)*10)/10);
    

        
    
    