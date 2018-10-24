function toggleMenus(gui_handles, state)
% sets the Enable property of Menu handles unable to be accessed during
% imaging to the value in state ('on'/'off') 

gui_handles.refresh_cam_menu.Enable = state;
gui_handles.refresh_COM_menu.Enable = state;
gui_handles.reg_proj_menu.Enable = state;
gui_handles.reg_error_menu.Enable = state;
gui_handles.distance_scale_menu.Enable = state;
gui_handles.vignette_correction_menu.Enable = state;
gui_handles.man_edit_roi_menu.Enable = state;
gui_handles.analysis_menu.Enable = state;
gui_handles.video_menu.Enable = state;
gui_handles.record_video_menu.Enable = state;

