function parameters = loadSavedParameters(gui_handles,profile)
%
% This function loads parameters and gui selections from a saved
% profile for rapid experimental setup.

load_path =[gui_handles.gui_dir 'profiles\'];

load(strcat(load_path,profile,'.mat'),'-mat','exp');
parameters = exp;

% Update GUI with values

if ~isempty(exp.camInfo)
set(gui_handles.edit_exposure,'string',num2str(exp.camInfo.Exposure));
end

if ~isempty(exp.camInfo)
set(gui_handles.edit_gain,'string',num2str(exp.camInfo.Gain));
end

if ~isempty(exp.camInfo)
set(gui_handles.edit_cam_shutter,'string',num2str(exp.camInfo.Shutter));
end

if isfield(exp,'White_intensity')
set(gui_handles.edit_White_intensity,'string',num2str(exp.White_intensity));
end

if isfield(exp,'IR_intensity')
set(gui_handles.edit_IR_intensity,'string',num2str(exp.IR_intensity));
end


if isfield(exp,'duration')
set(gui_handles.edit_exp_duration,'string',num2str(exp.duration));
end

if isfield(exp,'ref_stack_size')
set(gui_handles.edit_ref_stack_size,'string',num2str(exp.ref_stack_size));
end

if isfield(exp,'ref_freq')
set(gui_handles.edit_ref_freq,'string',num2str(exp.ref_freq));
end

if isfield(exp,'experiment')
set(gui_handles.exp_select_popupmenu,'value',exp.experiment);
end

if isfield(exp,'fpath')
set(gui_handles.save_path,'string',exp.fpath);
end

if isfield(exp,'ROI_thresh')
set(gui_handles.disp_ROI_thresh,'string',num2str(round(exp.ROI_thresh*100)/100));
end

if isfield(exp,'ROI_thresh')
set(gui_handles.ROI_thresh_slider,'value',exp.ROI_thresh);
end

if isfield(exp,'tracking_thresh')
set(gui_handles.disp_track_thresh,'string',num2str(round(exp.tracking_thresh*100)/100));
end

if isfield(exp,'tracking_thresh')
set(gui_handles.track_thresh_slider,'value',exp.tracking_thresh);
end


