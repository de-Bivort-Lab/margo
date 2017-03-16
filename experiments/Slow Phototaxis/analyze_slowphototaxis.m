function expmt = analyze_basictracking(expmt,varargin)
%
% This function provides a sample analysis function to run after the
% sample bare-bones template 'experimental_template.m'. It takes the
% experimental master data struct (expmt) as an input, processes the data
% to extract features and store them to file. This sample also shows how to
% automatically zip the raw data files after analysis to reduce file size.

%% parse inputs

for i = 1:length(varargin)
    if ischar(varargin{i})
        plot_mode = varargin{i};
    else
        handles = varargin{i};
    end
end

%% Pull in ASCII data, format into vectors/matrices

if exist('handles','var')
    gui_notify('importing and processing data...',handles.disp_note)
end

expmt.nTracks = size(expmt.ROI.centers,1);

% read in data files sequentially and store in data struct
for i = 1:length(expmt.fields)
    
    % get subfields
    f = expmt.fields{i};
    path = expmt.(f).path;
    dim = expmt.(f).dim;
    prcn = expmt.(f).precision;
    
    % read .bin file
    expmt.(f).fID = fopen(path,'r');

    
    % if field is centroid, reshape to (frames x dim x nTracks)
    if strcmp(f,'Centroid')
        expmt.(f).data = fread(expmt.(f).fID,prcn);
        expmt.(f).data = reshape(expmt.(f).data,dim(1),dim(2),expmt.nFrames);
        expmt.(f).data = permute(expmt.(f).data,[3 2 1]);
        expmt.drop_ct = expmt.drop_ct ./ expmt.nFrames;
    
    % if area, orientation, or speed, reshape to (frames x nTracks)
    elseif any(strmatch(f,{'Area' 'Orientation' 'Speed'}))
        expmt.(f).data = fread(expmt.(f).fID,prcn);
        expmt.(f).data = reshape(expmt.(f).data,expmt.nTracks,length(expmt.(f).data)/(prod(dim)))';
    
    elseif strcmp(f,'Time')
        expmt.(f).data = fread(expmt.(f).fID,prcn);
        
    elseif ~strcmp(f,'VideoData') || ~strcmp(f,'VideoIndex')
        expmt.(f).data = fread(expmt.(f).fID,[expmt.(f).dim(1) expmt.nFrames],prcn);
        
    end
    
    fclose(expmt.(f).fID);
    
end

% In the example, the centroid is being processed to extract circling
% handedness for each track. Resulting handedness scores are stored in
% the master data struct.
[expmt,trackProps] = processCentroid(expmt);

if exist('handles','var')
    gui_notify('processing complete',handles.disp_note)
end

clearvars -except handles expmt trackProps varargin

%% Analyze stimulus response

% reshape date so that each col is a trace
expmt.Texture.data = expmt.Texture.data';
expmt.StimAngle.data = expmt.StimAngle.data';

% Convert centroid data to projector space
x=squeeze(expmt.Centroid.data(:,1,:));
y=squeeze(expmt.Centroid.data(:,2,:));
proj_x = expmt.projector.Fx(x,y);
proj_y = expmt.projector.Fy(x,y);
[div_dist,lightStat] = ...
    parseShadeLight(expmt.StimAngle.data, proj_x, proj_y, expmt.stim.centers, 0);

% Calculate mean distance to divider for each fly
avg_d = mean(div_dist);

% Initialize light occupancy variables
light_occupancy = NaN(expmt.nTracks,1);
light_occupancy_time = NaN(expmt.nTracks,1);
light_total_time = NaN(expmt.nTracks,1);

% Initialize blank stimulus occupancy variables
blank_occupancy = NaN(expmt.nTracks,1);
blank_occupancy_time = NaN(expmt.nTracks,1);
blank_total_time = NaN(expmt.nTracks,1);

