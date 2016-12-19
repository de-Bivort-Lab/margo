function [stim]=initialize_photo_stim(xdim,ydim,stim_divider_size,contrast)

% Generates a pinwheel image to be used in texture generation.
% Inputs:
% xdim = number of pixels in x
% ydim = number of pixels in y
% divider_size = width of the gray band separating light and dark regions

%% Initialize stimulus

% Define the stimulus texture
stim = zeros(ydim,xdim);
mid = round(ydim/2);
stim(1:mid,:)=contrast;

% Define the divider line
div_value = logspace(log10(1),log10(256),3)-1;
div_value = div_value(2)/div_value(3);
div_value=contrast/2;
stim_divider_size = stim_divider_size*xdim;
div_ub = mid+round(stim_divider_size/2);
div_lb = mid-round(stim_divider_size/2)+1;
stim(div_lb:div_ub,:)=div_value;

