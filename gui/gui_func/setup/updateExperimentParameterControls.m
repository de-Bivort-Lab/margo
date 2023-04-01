function handles = updateExperimentParameterControls(parameters, handles)
%UPDATEEXPERIMENTPARAMETERCONTROLS Summary of this function goes here

handles.edit_ref_depth.Value  = parameters.ref_depth;
handles.edit_ref_freq.Value = parameters.ref_freq;
handles.edit_exp_duration.Value = parameters.duration;
handles.ROI_thresh_slider.Value = ceil(parameters.roi_thresh);
handles.track_thresh_slider.Value = ceil(parameters.track_thresh);
handles.disp_ROI_thresh.String = num2str(handles.ROI_thresh_slider.Value);
handles.disp_track_thresh.String = num2str(handles.track_thresh_slider.Value);
handles.edit_target_rate.String = num2str(parameters.target_rate);
handles.edit_area_maximum.String = num2str(parameters.area_max);

end

