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
    if ~any(strcmp('Centroid',in_fields))
        in_fields = [in_fields; {'Centroid'}];
    end

    if ~any(strcmp('Area',in_fields))
        in_fields = [in_fields; {'Area'}];
    end
    
    % add BoundingBox as a field if dilate/erode mode
    if isfield(expmt.parameters,'dilate_element')
        in_fields = [in_fields; {'BoundingBox'}];
    end
    
%% Track objects

    trackDat.ct = trackDat.ct + 1;

    % calculate difference image and current for vignetting
    diffim = (expmt.ref - expmt.vignette.im) - (trackDat.im - expmt.vignette.im);
    
    % get current image threshold and use it to extract region properties     
    im_thresh = get(gui_handles.track_thresh_slider,'value');
    
    % threshold image
    thresh_im = diffim > im_thresh;
    if isfield(expmt.ROI,'mask')
        thresh_im = thresh_im & expmt.ROI.mask;
    end
    
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
        
        if ~isfield(expmt.parameters,'dilate_element')
            
            % get region properties
            props=regionprops(thresh_im, in_fields);

            % threshold blobs by area
            above_min = [props.Area]  .* (expmt.parameters.mm_per_pix^2) > ...
                gui_handles.gui_fig.UserData.area_min;
            below_max = [props.Area] .* (expmt.parameters.mm_per_pix^2) <...
                gui_handles.gui_fig.UserData.area_max;
            props(~(above_min & below_max)) = [];

            raw_cen = reshape([props.Centroid],2,length([props.Centroid])/2)';
            
        else
            
            if isempty(expmt.parameters.dilate_element)
                expmt.parameters.dilate_element = ...
                    strel('disk',6);
            end
            
            % dilate and erode with same element to connect components
            dim = imdilate(thresh_im,expmt.parameters.dilate_element);
            eim = imerode(dim,expmt.parameters.dilate_element);
            
            % get region properties
            props=regionprops(eim, in_fields);

            % threshold blobs by area
            below_max = [props.Area] .* (expmt.parameters.mm_per_pix^2) <...
                gui_handles.gui_fig.UserData.area_max;
            above_min = [props.Area]  .* (expmt.parameters.mm_per_pix^2) > ...
                    gui_handles.gui_fig.UserData.area_min;
            props(~(above_min & below_max)) = [];
            
            % find new centroid estimates
            mim = diffim;
            mim(~eim) = 0;
            
            b = reshape([props.BoundingBox],4,length([props.BoundingBox])/4)';
            b = num2cell(b,2);
            raw_cen = arrayfun(@(k) estimateCen(k,mim), b, 'UniformOutput',false);
            raw_cen = cell2mat(raw_cen);
            
            clearvars dim eim mim
            
        end

        % Match centroids to last known centroid positions
        [permutation,update,raw_cen] = ...
            matchCentroids2ROIs(raw_cen,trackDat,expmt,gui_handles);

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
        trackDat.Centroid(update,:) = single(raw_cen(permutation,:));
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

    if any(strcmp('Speed',out_fields))
        if record
            trackDat.Speed = single(speed);
        else
            trackDat.Speed = single(NaN(size(trackDat.Centroid,1),1)); 
        end
    end

    if any(strcmp('Area',out_fields))
        area = NaN(size(trackDat.Centroid,1),1);
        if record
            area(update) = [props(permutation).Area];
        end
        trackDat.Area = single(area .* (expmt.parameters.mm_per_pix^2));
    end

    if any(strcmp('Orientation',out_fields))
        orientation = NaN(size(trackDat.Centroid,1),1);
        if record
            orientation(update) = [props(permutation).Orientation];
        end
        trackDat.Orientation = single(orientation);
    end
    
    if any(strcmp('PixelIdxList',out_fields))
        pxList = cell(size(trackDat.Centroid,1),1);
        if record
            pxList(update) = {props(permutation).PixelIdxList};
        end
        singletrackDat.PixelIdxList = (pxList);
    end

    if any(strcmp('Time',out_fields))
        trackDat.Time = single(trackDat.ifi);
    end

    if any(strcmp('VideoData',out_fields))
        trackDat.VideoData = trackDat.im;
    end

    if any(strcmp('VideoIndex',out_fields))
        trackDat.VideoIndex = trackDat.ct;
    end



    
    
function cen = estimateCen(bounds,diffimage)
        
b = round(bounds{:});
sim = diffimage(b(2):sum(b([2 4]))-1,b(1):sum(b([1 3]))-1);
cen(1) = sum( (sum(sim) ./ sum(sim(:))) .* (b(1):sum(b([1 3]))-1) );
cen(2) = sum( (sum(sim,2) ./ sum(sim(:))) .* (b(2):sum(b([2 4]))-1)' );




            