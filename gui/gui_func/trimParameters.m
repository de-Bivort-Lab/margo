function out_parameters = trimParameters(in_parameters, gui_handles)
% trim parameters property of ExperimentData to core tracking
% parameters and properties

out_parameters.duration = gui_handles.edit_exp_duration.Value;
out_parameters.ref_depth = gui_handles.edit_ref_depth.Value;
out_parameters.ref_freq = gui_handles.edit_ref_freq.Value;
out_parameters.ROI_thresh = gui_handles.ROI_thresh_slider.Value;
out_parameters.track_thresh = gui_handles.track_thresh_slider.Value;
out_parameters.speed_thresh = in_parameters.speed_thresh;
out_parameters.distance_thresh = in_parameters.distance_thresh;
out_parameters.vignette_sigma = in_parameters.vignette_sigma;
out_parameters.vignette_weight = in_parameters.vignette_weight;
out_parameters.area_min = in_parameters.area_min;
out_parameters.area_max = in_parameters.area_max;
out_parameters.target_rate = in_parameters.target_rate;
out_parameters.mm_per_pix = in_parameters.mm_per_pix;
out_parameters.units = in_parameters.units;
out_parameters.roi_mode = in_parameters.roi_mode;
out_parameters.sort_mode = in_parameters.sort_mode;
out_parameters.roi_tol = in_parameters.roi_tol;
out_parameters.dilate_sz = in_parameters.dilate_sz;
