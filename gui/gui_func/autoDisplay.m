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
disp_menu = gui_handles.display_menu;
active_disp = disp_menu.UserData;

switch active_disp

    % raw image
    case 'raw'         
        im_handle.CData = trackDat.im;
        if strcmp(im_handle.CDataMapping,'direct')
            im_handle.CDataMapping = 'scaled';
        end
        if any(gui_handles.axes_handle.CLim ~= [0 255])
            gui_handles.axes_handle.CLim = [0 255];
        end

    % difference image
    case 'difference'
        if isfield(trackDat,'diffim')
        im_handle.CData = trackDat.diffim;
            if strcmp(im_handle.CDataMapping,'scaled')
                im_handle.CDataMapping = 'direct';
            end
            if any(gui_handles.axes_handle.CLim ~= [0 255])
                gui_handles.axes_handle.CLim = [0 255];
            end
        else
            set_display_mode(disp_menu,'difference','Disable',true);
        end

    % threshold image
    case 'threshold'
        if isfield(trackDat,'thresh_im')
            im_handle.CData = trackDat.thresh_im;
            if strcmp(im_handle.CDataMapping,'direct')
                im_handle.CDataMapping = 'scaled';
            end
            if any(gui_handles.axes_handle.CLim ~= [0 1])
                gui_handles.axes_handle.CLim = [0 1];
            end
        else
            set_display_mode(disp_menu,'threshold','Disable',true);
        end

    % reference image
    case 'reference'
        if isfield(trackDat,'ref') && isfield(trackDat.ref,'im')
            im_handle.CData = trackDat.ref.im;
            if strcmp(im_handle.CDataMapping,'direct')
                im_handle.CDataMapping = 'scaled';
            end
        else 
            set_display_mode(disp_menu,'reference','Disable',true);
        end
        if any(gui_handles.axes_handle.CLim ~= [0 255])
            gui_handles.axes_handle.CLim = [0 255];
        end
        
    case 'composite'
        if isfield(trackDat,'thresh_im')
            R = trackDat.im;
            G = trackDat.im;
            R(trackDat.thresh_im) = 255;
            G(trackDat.thresh_im) = 0;
            im_handle.CData = cat(3,R,G,G);
            if strcmp(im_handle.CDataMapping,'direct')
                im_handle.CDataMapping = 'scaled';
            end
            if any(gui_handles.axes_handle.CLim ~= [0 255])
                gui_handles.axes_handle.CLim = [0 255];
            end
        else
            set_display_mode(disp_menu,'composite','Disable',true);
        end
        
    case 'none'
        if isempty(gui_handles.display_none_menu.UserData)
            msg = 'Display disabled';
            ax = gui_handles.axes_handle;
            loc = [ax.XLim(2)*0.01 ax.YLim(2)*0.01];
            gui_handles.display_none_menu.UserData = ...
                gui_axes_notify(ax,msg,'color','r',...
                'FontSize',14,'Position', loc, 'Alignment', 'left');
        end
end

if ~strcmp(active_disp,'none')
    if isfield(gui_handles.gui_fig.UserData,'cenText') && ...
            ishghandle(gui_handles.gui_fig.UserData.cenText(1)) &&...
            strcmp(gui_handles.gui_fig.UserData.cenText(1).Visible,'on')

         arrayfun(@updateText,gui_handles.gui_fig.UserData.cenText,...
             num2cell(trackDat.centroid,2),(1:size(trackDat.centroid,1))',...
             repmat(size(trackDat.im,1)*.015,size(trackDat.centroid,1),1));

    end
    if strcmp(gui_handles.view_ref_stack_depth.Checked,'on') && ...
            isfield(trackDat,'ref') && isfield(trackDat.ref,'ct')
        % Initialize color variables
        hsv_base = 360;                         % hsv red
        hsv_targ = 240;                         % hsv blue
        color_scale = 1 - hsv_targ/hsv_base;
        
        % initialize indicator if necessary
        if ~isfield(trackDat,'hRefCirc') || ~ishghandle(trackDat.hRefCirc(1))
            hold(gui_handles.axes_handle,'on');
            color = zeros(expmt.meta.roi.n,3);
            color(:,1) = 1;
            trackDat.hRefCirc = scatter(expmt.meta.roi.corners(:,1),...
                expmt.meta.roi.corners(:,2),...
                'o','filled','LineWidth',2);
            trackDat.hRefCirc.CData = color;
            hold(gui_handles.axes_handle,'off');
        end
        
        % Update ref number color indicator
        hue = 1-color_scale.*trackDat.ref.ct./expmt.parameters.ref_depth;
        hsv_color = ones(numel(hue),3);
        hsv_color(:,1) = hue;
        color = hsv2rgb(hsv_color);
        trackDat.hRefCirc.CData = color;
    else
        if isfield(trackDat,'hRefCirc')
            delete(trackDat.hRefCirc);
            trackDat = rmfield(trackDat,'hRefCirc');
        end
    end
    if isfield(trackDat,'hMark') && ishghandle(trackDat.hMark(1))
        trackDat.hMark.XData = trackDat.centroid(:,1);
        trackDat.hMark.YData = trackDat.centroid(:,2);
        if strcmp(active_disp,'composite') && ...
                (any(trackDat.hMark.Color ~= [0 0 1]) && ...
                any(trackDat.hMark.Color ~= 'b'))
            trackDat.hMark.Color = [0 0 1];
        elseif  ~strcmp(active_disp,'composite') && ...
                (any(trackDat.hMark.Color ~= [1 0 0]) && ...
                any(trackDat.hMark.Color ~= 'r'))
            trackDat.hMark.Color = [1 0 0];
        end
    end
    if ~isempty(gui_handles.display_none_menu.UserData)
       cellfun(@(h) delete(h),gui_handles.display_none_menu.UserData); 
       gui_handles.display_none_menu.UserData = [];
    end
end

% force immediate screen drawing and callback evaluation
drawnow limitrate                 

% listen for gui pause/unpause
while gui_handles.pause_togglebutton.UserData.Value || ...
        gui_handles.stop_pushbutton.UserData.Value
    
    [expmt,trackDat.tPrev,exit] = updatePauseStop(trackDat,expmt,gui_handles);
    if exit
        trackDat.lastFrame = true;
        expmt.meta.ref = trackDat.ref;
        expmt.meta.sample_im = trackDat.im;
        if isfield(trackDat,'px_dist') && expmt.parameters.noise_sample
            expmt.meta.noise.tracking_dist = sum(trackDat.thresh_im(:));
            expmt.meta.noise.tracking_dev = ((nanmean(trackDat.px_dist) - ...
                    expmt.meta.noise.mean)/expmt.meta.noise.std);
        end
        return
    end
end
if isfield(gui_handles.pause_togglebutton.UserData,'pause_note')
   cellfun(@(h) delete(h), ...
       gui_handles.pause_togglebutton.UserData.pause_note); 
end



function updateText(h,pos,n,offset)

if ~isnan(pos{1}(1))
    h.Position = pos{:} - [0 offset];
    if isempty(h.String)
        h.String = sprintf('%i',n);
    end
elseif ~isempty(h.String)
    h.String = '';
    h.Position = pos{:};
end



