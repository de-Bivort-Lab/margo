function trackDat = refRawCrossPatch(trackDat, expmt)
% patch bad areas of the reference with the raw image if possible

refin = trackDat.ref.im;

% compute inverse difference image and threshold to identify target patches
switch trackDat.ref.bg_mode
    case 'light'
        inv_diff = trackDat.im - trackDat.ref.im;     
    case 'dark'
        inv_diff = trackDat.ref.im - trackDat.im;
end

% threshold blobs by area
inv_thresh = inv_diff > expmt.parameters.track_thresh;
props = regionprops(inv_thresh,'Area','PixelIdxList');
above_min = [props.Area]  .* (expmt.parameters.mm_per_pix^2) > ...
    expmt.parameters.area_min;
below_max = [props.Area] .* (expmt.parameters.mm_per_pix^2) <...
    expmt.parameters.area_max;
props(~(above_min & below_max)) = [];

% update reference image with target patches from the raw image
pixList = cat(1,props.PixelIdxList);
trackDat.ref.im(pixList) = trackDat.im(pixList);




