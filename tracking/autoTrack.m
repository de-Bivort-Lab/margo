function [varargout] = autoTrack(trackDat,expmt,gui_handles)

    trackDat.ct = trackDat.ct + 1;

    % calculate difference image and current for vignetting
    diffim = (expmt.ref - expmt.vignetteMat) - (trackDat.im - expmt.vignetteMat);
    
    % get current image threshold and use it to extract region properties     
    im_thresh = get(gui_handles.track_thresh_slider,'value');
    
    % add centroid and area to the input regionprops fields if not provided
    out_fields = trackDat.fields;
    in_fields = trackDat.fields;
    if ~any(strmatch('Centroid',in_fields))
        in_fields = [in_fields; {'Centroid'}];
    end

    if ~any(strmatch('Area',in_fields))
        in_fields = [in_fields; {'Area'}];
    end
    
    if any(strmatch('Speed',in_fields))
        in_fields(strmatch('Speed',in_fields)) = [];
    end
    
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
        target_area =([props.Area] > gui_handles.gui_fig.UserData.area_min & [props.Area] < gui_handles.gui_fig.UserData.area_max);
        props(~target_area) = [];

        cenDat = reshape([props.Centroid],2,length([props.Centroid])/2)';

        % Match centroids to last known centroid positions
        [permutation,update] = ...
            matchCentroids2ROIs(cenDat,trackDat.lastCen,expmt.ROI.centers,gui_handles.gui_fig.UserData.distance_thresh);


        % Apply speed threshold to centroid tracking
        speed = NaN(size(update));

        if any(update)
            
            % calculate distance
            d = sqrt((cenDat(permutation,1)-trackDat.lastCen(update,1)).^2 ...
                     + (cenDat(permutation,2)-trackDat.lastCen(update,2)).^2);
            
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
        trackDat.lastCen(update,:) = cenDat(permutation,:);
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

    % assign any optional sorted output fields, return NaNs if record = false
    if ~isempty(out_fields)

        if any(strmatch('Speed',out_fields));
            if record
                sorted.Speed = speed;
            else
                sorted.Speed = NaN(size(trackDat.lastCen,1),1); 
            end
        end

        if any(strmatch('Area',out_fields));
            area = NaN(size(trackDat.lastCen,1),1);
            if record
                area(update) = [props(permutation).Area];
            end
            sorted.Area = area;
        end
        if any(strmatch('Orientation',out_fields));
            orientation = NaN(size(trackDat.lastCen,1),1);
            if record
                orientation(update) = [props(permutation).Orientation];
            end
            sorted.Orientation = orientation;
        end

    end

        
    % assign outputs
    for i = 1:nargout
        switch i
            case 1
                varargout{i} = trackDat;
            case 2
                varargout{i} = sorted;
        end
    end
            