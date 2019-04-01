function trackDat = setTrackingOptions(trackDat, expmt)
% Split fields into fields going into regionprops and fields 

% temporarily remove fields not recognized by regionprops
prop_fields = {'area';'BoundingBox';'centroid';'Convexarea';'ConvexHull';...
    'ConvexImage';'Eccentricity';'EquivDiameter';'EulerNumber';'Extent';...
    'Extrema';'Filledarea';'FilledImage';'Image';'majorAxisLength';...
    'minorAxisLength';'orientation';'Perimeter';'pixelIdxList';'PixelList';...
    'Solidity';'SubarrayIdx';'weightedCentroid'};

% record which properties to retrieve from 
remove = ~ismember(trackDat.fields,prop_fields);
trackDat.prop_fields = trackDat.fields(~remove);

% add centroid and area to the input regionprops fields if not provided
if ~any(strcmpi('centroid',trackDat.prop_fields)) && ...
        ~any(strcmpi('weightedCentroid',trackDat.prop_fields))
    trackDat.prop_fields = [trackDat.prop_fields; {'centroid'}];
end

% trim props from regionprops list that are provided by bwconncomp
if any(strcmpi('area',trackDat.prop_fields))
    trackDat.prop_fields(strcmpi('area',trackDat.prop_fields)) = [];
end
if any(strcmpi('PixelList',trackDat.prop_fields))
    trackDat.prop_fields(strcmpi('PixelList',trackDat.prop_fields)) = [];
end

% add BoundingBox as a field if dilate/erode mode
if isfield(expmt.parameters,'dilate_element')
    trackDat.prop_fields = [trackDat.prop_fields; {'BoundingBox'}];
end

% define which fields to record each frame
prop_fields = [prop_fields; {'time';'speed';'VideoData';'VideoIndex'}];
record_fields = cat(1,prop_fields',num2cell(false(1,numel(prop_fields))));
trackDat.record = struct(record_fields{:});
for i=1:numel(prop_fields)
    if any(strcmpi(trackDat.fields,prop_fields{i}))
        trackDat.record.(prop_fields{i}) = true;
    end
end

% assign tracking options
has.noise_sample =  isfield(expmt.parameters,'noise_sample');
has.noise = isfield(expmt.meta,'noise');
has.px_dist = isfield(trackDat,'px_dist');
has.noise_dist = has.noise && isfield(expmt.meta.noise,'dist');
has.noise_skip_thresh = isfield(expmt.parameters,'noise_skip_thresh');
has.noise_ref_thresh = isfield(expmt.parameters,'noise_ref_thresh');
has.noise_roi_mean = has.noise && isfield(expmt.meta.noise,'roi_mean');
has.dilate_sz = isfield(expmt.parameters,'dilate_sz');
has.drop_ct = isfield(trackDat,'drop_ct');
has.roi_mask = isfield(expmt.meta,'roi') && isfield(expmt.meta.roi,'mask');
has.ref_t = isfield(trackDat,'ref') && isfield(trackDat.ref,'t');
has.video = strcmpi(expmt.meta.source,'video');
has.video_framerate = has.video && isprop(expmt.meta.video.vid,'FrameRate');
has.video_out = isfield(expmt.meta,'video_out');
has.video_out_data = isfield(expmt.meta,'VideoData');
trackDat.has = has;





