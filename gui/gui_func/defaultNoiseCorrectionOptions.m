function param = defaultNoiseCorrectionOptions(param)

% set default values for noise correction
param.noise_sample = true;              % enable/disable noise sampling and correction
param.noise_sample_num = 100;           % n frames to sample for noise distribution
param.noise_skip_thresh = 9;            % n std. dev above baseline for frame skipping
param.noise_ref_thresh = 10;            % n std. dev above baseline for background reset
param.noise_estimate_missing = true;    % estimate noise in empty rois by bootstrap resampling

