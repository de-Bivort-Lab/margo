function [expmt] = initializeRef(gui_handles,expmt)


clearvars -except gui_handles expmt
gui_notify('initializing reference',gui_handles.disp_note);
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','image');   % image handle

if isempty(imh)
    % Take single frame
    switch expmt.meta.source
        case 'camera'
            trackDat.im = peekdata(expmt.hardware.cam.vid,1);
        case 'video'
            [trackDat.im, expmt.meta.video] = nextFrame(expmt.meta.video,gui_handles);
    end
    imh = imagesc(trackDat.im);
elseif strcmp(imh.CDataMapping,'direct')
    imh.CDataMapping = 'scaled';
end

% enable display adjustment and set set the view to thresholded by default
colormap('gray');
set_display_mode(gui_handles.display_menu,'reference');
gui_handles.accept_track_thresh_pushbutton.Value = 0;

%% Setup the camera and/or video object

expmt = getVideoInput(expmt,gui_handles);

%% Assign parameters and placeholders

% intialize trackDat frame to frame tracking data
expmt.meta.ref = struct;
trackDat = initializeTrackDat(expmt);
trackDat.fields={'centroid';'area';'majorAxisLength'};
if isfield(trackDat,'px_dist')
    trackDat = rmfield(trackDat,'px_dist');
end

blob_lengths = NaN(100,1);
if expmt.parameters.area_min == 5 && expmt.parameters.area_max == 100
    expmt.parameters.area_max = 600;
    areas = cell(10,1);
end

% Set maximum allowable distance to center of ROI as the long axis of the ROI
if expmt.parameters.distance_thresh == 20
    widths=(expmt.meta.roi.bounds(:,3));
    heights=(expmt.meta.roi.bounds(:,4));
    w=median(widths);
    h=median(heights);
    expmt.parameters.distance_thresh = ...
        round(sqrt(w^2+h^2)/2*0.9*10)/10 * expmt.parameters.mm_per_pix;
    gui_handles.edit_dist_thresh.String = ...
        num2str(expmt.parameters.distance_thresh);
end

% set min distance from previous ref locations before acquiring new ref for any given object
trackDat.ref.thresh = expmt.parameters.distance_thresh * 0.5;  

% Initialize reference with single image
[trackDat,expmt] = autoFrame(trackDat,expmt,gui_handles);
trackDat.ref.im = trackDat.im;
trackDat.ref.freq = expmt.parameters.ref_freq;
tmp_ref = trackDat.ref.im;
depth = expmt.parameters.ref_depth;
nROIs = expmt.meta.roi.n;
trackDat.ref.stack = squeeze(num2cell(repmat(trackDat.ref.im,1,1,depth),[1 2]));
pause(0.1);

% initialize variables for ref bg_mode auto detection           
dDifference = NaN(35,2);
diffStack = cell(2,1);
diffStack(:) = {uint8(zeros(size(trackDat.im,1),...
                    size(trackDat.ref.im,2),2))};
                
% acquire reference from video file if possible
if strcmpi(expmt.meta.source,'video') && ...
        isfield(expmt.parameters,'ref_mode') && ...
        strcmpi(expmt.parameters.ref_mode,'video')
        
        gui_notify('computing background reference from video',...
            gui_handles.disp_note);
        msg = 'Computing background reference from video file';
        ax = gui_handles.axes_handle;
        mh = gui_axes_notify(ax,msg,'color','r','FontSize',14);
        drawnow
        [trackDat.ref.im, trackDat.ref.stack, expmt.meta.video.vid] = ...
            makeVidReference(expmt.meta.video.vid...
            , 'median', expmt.parameters.ref_depth);
        cellfun(@(h) delete(h),mh); 
        expmt.meta.ref = trackDat.ref;
        return;
end


%% initialize display objects

clean_gui(gui_handles.axes_handle);
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','Image');
set(gca,'Xtick',[],'Ytick',[]);     % turn off tick marks
clearvars hCirc hText

hold(gui_handles.axes_handle,'on');
trackDat.hMark = plot(trackDat.centroid(:,1),trackDat.centroid(:,2),'ro');
hold(gui_handles.axes_handle,'off');


%% Collect reference until timeout OR "accept reference" GUI press

% Time stamp placeholders
trackDat.t = 0;
tic
trackDat.tPrev=toc;

