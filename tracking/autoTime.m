function [trackDat] = autoTime(trackDat, expmt, gui_handles, varargin)
    

    % check last frame against block duration if running in block mode
    % otherwise, check against the experiment duration
    if isfield(expmt,'block')
        switch expmt.meta.name
            case 'Arena Circling'
                trackDat.lastFrame = (trackDat.t - expmt.block.t) > expmt.block.arena_duration * 60;
            case 'Optomotor'
                trackDat.lastFrame = (trackDat.t - expmt.block.t) > expmt.block.opto_duration * 60;
            case 'Slow Phototaxis'
                trackDat.lastFrame = (trackDat.t - expmt.block.t) > expmt.block.photo_duration * 60;
        end
    elseif strcmp(expmt.meta.source,'camera')
        trackDat.lastFrame = trackDat.t > gui_handles.edit_exp_duration.Value * 3600;
    end
    
    no_plot = false;
    if ~isempty(varargin)
        no_plot = logical(varargin{1});
    end

    % calculate the interframe interval (ifi)
    tCurrent = toc;
    ifi = tCurrent - trackDat.tPrev;
    trackDat.tPrev=tCurrent;
    gui_update_t = 0;

    %wait if necessary to achieve the target frame rate
    if nargin > 2
        while ifi < 1/gui_handles.gui_fig.UserData.target_rate
            tCurrent = toc;
            ifi = ifi + tCurrent - trackDat.tPrev;
            gui_update_t = gui_update_t + tCurrent - trackDat.tPrev;
            trackDat.tPrev=tCurrent;
            
            % ensure timer is minimally update 1/sec
            if gui_update_t > 1 && strcmp(expmt.meta.source,'camera') && ~no_plot               
                % report time remaining to reference timeout to GUI
                tRemain = round(gui_handles.edit_exp_duration.Value * 3600 - (trackDat.t+ifi));
                updateTimeString(tRemain, gui_handles.edit_time_remaining);
                gui_update_t = 0;
            end
            
            % update gui
            drawnow limitrate
        end
    end    
    
    % update time variables
    trackDat.t = trackDat.t + ifi;
    trackDat.ifi = ifi;
    if isfield(trackDat.ref,'t')
        trackDat.ref.t = trackDat.ref.t + ifi;
        trackDat.ref.last_update = trackDat.ref.last_update + ifi;
    end
    
    % check reference update timer
    trackDat.ref.update = trackDat.ref.t > gui_handles.edit_ref_freq.Value * 60;
    
    if strcmp(expmt.meta.source,'camera') && ~no_plot
        
        % report time remaining to reference timeout to GUI
        tRemain = round(gui_handles.edit_exp_duration.Value * 3600 - trackDat.t);
        updateTimeString(tRemain, gui_handles.edit_time_remaining);
        
    elseif ~no_plot
        
        frames_remaining = expmt.video.nFrames - trackDat.ct;
        gui_handles.edit_time_remaining.String = num2str(frames_remaining);
        
    end
    
    % update frame rate in the gui
    gui_handles.edit_frame_rate.String = num2str(round((1/ifi)*10)/10);
    

        
    
    