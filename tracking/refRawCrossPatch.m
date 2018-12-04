function trackDat = refRawCrossPatch(trackDat, expmt)
% patch bad areas of the reference with the raw image if possible

% compute inverse difference image and threshold to identify target patches
switch trackDat.ref.bg_mode
    case 'light'
        inv_diff = trackDat.im - trackDat.ref.im;     
    case 'dark'
        inv_diff = trackDat.ref.im - trackDat.im;
end
% adjust difference image to enhance contrast
if expmt.parameters.bg_adjust
    diffim_upper_bound = double(max(inv_diff(:)));
    diffim_upper_bound(diffim_upper_bound==0) = 255;
    inv_diff = imadjust(inv_diff, [0 diffim_upper_bound/255], [0 1]);
end

% threshold blobs by area
inv_thresh = inv_diff > expmt.parameters.track_thresh;
if isfield(expmt.meta.roi,'mask')
    % set pixels outside ROIs to zero
    inv_thresh = inv_thresh & expmt.meta.roi.mask;
end

% get region properties
cc = bwconncomp(inv_thresh, 8);
area = cellfun(@numel,cc.PixelIdxList);

% threshold blobs by area
below_min = area  .* (expmt.parameters.mm_per_pix^2) < ...
    expmt.parameters.area_min;
above_max = area .* (expmt.parameters.mm_per_pix^2) >...
    expmt.parameters.area_max;
oob = below_min | above_max;
if any(oob)
    cc.PixelIdxList(oob) = [];
    cc.NumObjects = cc.NumObjects - sum(oob);
end

% update reference image with target patches from the raw image
pixList = cat(1,cc.PixelIdxList{:});
trackDat.ref.im(pixList) = trackDat.im(pixList);




