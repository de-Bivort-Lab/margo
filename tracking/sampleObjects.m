function [expmt] = sampleObjects(gui_handles, expmt)
% 
% Samples the background noise distribution prior to imaging for the
% purpose of determining when to force reset background reference images.
% For the sampling to accurate, it is important for the tracking during the
% sampling period to be clean (ie. majority of the tracked objects appear
% above the imaging threshold with few above-threshold pixels due to
% noise).

gui_notify('sampling imaging noise',gui_handles.disp_note);

colormap('gray');
set(gui_handles.display_menu.Children,'Enable','on');
set(gui_handles.display_menu.Children,'Checked','off');
set(gui_handles.display_threshold_menu,'Checked','on');
gui_handles.display_menu.UserData = 3;


%% Sampling Parameters

n = 50000;
sample_window = ceil(expmt.meta.ref.thresh);
sample_obj = cell(n,1);
sample_bg = cell(n,1);
sample_ct = 0;

% tracking vars
trackDat.centroid = expmt.meta.roi.centers;     % placeholder for most recent non-NaN centroids
trackDat.fields = {'centroid';'area'};     % Define fields for regionprops
trackDat.tStamp = zeros(size(expmt.meta.roi.centers(:,1),1),1);
trackDat.t = 0;
trackDat.ct = 0;
trackDat.ref = expmt.meta.ref;

%% Initalize camera and axes

expmt = getVideoInput(expmt,gui_handles);

%% Sample noise

% initialize display objects
clean_gui(gui_handles.axes_handle);
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','Image');
set(gca,'Xtick',[],'Ytick',[]);
clearvars hCirc
hold on
hCirc = plot(expmt.meta.roi.centers(:,1),expmt.meta.roi.centers(:,2),'o','Color',[1 0 0]);
hold off

tic
trackDat.tPrev = toc;
old_rate = expmt.parameters.target_rate;
expmt.parameters.target_rate = 100;

while sample_ct < n

    % update time stamps and frame rate
    trackDat = autoTime(trackDat, expmt, gui_handles,1);
    gui_handles.edit_time_remaining.String = num2str(n - sample_ct);

    % query next frame and optionally correct lens distortion
    [trackDat,expmt] = autoFrame(trackDat,expmt,gui_handles);

    % track objects and sort to ROIs
    [trackDat] = autoTrack(trackDat,expmt,gui_handles);
    
    if ~exist('area_thresh','var') || isnan(area_thresh)
        area_thresh = nanFilteredMedian(trackDat.area);
    end
    
    % identify objects with good separation from background
    extract = trackDat.area > area_thresh;
    if any(extract)
        [obj_ims, bg_ims] = ...
            extractSamples(trackDat, expmt, extract, sample_window);
        
        if numel(obj_ims) + sample_ct > n
            range = 1:n-sample_ct;
        else
            range = 1:numel(obj_ims);
        end
        sample_obj(sample_ct + range) = obj_ims(range);
        sample_bg(sample_ct + range) = bg_ims(range);
        sample_ct = sample_ct + range(end);
        
        sprintf('sample count:\t %i \t of \t %i\n',sample_ct,n)
        
    end
    

    %Update display if display tracking is ON
    if gui_handles.display_menu.UserData ~= 5

        % update the display
        autoDisplay(trackDat, expmt, imh, gui_handles);

       % Draw last known centroid for each ROI and update ref. number indicator
       hCirc.XData = trackDat.centroid(:,1);
       hCirc.YData = trackDat.centroid(:,2);

    end
    drawnow limitrate


   % Create distribution for num pixels above imageThresh
   % Image statistics used later during acquisition to detect noise
   diffim = (trackDat.ref.im - expmt.meta.vignette.im) - ...
       (trackDat.im - expmt.meta.vignette.im);
   thresh_im = diffim(:) > gui_handles.track_thresh_slider.Value;
   
end

switch expmt.meta.source
    case 'video'
        gui_handles.edit_time_remaining.String = num2str(expmt.meta.video.nFrames);
    case 'camera'
        updateTimeString(round(gui_handles.edit_exp_duration.Value * 3600),...
                        gui_handles.edit_time_remaining);
end
drawnow limitrate
expmt.parameters.target_rate = old_rate;
gui_notify('noise sampling complete',gui_handles.disp_note);

% Assign outputs
expmt.meta.noise.dist = pixelDist;
expmt.meta.noise.std = nanFilteredStd(pixelDist);
expmt.meta.noise.mean = nanFilteredMean(pixelDist);
expmt.meta.noise.roi_dist = roiDist;
expmt.meta.noise.roi_std = nanFilteredStd(roiDist(roiDist>4));
expmt.meta.noise.roi_mean = nanFilteredMean(roiDist(roiDist>4));

