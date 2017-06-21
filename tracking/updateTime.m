function [trackDat,tPrev] = updateTime(trackDat, tPrev, expmt, gui_handles, varargin)
    

    % check last frame against block duration if running in block mode
    % otherwise, check against the experiment duration
    if isfield(expmt,'block')
        switch expmt.Name
            case 'Arena Circling'
                trackDat.lastFrame = (trackDat.t - expmt.block.t) > expmt.block.arena_duration * 60;
            case 'Optomotor'
                trackDat.lastFrame = (trackDat.t - expmt.block.t) > expmt.block.opto_duration * 60;
            case 'Slow Phototaxis'
                trackDat.lastFrame = (trackDat.t - expmt.block.t) > expmt.block.photo_duration * 60;
        end
    else
        trackDat.lastFrame = trackDat.t > gui_handles.edit_exp_duration.Value * 3600;
    end
    
    no_plot = false;
    if ~isempty(varargin)
        no_plot = logical(varargin{1});
    end

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
    
    if strcmp(expmt.source,'camera') && ~no_plot
        
        % report time remaining to reference timeout to GUI
        tRemain = round(gui_handles.edit_exp_duration.Value * 3600 - trackDat.t);
        updateTimeString(tRemain, gui_handles.edit_time_remaining);
        
    elseif ~no_plot
        
        frames_remaining = expmt.video.nFrames - trackDat.ct;
        gui_handles.edit_time_remaining.String = num2str(frames_remaining);
        
    end
    
    % update frame rate in the gui
    gui_handles.edit_frame_rate.String = num2str(round((1/ifi)*10)/10);
    

        
    
    