function [trackDat] = autoTime(trackDat, expmt, gui_handles, varargin)
    

% check last frame against block duration if running in block mode
% otherwise, check against the experiment duration
if strcmp(expmt.meta.source,'camera')
    trackDat.lastFrame = trackDat.t > gui_handles.edit_exp_duration.Value * 3600;
end

no_plot = false;
if ~isempty(varargin)
    no_plot = logical(varargin{1});
end

% calculate the interframe interval (ifi)
if strcmp(expmt.meta.source,'video') && ...
        isprop(expmt.meta.video.vid,'FrameRate') && false

    ifi = 1/expmt.meta.video.vid.FrameRate;
    tCurrent = trackDat.tPrev + ifi;
else
    tCurrent = toc;
    ifi = tCurrent - trackDat.tPrev;
end

trackDat.tPrev=tCurrent;
gui_update_t = 0;

%wait if necessary to achieve the target frame rate
if nargin > 2
    exit = false;
    while ifi < 1/expmt.parameters.target_rate && ~exit
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

        % listen for gui pause/unpause
        while gui_handles.pause_togglebutton.UserData.Value ||...
                gui_handles.stop_pushbutton.UserData.Value

            [expmt,trackDat.tPrev,exit] = updatePauseStop(trackDat,expmt,gui_handles);
            if exit
                trackDat.lastFrame = true;
            end
        end

        % update gui
        drawnow limitrate
    end
end    

% update timer variables
trackDat.t = trackDat.t + ifi;
trackDat.ifi = ifi;
if isfield(trackDat.ref,'t')
    % referencing timer update
    trackDat.ref.t = trackDat.ref.t + ifi;
    trackDat.ref.last_update = trackDat.ref.last_update + ifi;
end
if isfield(expmt.meta,'video_out') && expmt.meta.video_out.rate >= 0
    
    % video sub-sampling timer update
    expmt.meta.video_out.t = expmt.meta.video_out.t + ifi;
    if any(strcmpi('video_index',expmt.meta.fields))
       if expmt.meta.video_out.t > 1/expmt.meta.video_out.rate
            trackDat.video_index = true;
       else
           trackDat.video_index = false;
       end
    end
end

% check reference update timer
trackDat.ref.update = trackDat.ref.t > (1/trackDat.ref.freq) * 60;

if strcmp(expmt.meta.source,'camera') && ~no_plot

    % report time remaining to reference timeout to GUI
    tRemain = round(gui_handles.edit_exp_duration.Value * 3600 - trackDat.t);
    updateTimeString(tRemain, gui_handles.edit_time_remaining);

elseif ~no_plot

    frames_remaining = expmt.meta.video.nFrames - expmt.meta.video.current_frame;
    gui_handles.edit_time_remaining.String = num2str(frames_remaining);

end

% update frame rate in the gui
gui_handles.edit_frame_rate.String = num2str(round((1/ifi)*10)/10);

    

        
    
    