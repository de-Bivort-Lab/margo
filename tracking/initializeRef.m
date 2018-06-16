function [expmt] = initializeRef(gui_handles,expmt)


clearvars -except gui_handles expmt

gui_notify('initializing reference',gui_handles.disp_note);

gui_fig = gui_handles.gui_fig;
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','image');   % image handle

if isempty(imh)
    % Take single frame
    switch expmt.source
        case 'camera'
            trackDat.im = peekdata(expmt.camInfo.vid,1);
        case 'video'
            [trackDat.im, expmt.video] = nextFrame(expmt.video,gui_handles);
    end
    imh = imagesc(trackDat.im);
elseif strcmp(imh.CDataMapping,'direct')
    imh.CDataMapping = 'scaled';
end

% enable display adjustment and set set the view to thresholded by default
colormap('gray');
set(gui_handles.display_menu.Children,'Enable','on');
set(gui_handles.display_menu.Children,'Checked','off');
set(gui_handles.display_threshold_menu,'Checked','on');
gui_handles.display_menu.UserData = 3;

gui_handles.accept_track_thresh_pushbutton.Value = 0;

%% Setup the camera and/or video object

expmt = getVideoInput(expmt,gui_handles);

%% Assign parameters and placeholders

% Reference vars
nROIs = size(expmt.ROI.corners, 1);             % total number of ROIs
depth = gui_handles.edit_ref_depth.Value;       % number of rolling sub references
trackDat.ref.cen = NaN(nROIs,2,depth);          % placeholder for cen. coords where references are taken
trackDat.ref.ct = zeros(nROIs, 1);              % Reference number placeholder
trackDat.ref.t = 0;                             % reference time stamp
trackDat.ref.last_update = zeros(nROIs,1);
trackDat.ref.bg_mode = 'light';                 % set reference mode to dark
                                                % obj on light background


% tracking vars
trackDat.fields={'Centroid';'Area';'MajorAxisLength'};  % Define fields for regionprops
trackDat.Centroid=expmt.ROI.centers;                   	% placeholder for most recent non-NaN centroids
trackDat.tStamp=zeros(nROIs,1);
trackDat.ct = 0;
blob_lengths = NaN(100,1);


% Set maximum allowable distance to center of ROI as the long axis of the ROI
if gui_fig.UserData.distance_thresh == 20
    widths=(expmt.ROI.bounds(:,3));
    heights=(expmt.ROI.bounds(:,4));
    w=median(widths);
    h=median(heights);
    gui_fig.UserData.distance_thresh=round(sqrt(w^2+h^2)/2*0.9*10)/10 * expmt.parameters.mm_per_pix;
    gui_handles.edit_dist_thresh.String = num2str(gui_fig.UserData.distance_thresh);
end

% set min distance from previous ref locations before acquiring new ref for any given object
trackDat.ref.thresh = gui_fig.UserData.distance_thresh * 0.2;  

% Initialize reference with single image
[trackDat,expmt] = autoFrame(trackDat,expmt,gui_handles);
trackDat.ref.im = trackDat.im;
trackDat.ref.stack = squeeze(num2cell(repmat(trackDat.ref.im,1,1,depth),[1 2]));
pause(0.1);

% initialize variables for ref bg_mode auto detection           
dDifference = NaN(35,2);
diffStack = cell(2,1);
diffStack(:) = {uint8(zeros(size(trackDat.im,1),...
                    size(trackDat.ref.im,2),2))};


%% initialize display objects

clean_gui(gui_handles.axes_handle);
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','Image');
set(gca,'Xtick',[],'Ytick',[]);     % turn off tick marks
clearvars hCirc hText

% Initialize color variables
hsv_base = 360;                         % hsv red
hsv_targ = 240;                         % hsv blue
color_scale = 1 - hsv_targ/hsv_base;

% initialize 
hold on
color = zeros(nROIs,3);
color(:,1) = 1;
hCirc = scatter(expmt.ROI.corners(:,1),expmt.ROI.corners(:,2),...
    'o','filled','LineWidth',2);
hCirc.CData = color;

hold off


%% Collect reference until timeout OR "accept reference" GUI press

% Time stamp placeholders
trackDat.t = 0;
tic
trackDat.tPrev=toc;

old_ref_freq = gui_handles.edit_ref_freq.Value;
gui_handles.edit_ref_freq.Value = 1/120;

