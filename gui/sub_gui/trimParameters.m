function out_parameters = trimParameters(in_parameters, gui_handles)

out_parameters.duration = gui_handles.edit_exp_duration.Value;
out_parameters.ref_depth = gui_handles.edit_ref_depth.Value;
out_parameters.ref_freq = gui_handles.edit_ref_freq.Value;
out_parameters.ROI_thresh = gui_handles.ROI_thresh_slider.Value;
out_parameters.track_thresh = gui_handles.track_thresh_slider.Value;
out_parameters.speed_thresh = gui_handles.gui_fig.UserData.speed_thresh;
out_parameters.distance_thresh = gui_handles.gui_fig.UserData.distance_thresh;
out_parameters.vignette_sigma = gui_handles.gui_fig.UserData.vignette_sigma;
out_parameters.vignette_weight = gui_handles.gui_fig.UserData.vignette_weight;
out_parameters.area_min = gui_handles.gui_fig.UserData.area_min;
out_parameters.area_max = gui_handles.gui_fig.UserData.area_max;
out_parameters.mm_per_pix = in_parameters.mm_per_pix;
out_parameters.units = in_parameters.units;
out_parameters.ROI_mode = in_parameters.ROI_mode;
out_parameters.sort_mode = in_parameters.sort_mode;
