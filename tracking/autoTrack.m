function [trackDat] = autoTrack(trackDat,expmt,gui_handles)

%% Parse fields

    out_fields = trackDat.fields;
    in_fields = trackDat.fields;
    
    % temporarily remove fields not recognized by regionprops
    prop_fields = [{'Area'};{'BoundingBox'};{'Centroid'};{'ConvexArea'};{'ConvexHull'};...
        {'ConvexImage'};{'Eccentricity'};{'EquivDiameter'};{'EulerNumber'};{'Extent'};...
        {'Extrema'};{'FilledArea'};{'FilledImage'};{'Image'};{'MajorAxisLength'};...
        {'MinorAxisLength'};{'Orientation'};{'Perimeter'};{'PixelIdxList'};{'PixelList'};...
        {'Solidity'};{'SubarrayIdx'}];
    remove = ~ismember(in_fields,prop_fields);
    in_fields(remove) = [];
    
    % add centroid and area to the input regionprops fields if not provided
    if ~any(strmatch('Centroid',in_fields))
        in_fields = [in_fields; {'Centroid'}];
    end

    if ~any(strmatch('Area',in_fields))
        in_fields = [in_fields; {'Area'}];
    end
    
%% Track objects

    trackDat.ct = trackDat.ct + 1;

    % calculate difference image and current for vignetting
    diffim = (expmt.ref - expmt.vignette.im) - (trackDat.im - expmt.vignette.im);
    
    % get current image threshold and use it to extract region properties     
    im_thresh = get(gui_handles.track_thresh_slider,'value');
    
    % threshold image
    thresh_im = diffim > im_thresh;
    
    % check image noise and dump frame if noise is too high
    record = true;
    if isfield(trackDat,'px_dist')
        
        trackDat.px_dist(mod(trackDat.ct,length(trackDat.px_dist))+1) = sum(sum(thresh_im));
        trackDat.px_dev((mod(trackDat.ct,length(trackDat.px_dist))+1)) =...
            ((nanmean(trackDat.px_dist) - expmt.noise.mean)/expmt.noise.std);
        
        if trackDat.px_dev((mod(trackDat.ct,length(trackDat.px_dist))+1)) > 7
            record = false;
        end
    end
        
    if record  
        
        % get region properties
        props=regionprops(thresh_im, in_fields);

        % threshold blobs by area
        above_min = [props.Area]  .* (expmt.parameters.mm_per_pix^2) > ...
            gui_handles.gui_fig.UserData.area_min;
        below_max = [props.Area] .* (expmt.parameters.mm_per_pix^2) <...
            gui_handles.gui_fig.UserData.area_max;
        props(~(above_min & below_max)) = [];

        raw_cen = reshape([props.Centroid],2,length([props.Centroid])/2)';

        % Match centroids to last known centroid positions
        [permutation,update] = ...
            matchCentroids2ROIs(raw_cen,trackDat.Centroid,expmt,gui_handles);

        % Apply speed threshold to centroid tracking
        speed = NaN(size(update));

        if any(update)
            
            % calculate distance and convert from pix to mm
            d = sqrt((raw_cen(permutation,1)-trackDat.Centroid(update,1)).^2 ...
                     + (raw_cen(permutation,2)-trackDat.Centroid(update,2)).^2);
            d = d .* expmt.parameters.mm_per_pix;
            
            % time elapsed since each centroid was last updated
            dt = trackDat.t - trackDat.tStamp(update);
            
            % calculate speed and exclude centroids over speed threshold
            tmp_spd = d./dt;
            above_spd_thresh = tmp_spd > gui_handles.gui_fig.UserData.speed_thresh;
            permutation(above_spd_thresh)=[];
            update(update) = ~above_spd_thresh;
            speed(update) = tmp_spd(~above_spd_thresh);
            
        end

        % Use permutation vector to sort raw centroid data and update
        % vector to specify which centroids are reliable and should be updated
        trackDat.Centroid(update,:) = raw_cen(permutation,:);
        trackDat.tStamp(update) = trackDat.t;
        
        % update centroid drop count for objects not updated this frame
        if isfield(trackDat,'drop_ct')
            trackDat.drop_ct(~update) = trackDat.drop_ct(~update) + 1;
        end
    
    else
        
        % icrement drop count for all objects if entire frame is dropped
        if isfield(trackDat,'drop_ct')
            trackDat.drop_ct = trackDat.drop_ct + 1;
        end
        
    end
    
%% Assign outputs

% assign any optional sorted output fields to the trackDat
% structure if listed in expmt.fields. 
% return NaNs if record = false

    if any(strmatch('Speed',out_fields));
        if record
            trackDat.Speed = speed;
        else
            trackDat.Speed = NaN(size(trackDat.Centroid,1),1); 
        end
    end

    if any(strmatch('Area',out_fields));
        area = NaN(size(trackDat.Centroid,1),1);
        if record
            area(update) = [props(permutation).Area];
        end
        trackDat.Area = area;
    end

    if any(strmatch('Orientation',out_fields));
        orientation = NaN(size(trackDat.Centroid,1),1);
        if record
            orientation(update) = [props(permutation).Orientation];
        end
        trackDat.Orientation = orientation;
    end

    if any(strmatch('Time',out_fields));
        trackDat.Time = trackDat.ifi;
    end

    if any(strmatch('VideoData',out_fields));
        trackDat.VideoData = trackDat.im;
    end

    if any(strmatch('VideoIndex',out_fields));
        trackDat.VideoIndex = trackDat.ct;
    end
    
    
            