while trackDat.t < expmt.parameters.duration*3600 &&...
        ~gui_handles.accept_track_thresh_pushbutton.Value
    
    % update time stamps and frame rate
    [trackDat] = autoTime(trackDat, expmt, gui_handles);

    % query next frame and optionally correct lens distortion
    [trackDat,expmt] = autoFrame(trackDat,expmt,gui_handles);
    
    if trackDat.ct == 0
        diffim = (trackDat.ref.im - expmt.vignette.im) -...
                    (trackDat.im - expmt.vignette.im);
        tmp_thresh = floor(graythresh(diffim)*255);
        
        if tmp_thresh > 4
            gui_handles.track_thresh_slider.Value = tmp_thresh;
            feval(gui_handles.track_thresh_slider.Callback,...
                gui_handles.track_thresh_slider,[]);
        end
    end

    % track objects and sort to ROIs
    [trackDat] = autoTrack(trackDat,expmt,gui_handles);
    
    % update blob length distribution
    if any(isnan(blob_lengths)) && any(~isnan(trackDat.MajorAxisLength))
        n_remain = sum(isnan(blob_lengths));
        n_available = sum(~isnan(trackDat.MajorAxisLength));
        if n_available <= n_remain
            idx = numel(blob_lengths)-n_remain+1;
            blob_lengths(idx:idx+n_available-1) =...
                trackDat.MajorAxisLength(~isnan(trackDat.MajorAxisLength));
        else
            idx = numel(blob_lengths)-n_remain+1;
            blob_lengths(idx:end) =...
                trackDat.MajorAxisLength(...
                find(~isnan(trackDat.MajorAxisLength),n_remain));
        end
        if ~any(isnan(blob_lengths))          
           tmp_thresh = (mean(blob_lengths) + std(blob_lengths)*3)*0.6;
           if tmp_thresh < trackDat.ref.thresh
                trackDat.ref.thresh = tmp_thresh;
           end
           trackDat.fields(strcmp(trackDat.fields,'MajorAxisLength'))=[];
        end
    end

    % update ref at the reference frequency
    trackDat.px_dev = 0;
    [trackDat, expmt] = autoReference(trackDat, expmt, gui_handles);   

    % Update display
    if gui_handles.display_menu.UserData ~= 5
        
        % update the display
        autoDisplay(trackDat, expmt, imh, gui_handles);
                
        nRefs = trackDat.ref.ct;

        % Update color indicator
        hue = 1-color_scale.*nRefs./depth;
        hsv_color = ones(numel(hue),3);
        hsv_color(:,1) = hue;
        color = hsv2rgb(hsv_color); 

        % Draw last known centroid for each ROI and update ref. number indicator
        hCirc.CData = color;

       
    end

    if trackDat.ct <= size(dDifference,1)
        % compute frame to frame change in the magnitude of the difference of
        % the difference image with bg_mode = 'light' and bg_mode = 'dark'
        diffStack{1}(:,:,mod(trackDat.ct-1,2)+1) = trackDat.ref.im - trackDat.im;
        diffStack{2}(:,:,mod(trackDat.ct-1,2)+1) = trackDat.im - trackDat.ref.im;
        tmp_dDif = cellfun(@(x) ...
            abs(diff(single(x),1,3)), diffStack,'UniformOutput',false);
        dDifference(mod(trackDat.ct-1,size(dDifference,1))+1,:) = ...
            cellfun(@(x) sum(x(:)),tmp_dDif);
    
        % select appropriate reference mode
        if ~any(isnan(dDifference(:)))
           
            avg_deltaDiff = nanmean(dDifference);
            if avg_deltaDiff(1) > avg_deltaDiff(2)
                trackDat.ref.bg_mode = 'light';
                gui_notify('detected dark objects on light background',...
                    gui_handles.disp_note);
            else
                trackDat.ref.bg_mode = 'dark';
                gui_notify('detected light objects on dark background',...
                    gui_handles.disp_note);
            end
            
        end
    end
    
    drawnow limitrate
    
end

gui_handles.edit_ref_freq.Value = old_ref_freq;

%% Reset UI properties
trackDat.t = 0;
tic
trackDat.tPrev = toc;
autoTime(trackDat, expmt, gui_handles);
expmt.ref = trackDat.ref;

% Reset accept reference button
set(gui_handles.accept_track_thresh_pushbutton,'value',0);

% disable display control
set(gui_handles.display_menu.Children,'Enable','off');
set(gui_handles.display_menu.Children,'Checked','off');
gui_handles.display_raw_menu.Checked = 'on';
gui_handles.display_menu.UserData = 1;

% Set time to zero
if strcmp(expmt.source,'camera')
    updateTimeString(0, gui_handles.edit_time_remaining);
end
