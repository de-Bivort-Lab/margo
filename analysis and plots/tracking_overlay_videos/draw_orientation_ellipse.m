function draw_orientation_ellipse(expmt, frame_num, im, mask, heading)
% draw an ellipse on each tracked object in tracking overlay video
%
% Inputs
%   expmt - ExperimentData for the tracking session
%   frame_num - index of the acquisition frame
%   im - input image to modify
%   mask - logical mask of tracked objects to draw ellipse
%   heading - option (true/false) to draw head/tail markers from heading
% Outputs
%   im_out - modified input image with draw ellipses