% Calculate occupancy for each fly in both blank and photo_stim conditions
for i=1:expmt.nTracks
    
    % When one half of the arena is lit
    off_divider = abs(div_dist(:,i))>3;                         % data mask for trials where fly is clearly in one half or the other
    tmp_tStamps = expmt.Time.data(off_divider & expmt.Texture.data);               % ifi for included frames
    tmp_lightStat = lightStat(off_divider & expmt.Texture.data,i);                   % light status for included frames
    light_occupancy_time(i) = sum(tmp_tStamps(tmp_lightStat));        % total time in the light
    light_total_time(i) = sum(tmp_tStamps);
    light_occupancy(i) = sum(tmp_tStamps(tmp_lightStat))/light_total_time(i);    % fractional time in light
    
    % When both halfs of the arena are unlit
    tmp_tStamps = expmt.Time.data(off_divider & ~expmt.Texture.data);               % ifi for included frames
    tmp_lightStat = lightStat(off_divider & ~expmt.Texture.data,i);                   % light status for included frames
    blank_occupancy_time(i) = sum(tmp_tStamps(tmp_lightStat));        % total time in the fake lit half
    blank_total_time(i) = sum(tmp_tStamps);
    blank_occupancy(i) = sum(tmp_tStamps(tmp_lightStat))/blank_total_time(i);    % fractional time in fake lit half
    
end

% Convert occupancy time from seconds to hours
light_occupancy_time = light_occupancy_time./3600;
light_total_time = light_total_time./3600;
blank_occupancy_time = blank_occupancy_time./3600;
blank_total_time = blank_total_time./3600;

%% Generate plots

min_active_period = 0.4;        % Minimum time spent off the boundary divider (hours)
active = nanmean(trackProps.speed)' > 0.1;
%active = boolean(ones(size(flyTracks.speed)));

% Histogram for stimulus ON period
figure();
bins = 0:0.05:1;
c=histc(light_occupancy(light_total_time>min_active_period&active),bins)./sum(light_total_time>min_active_period&active);
c(end)=[];
plot(c,'Color',[1 0 1],'Linewidth',2);
set(gca,'Xtick',0:2:length(c),'XtickLabel',0:0.1:1);
axis([0 length(c) 0 max(c)+0.05]);
n_light=sum(light_total_time>min_active_period&active);

% Histogram for blank stimulus with fake lit half
bins = 0:0.05:1;
c=histc(blank_occupancy(blank_total_time>min_active_period&active),bins)./sum(blank_total_time>min_active_period&active);
c(end)=[];
hold on
plot(c,'Color',[0 0 1],'Linewidth',2);
set(gca,'Xtick',0:2:length(c),'XtickLabel',0:0.1:1);
axis([0 length(c) 0 max(c)+0.05]);
title('Light Occupancy Histogram');
n_blank=sum(blank_total_time>min_active_period&active);
hold off

% Generate legend labels
if iscellstr(expmt.labels{1,1})
    strain=expmt.labels{1,1}{:};
end
if iscellstr(expmt.labels{1,3})
    treatment=expmt.labels{1,3}{:};
end

% light ON label
light_avg_occ = round(mean(light_occupancy(light_total_time>min_active_period&active))*100)/100;
light_mad_occ = round(mad(light_occupancy(light_total_time>min_active_period&active))*100)/100;
n = sum(light_total_time>min_active_period&active);
legendLabel(1)={['Stim ON: ' strain ' ' treatment ' (u=' num2str(light_avg_occ)...
    ', MAD=' num2str(light_mad_occ) ', n=' num2str(n) ')']};
% light OFF label
blank_avg_occ = round(mean(blank_occupancy(blank_total_time>min_active_period&active))*100)/100;
blank_mad_occ = round(mad(blank_occupancy(blank_total_time>min_active_period&active))*100)/100;
n = sum(blank_total_time>min_active_period&active);
legendLabel(2)={['Stim OFF: ' strain ' ' treatment ' (u=' num2str(blank_avg_occ)...
    ', MAD=' num2str(blank_mad_occ) ', n=' num2str(n) ')']};
legend(legendLabel);
shg

% Save data to struct
expmt.Photo.Occ = light_occupancy;
expmt.Photo.tOcc = light_occupancy_time;
expmt.Photo.tTotal = light_total_time;
expmt.Photo.mean = light_avg_occ;
expmt.Photo.mad = light_mad_occ;
expmt.Dark.Occ = blank_occupancy;
expmt.Dark.tOcc = blank_occupancy_time;
expmt.Dark.tTotal = blank_total_time;
expmt.Dark.mean = blank_avg_occ;
expmt.Dark.mad = blank_mad_occ;

%% Generate plots

if exist('plot_mode','var') && strcmp(plot_mode,'plot')
    if exist('handles','var')
        gui_notify('generating plots',handles.disp_note)
    end
    plotArenaTraces(expmt);
end

clearvars -except handles expmt plot_mode varargin

%% Clean up files and wrap up analysis

autoFinishAnalysis(expmt,varargin);