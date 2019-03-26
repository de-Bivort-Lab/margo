function gui_handles = toggleSubguis(gui_handles,state)

% this function enables/disables subguis of margo.
% any function control that opens a separate window cannot be accessed
% during experiments and should be disabled. Use this function to easily
% toggle between enabled and disabled states for all controls that open
% dependent subguis

set(gui_handles.tracking_menu.Children,'Enable','off');
gui_handles.advanced_tracking_menu.Enable = 'on';
gui_handles.proj_settings_menu.Enable = state;
gui_handles.exp_parameter_pushbutton.Enable = state;
gui_handles.exp_select_popupmenu.Enable = state;
gui_handles.enter_labels_pushbutton.Enable = state;
gui_handles.save_path_button1.Enable = state;
gui_handles.auto_detect_ROIs_pushbutton.Enable = state;
gui_handles.reference_pushbutton.Enable = state;
gui_handles.save_path.Enable = state;
gui_handles.sample_noise_pushbutton.Enable = state;
gui_handles.cam_settings_menu.Enable = state;
gui_handles.select_source_menu.Enable = state;
gui_handles.file_menu.Enable = state;
gui_handles.vid_scrubber_slider.Enable = state;
set(gui_handles.cam_uipanel.Children,'Enable',state);