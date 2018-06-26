function trackDat = refRawCrossPatch(trackDat, expmt, gui_handles)
% patch bad areas of the reference with the raw image if possible


% compute inverse difference image and threshold to identify target patches
switch trackDat.ref.bg_mode
    case 'light'
        inv_diff = trackDat.im - trackDat.ref.im;     
    case 'dark'
        inv_diff = trackDat.ref.im - trackDat.im;
end

% threshold blobs by area
inv_thresh = inv_diff > gui_handles.track_thresh_slider.Value;
props = regionprops(inv_thresh,'Area','PixelIdxList');
above_min = [props.Area]  .* (expmt.parameters.mm_per_pix^2) > ...
    gui_handles.gui_fig.UserData.area_min;
below_max = [props.Area] .* (expmt.parameters.mm_per_pix^2) <...
    gui_handles.gui_fig.UserData.area_max;
props(~(above_min & below_max)) = [];

% update reference image with target patches from the raw image
pixList = cat(1,props.PixelIdxList);
trackDat.ref.im(pixList) = trackDat.im(pixList);

%
%{
vim = trackDat.ref.im-expmt.meta.vignette.im;
vim_lum = mean(vim(expmt.meta.roi.mask));
vim_thresh = vim < vim_lum;
vim_thresh(~expmt.meta.roi.mask)=255;
props = regionprops(vim_thresh,'Area','PixelIdxList');
above_min = [props.Area]  .* (expmt.parameters.mm_per_pix^2) > ...
    gui_handles.gui_fig.UserData.area_min*2;
below_max = [props.Area] .* (expmt.parameters.mm_per_pix^2) <...
    gui_handles.gui_fig.UserData.area_max;
props(~(above_min & below_max)) = [];

pixList = cat(1,props.PixelIdxList);
pix_lums = vim_lum + (vim_lum - vim(pixList));
trackDat.ref.im(pixList) = pix_lums;
a(pixList)=255;
figure;imshow(a);
%}