while trackDat.t < expmt.parameters.duration*3600 &&...
        ~gui_handles.accept_track_thresh_pushbutton.Value
    trackDat.ref.freq = 30;
    
    % update time stamps and frame rate
    [trackDat] = autoTime(trackDat, expmt, gui_handles);

    % query next frame and optionally correct lens distortion
    [trackDat,expmt] = autoFrame(trackDat,expmt,gui_handles);
    
    if trackDat.ct == 0
        diffim = (trackDat.ref.im - expmt.meta.vignette.im) -...
                    (trackDat.im - expmt.meta.vignette.im);
        
        if expmt.parameters.bg_adjust
            diffim_upper_bound = double(max(diffim(:)));
            diffim_upper_bound(diffim_upper_bound==0) = 255;
            diffim = imadjust(diffim, [0 diffim_upper_bound/255], [0 1]);
        end
        tmp_thresh = floor(graythresh(diffim)*255);
        
        if tmp_thresh > 4
            gui_handles.track_thresh_slider.Value = tmp_thresh;
            feval(gui_handles.track_thresh_slider.Callback,...
                gui_handles.track_thresh_slider,[]);
        end
    end

    % track objects and sort to ROIs
    trackDat = autoTrack(trackDat,expmt,gui_handles);
    
    
    % update area distribution
    if exist('areas','var') && trackDat.ct < numel(areas)  
        areas{trackDat.ct} = trackDat.area;
    elseif exist('areas','var') && trackDat.ct == numel(areas) 
        areas{trackDat.ct} = trackDat.area;
        areas = cat(1,areas{:});
        areas = areas(~isnan(areas));
        areas = sort(areas);
        area_cdf = cumsum(areas)./sum(areas);
        [~,lb] = min(abs(area_cdf-0.02));
        [~,ub] = min(abs(area_cdf-0.98));
        expmt.meta.parameters.area_min = areas(lb);
        expmt.meta.parameters.area_max = areas(ub);
        gui_handles.edit_area_minimum.String = num2str(areas(lb));
        gui_handles.edit_area_maximum.String = num2str(areas(ub));
        gui_notify(sprintf('min blob area = %i,  max blob area = %i',...
            areas(lb),areas(ub)), gui_handles.disp_note);
        clear areas
    end
        
    % update blob length distribution
    if any(isnan(blob_lengths)) && any(~isnan(trackDat.majorAxisLength))
        n_remain = sum(isnan(blob_lengths));
        n_available = sum(~isnan(trackDat.majorAxisLength));
        if n_available <= n_remain
            idx = numel(blob_lengths)-n_remain+1;
            blob_lengths(idx:idx+n_available-1) =...
                trackDat.majorAxisLength(~isnan(trackDat.majorAxisLength));
        else
            idx = numel(blob_lengths)-n_remain+1;
            blob_lengths(idx:end) =...
                trackDat.majorAxisLength(...
                find(~isnan(trackDat.majorAxisLength),n_remain));
        end
        if ~any(isnan(blob_lengths))          
           tmp_thresh = (mean(blob_lengths) + std(blob_lengths)*3)*0.6;
           if tmp_thresh < trackDat.ref.thresh
                trackDat.ref.thresh = tmp_thresh;
           end
           trackDat.fields(strcmp(trackDat.fields,'majorAxisLength'))=[];
        end
    end

    % update ref at the reference frequency
    trackDat.px_dev = 0;
    [trackDat, expmt] = autoReference(trackDat, expmt, gui_handles);   
  
    % update the display
    [trackDat, expmt] = autoDisplay(trackDat, expmt, imh, gui_handles);   

    if trackDat.ct <= size(dDifference,1) && expmt.parameters.bg_auto
        % compute frame to frame change in the magnitude of the difference of
        % the difference image with bg_mode = 'light' and bg_mode = 'dark'
        trackDat.im(~expmt.meta.roi.mask) = 0;
        tmp_ref(~expmt.meta.roi.mask) = 0;
        diffStack{1}(:,:,mod(trackDat.ct-1,2)+1) = tmp_ref - trackDat.im;
        diffStack{2}(:,:,mod(trackDat.ct-1,2)+1) = trackDat.im - tmp_ref;
        tmp_dDif = cellfun(@(x) ...
            abs(diff(single(x),1,3)), diffStack,'UniformOutput',false);
        dDifference(mod(trackDat.ct-1,size(dDifference,1))+1,:) = ...
            cellfun(@(x) sum(x(:)),tmp_dDif);
    
        % select appropriate reference mode
        if ~any(isnan(dDifference(:)))
           
            avg_deltaDiff = nanFilteredMean(dDifference);
            if avg_deltaDiff(1) > avg_deltaDiff(2)
                trackDat.ref.bg_mode = 'light';
                expmt.parameters.bg_mode = 'light';
                expmt.parameters.bg_auto = false;
                gui_notify('detected dark objects on light background',...
                    gui_handles.disp_note);
            else
                trackDat.ref.bg_mode = 'dark';
                gui_notify('detected light objects on dark background',...
                    gui_handles.disp_note);
                expmt.parameters.bg_mode = 'dark';
                expmt.parameters.bg_auto = false;
            end
            
        end
    end
    
    drawnow limitrate
    
end



%% Reset UI properties
trackDat.t = 0;
tic
trackDat.tPrev = toc;
autoTime(trackDat, expmt, gui_handles);

if expmt.parameters.estimate_trace_num
    
    expmt.meta.roi.num_traces = ...
        arrayfun(@(t) sum(~isnan(t.t)), trackDat.traces);
    trackDat.ref.cen = ...
        cellfun(@(refc,nt) refc(1:nt,:,:), ...
            trackDat.ref.cen, num2cell(expmt.meta.roi.num_traces),...
            'UniformOutput', false);
end
expmt.meta.ref = trackDat.ref;

switch expmt.meta.vignette.mode
    case 'auto'
        expmt.meta.vignette.im = filterVignetting(expmt);
end

% delete reference number indicators
if isfield(trackDat,'hRefCirc')
    delete(trackDat.hRefCirc);
    trackDat = rmfield(trackDat,'hRefCirc');
end

% send gui message
gui_notify('reference initialization complete',gui_handles.disp_note);

% Reset accept reference button
set(gui_handles.accept_track_thresh_pushbutton,'value',0);

