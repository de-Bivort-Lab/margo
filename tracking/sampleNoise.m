function [expmt] = sampleNoise(gui_handles, expmt)
% 
% Samples the background noise distribution prior to imaging for the
% purpose of determining when to force reset background reference images.
% For the sampling to accurate, it is important for the tracking during the
% sampling period to be clean (ie. majority of the tracked objects appear
% above the imaging threshold with few above-threshold pixels due to
% noise).

gui_notify('sampling imaging noise',gui_handles.disp_note);

gui_fig = gui_handles.gui_fig;
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','image');   % image handle

colormap('gray');
set(gui_handles.display_menu.Children,'Enable','on');
set(gui_handles.display_menu.Children,'Checked','off');
set(gui_handles.display_threshold_menu,'Checked','on');
gui_handles.display_menu.UserData = 3;


%% Sampling Parameters

pixDistSize=100;                    % Num values to record in p
pixelDist=NaN(pixDistSize,1);       % Distribution of total number of pixels above image threshold

% tracking vars
trackDat.Centroid = expmt.ROI.centers;     % placeholder for most recent non-NaN centroids
trackDat.fields = {'Centroid';'Area'};     % Define fields for regionprops
trackDat.tStamp = zeros(size(expmt.ROI.centers(:,1),1),1);
trackDat.t = 0;
trackDat.ct = 0;

%% Initalize camera and axes

expmt = getVideoInput(expmt,gui_handles);

%% Sample noise

% initialize display objects
clean_gui(gui_handles.axes_handle);
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','Image');
set(gca,'Xtick',[],'Ytick',[]);
clearvars hCirc
hold on
hCirc = plot(expmt.ROI.centers(:,1),expmt.ROI.centers(:,2),'o','Color',[1 0 0]);
hold off

tic
tPrev = toc;

while trackDat.ct < pixDistSize;

    % update time stamps and frame rate
    [trackDat, tPrev] = updateTime(trackDat, tPrev, expmt, gui_handles,1);
    gui_handles.edit_time_remaining.String = num2str(pixDistSize - trackDat.ct);

    % query next frame and optionally correct lens distortion
    [trackDat,expmt] = autoFrame(trackDat,expmt,gui_handles);

    % track objects and sort to ROIs
    [trackDat] = autoTrack(trackDat,expmt,gui_handles);

    %Update display if display tracking is ON
    if gui_handles.display_menu.UserData ~= 5

        % update the display
        updateDisplay(trackDat, expmt, imh, gui_handles);

       % Draw last known centroid for each ROI and update ref. number indicator
       hCirc.XData = trackDat.Centroid(:,1);
       hCirc.YData = trackDat.Centroid(:,2);

    end
    drawnow limitrate


   % Create distribution for num pixels above imageThresh
   % Image statistics used later during acquisition to detect noise
   diffim = (expmt.ref - expmt.vignette.im) - (trackDat.im - expmt.vignette.im);
   pixelDist(mod(trackDat.ct,pixDistSize)+1) = nansum(nansum(diffim > gui_handles.track_thresh_slider.Value));
   
end

trackDat.t = 0;
tic
tPrev = toc;
[trackDat, tPrev] = updateTime(trackDat, tPrev, expmt, gui_handles);

gui_notify('noise sampling complete',gui_handles.disp_note);

% Record stdDev and mean without noise
pixStd=nanstd(pixelDist);
pixMean=nanmean(pixelDist);    

% Assign outputs
expmt.noise.dist = pixelDist;
expmt.noise.std = nanstd(pixelDist);
expmt.noise.mean = nanmean(pixelDist);

