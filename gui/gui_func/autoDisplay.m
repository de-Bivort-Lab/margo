function [trackDat,expmt] = autoDisplay(trackDat, expmt, im_handle, gui_handles)
%   Updates the GUI display with the current frame image (trackDat.im)
% 
%   Inputs
%
%   trackDat    struct updated with frame to frame tracking data, and holds
%               both the current frame's image (trackDat.im) and the
%               reference image data (trackDat.ref.im)
%
%   expmt       master struct containing experiment meta data, parameters,
%               and hardware settings 
%
%   gui_handles struct containing handles for all GUI objects
%
%   Outputs
%
%   trackDat    updated with lastFrame flag if pause/stop
%               
%   expmt       updated with closed files if pause/stop


% query the active display mode
active_disp = gui_handles.display_menu.UserData;

switch active_disp

    % raw image
    case 1         
        im_handle.CData = trackDat.im;
        if strcmp(im_handle.CDataMapping,'direct')
            im_handle.CDataMapping = 'scaled';
        end
        if any(gui_handles.axes_handle.CLim ~= [0 255])
            gui_handles.axes_handle.CLim = [0 255];
        end

    % difference image
    case 2
        if isfield(expmt,'ref') && isfield(expmt.meta.vignette,'im')
        im_handle.CData = ...
            (trackDat.ref.im-expmt.meta.vignette.im)-(trackDat.im-expmt.meta.vignette.im);
            if strcmp(im_handle.CDataMapping,'scaled')
                im_handle.CDataMapping = 'direct';
            end
            if any(gui_handles.axes_handle.CLim ~= [0 255])
                gui_handles.axes_handle.CLim = [0 255];
            end
        else
            gui_handles.display_menu.UserData = 1;
            gui_handles.display_menu.Children(5).Checked= 'on';
            gui_handles.display_menu.Children(4).Checked= 'off';
            gui_handles.display_menu.Children(4).Enable = 'off';
        end

    % threshold image
    case 3 
        if isfield(trackDat,'thresh_im')
            im_handle.CData = trackDat.thresh_im;
            if strcmp(im_handle.CDataMapping,'direct')
                im_handle.CDataMapping = 'scaled';
            end
            if any(gui_handles.axes_handle.CLim ~= [0 1])
                gui_handles.axes_handle.CLim = [0 1];
            end
        else
            gui_handles.display_menu.UserData = 1;
            gui_handles.display_menu.Children(5).Checked= 'on';
            gui_handles.display_menu.Children(3).Checked= 'off';
            gui_handles.display_menu.Children(3).Enable = 'off';
        end

    % reference image
    case 4
        if isfield(trackDat,'ref') && isfield(trackDat.ref,'im')
            im_handle.CData = trackDat.ref.im;
            if strcmp(im_handle.CDataMapping,'direct')
                im_handle.CDataMapping = 'scaled';
            end
        else 
            gui_handles.display_menu.UserData = 1;
            gui_handles.display_menu.Children(5).Checked= 'on';
            gui_handles.display_menu.Children(2).Checked= 'off';
            gui_handles.display_menu.Children(2).Enable = 'off';
        end
        if any(gui_handles.axes_handle.CLim ~= [0 255])
            gui_handles.axes_handle.CLim = [0 255];
        end
end

if gui_handles.display_menu.UserData ~= 5
    if isfield(gui_handles.gui_fig.UserData,'cenText') && ...
            ishghandle(gui_handles.gui_fig.UserData.cenText(1)) &&...
            strcmp(gui_handles.gui_fig.UserData.cenText(1).Visible,'on')

        arrayfun(@updateText,gui_handles.gui_fig.UserData.cenText,...
            num2cell(trackDat.centroid,2));
    end
    if isfield(trackDat,'hMark') && ishghandle(trackDat.hMark(1))
        trackDat.hMark.XData = trackDat.centroid(:,1);
        trackDat.hMark.YData = trackDat.centroid(:,2);
    end
end

% force immediate screen drawing and callback evaluation
drawnow limitrate                 

% listen for gui pause/unpause
while gui_handles.pause_togglebutton.Value || gui_handles.stop_pushbutton.UserData.Value
    [expmt,trackDat.tPrev,exit] = updatePauseStop(trackDat,expmt,gui_handles);
    if exit
        trackDat.lastFrame = true;
        return
    end
end


function updateText(h,pos)

h.Position = pos{:};



