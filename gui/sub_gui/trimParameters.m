function out_parameters = trimParameters(gui_handles)

out_parameters.duration = gui_handles.edit_exp_duration.Value;
out_parameters.ref_depth = gui_handles.edit_ref_depth.Value;
out_parameters.ref_freq = gui_handles.edit_ref_freq.Value;
out_parameters.ROI_thresh = gui_handles.ROI_thresh_slider.Value;
out_parameters.tracking_thresh = gui_handles.track_thresh_slider.Value;
