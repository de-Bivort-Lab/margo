function [pinwheel]=initialize_pinwheel(xdim,ydim,nCycles,mask_r)

% Generates a pinwheel image to be used in texture generation.
% Inputs:
% xdim = number of pixels in x
% ydim = number of pixels in y
% nCycles = number of cycles in 360 degrees
% mask_r = radius of the center dark circular mask expressed as a fraction
% of the image width

xdim=round(xdim/2);
ydim=round(ydim/2);

% Define black and white
white = 1;
black = 0;
grey = white / 2;
inc = white - grey;

% Contrast for our contrast modulation mask: 0 = mask has no effect, 1 = mask
% will at its strongest part be completely opaque i.e. 0 and 100% contrast
% respectively
contrast = 1;

% Define the stimulus texture
[x, y] = meshgrid(-xdim:xdim, -ydim:ydim);
[th, r] = cart2pol(x, y);
grey=white/2;
inc=white-grey;
wheel = grey + inc .* cos(nCycles*th);
wheel(wheel>0.5)=1;
wheel(wheel<=0.5)=0;

[s1, s2] = size(x);
pinwheel= wheel .* contrast;

% Black out the center of the pinwheel
r=size(pinwheel,2)*mask_r;
center=round([size(pinwheel,2)/2 size(pinwheel,1)/2]);
x=1:size(pinwheel,2);
y=1:size(pinwheel,1);
a=repmat(x,length(y),1);
a=a(:);
b=repmat(y,1,length(x));
d=sqrt((center(1)-a).^2+(center(2)-b').^2);
d_mask=d<=r;
pinwheel(d_mask)=0;

