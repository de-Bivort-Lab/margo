function expmt = analyze_slowphototaxis(expmt,varargin)
%
% This function provides a sample analysis function to run after the
% sample bare-bones template 'experimental_template.m'. It takes the
% experimental master data struct (expmt) as an input, processes the data
% to extract features and store them to file. This sample also shows how to
% automatically zip the raw data files after analysis to reduce file size.

%% Parse inputs, read data from hard disk, format in master struct, process centroid data

[expmt,trackProps,meta] = autoDataProcess(expmt,varargin{:});

clearvars -except expmt trackProps meta

%% Analyze stimulus response

% reshape date so that each col is a trace
sz=size(expmt.Texture.data);
if sz(2) > sz(1)
    expmt.Texture.data = expmt.Texture.data';
end
sz=size(expmt.StimAngle.data);
if sz(2) > sz(1)
    expmt.StimAngle.data = expmt.StimAngle.data';
end

% Convert centroid data to projector space
x=squeeze(expmt.Centroid.data(:,1,:));
y=squeeze(expmt.Centroid.data(:,2,:));
proj_x = expmt.projector.Fx(x,y);
proj_y = expmt.projector.Fy(x,y);
clearvars x y
tic
[div_dist,in_Light] = ...
    parseShadeLight(expmt.StimAngle.data, proj_x, proj_y, expmt.stim.centers, 0);
toc

% Calculate mean distance to divider for each fly
avg_d = cellfun(@mean,div_dist);


% get stimulus transitions
stim_trans = diff([1;expmt.Texture.data]);
expmt.Light.blocks = find(stim_trans==1);
expmt.Light.nBlocks = length(expmt.Light.blocks);
expmt.Blank.blocks = find(stim_trans==-1);
expmt.Blank.nBlocks = length(expmt.Blank.blocks);

% get indices of stim endings
iOFF = expmt.Blank.blocks - 1;
iOFF = iOFF(iOFF>1);
if iOFF(end) < expmt.Light.blocks(end)
    iOFF = [iOFF;length(stim_trans)];
end
expmt.Light.blocks = [expmt.Light.blocks iOFF];
lb = num2cell(expmt.Light.blocks,2);

iOFF = expmt.Light.blocks(:,1) - 1;
iOFF = iOFF(iOFF>0);
if iOFF(end) < expmt.Blank.blocks(end)
    iOFF = [iOFF;length(stim_trans)];
end
expmt.Blank.blocks = [expmt.Blank.blocks iOFF];
bb = num2cell(expmt.Blank.blocks,2);


% get divider distance threshold for each ROI
div_thresh = (mean(expmt.ROI.bounds(:,[3 4]),2) .* expmt.parameters.divider_size * 0.5)';

% Initialize light occupancy variables
expmt.Light.include = cell(expmt.Light.nBlocks,expmt.nTracks);
expmt.Light.occ = cell(expmt.Light.nBlocks,expmt.nTracks);
expmt.Light.tOcc = cell(expmt.Light.nBlocks,expmt.nTracks);
expmt.Light.tInc = cell(expmt.Light.nBlocks,expmt.nTracks);
expmt.Light.tDiv = cell(expmt.Light.nBlocks,expmt.nTracks);

% Initialize blank stimulus occupancy variables
expmt.Blank.include = cell(expmt.Blank.nBlocks,expmt.nTracks);
expmt.Blank.occ = cell(expmt.Blank.nBlocks,expmt.nTracks);
expmt.Blank.tOcc = cell(expmt.Blank.nBlocks,expmt.nTracks);
expmt.Blank.tInc = cell(expmt.Blank.nBlocks,expmt.nTracks);
expmt.Blank.tDiv = cell(expmt.Blank.nBlocks,expmt.nTracks);


% Calculate occupancy for each fly in both blank and photo_stim conditions
for i=1:expmt.nTracks
    
    % When one half of the arena is lit
    off_divider = abs(div_dist{i})>div_thresh(i)*2;                       % data mask for trials where fly is clearly in one half or the other
    include = off_divider & expmt.Texture.data;
    [occ,tOcc,tInc,tDiv,inc] = arrayfun(@(k) parseBlocks(k,include,...  % extract occupancy for each stimulus block
        in_Light{i},expmt.Time.data), lb, 'UniformOutput',false);
    expmt.Light.include(:,i) = inc;                                     % light status for included frames
    expmt.Light.tOcc(:,i) = tOcc;                                       % total time in the light
    expmt.Light.tInc(:,i) = tInc;                                       % time of included frames
    expmt.Light.tDiv(:,i) = tDiv;                                       % time on stim divider
    expmt.Light.occ(:,i) = occ;                                         % fractional time in light of included frames
    clearvars occ tOcc tInc tDiv inc
    
    % When both halfs of the arena are unlit
    include = off_divider & ~expmt.Texture.data;
    [occ,tOcc,tInc,tDiv,inc] = arrayfun(@(k) parseBlocks(k,include,...  % extract occupancy for each stimulus block
        in_Light{i},expmt.Time.data), bb, 'UniformOutput',false);
    expmt.Blank.include(:,i) = inc;                                     % light status for included frames
    expmt.Blank.tOcc(:,i) = tOcc;                                       % total time in the light
    expmt.Blank.tInc(:,i) = tInc;
    expmt.Blank.tDiv(:,i) = tDiv;
    expmt.Blank.occ(:,i) = occ;  
    
end

%% Get centroid relative to stimulus

stimang = expmt.StimAngle.data;
stimang(stimang>180)=stimang(stimang>180)-360;
stimang = stimang * pi ./ 180;
cen_theta = trackProps.theta - stimang;
clearvars stimang

expmt.StimCen.data = NaN(size(expmt.Centroid.data));
expmt.StimCen.data(:,1,:) = trackProps.r .* cos(cen_theta);
expmt.StimCen.data(:,2,:) = trackProps.r .* sin(cen_theta);

%% Bootstrap data to measure overdispersion

nReps = 1000;
[expmt.Light.bs,f] = bootstrap_slowphototaxis(expmt,nReps,'Light');
fname = [expmt.figdir expmt.date '_light_bs'];
if ~isempty(expmt.figdir) && meta.save
    hgsave(f,fname);
    close(f);
end

if ~isfield(expmt.parameters,'blank_duration') || ...
        (isfield(expmt.parameters,'blank_duration') && expmt.parameters.blank_duration > 0)
    
    [expmt.Blank.bs,f] = bootstrap_slowphototaxis(expmt,nReps,'Blank');
    fname = [expmt.figdir expmt.date '_dark_bs'];
    if ~isempty(expmt.figdir) && meta.save
        hgsave(f,fname);
        close(f);
    end
    
end


%% Generate plots

% Minimum time spent off the boundary divider (hours)
min_active_period = 0.2 * nansum(expmt.Time.data(expmt.Texture.data))/3600;        
active = nanmean(trackProps.speed) > 0.1;
tTotal = nansum(cell2mat(expmt.Light.tInc));
btTotal = nansum(cell2mat(expmt.Blank.tInc));
locc = nanmean(cell2mat(expmt.Light.occ));
bocc = nanmean(cell2mat(expmt.Blank.occ));

% Histogram for stimulus ON period
f=figure();
bins = 0:0.05:1;
c=histc(locc(tTotal>min_active_period&active),bins)./sum(tTotal>min_active_period&active);
c(end)=[];
plot(c,'Color',[1 0 1],'Linewidth',2);
set(gca,'Xtick',0:2:length(c),'XtickLabel',0:0.1:1);
if ~isnan(max(c))
    axis([0 length(c) 0 max(c)+0.05]);
end
n_light=sum(tTotal>min_active_period&active);

if ~isfield(expmt.parameters,'blank_duration') || ...
        (isfield(expmt.parameters,'blank_duration') && expmt.parameters.blank_duration > 0)
% Histogram for blank stimulus with fake lit half
    bins = 0:0.05:1;
    c=histc(bocc(btTotal>min_active_period&active),bins)./sum(btTotal>min_active_period&active);
    c(end)=[];
    hold on
    plot(c,'Color',[0 0 1],'Linewidth',2);
    set(gca,'Xtick',0:2:length(c),'XtickLabel',0:0.1:1);
    if ~isnan(max(c))
        axis([0 length(c) 0 max(c)+0.05]);
    end
    title('Light Occupancy Histogram');
    n_blank=sum(btTotal>min_active_period&active);
    hold off
end

% Generate legend labels
if isfield(expmt,'Strain')
    strain=expmt.Strain;
end
if isfield(expmt,'Treatment')
    treatment=expmt.Treatment;
end

% light ON label
light_avg_occ = round(mean(locc(tTotal>min_active_period&active))*100)/100;
light_mad_occ = round(mad(locc(tTotal>min_active_period&active))*100)/100;
n = sum(tTotal>min_active_period&active);
legendLabel(1)={['Stim ON: ' strain ' ' treatment ' (u=' num2str(light_avg_occ)...
    ', MAD=' num2str(light_mad_occ) ', n=' num2str(n) ')']};

if ~isfield(expmt.parameters,'blank_duration') || ...
        (isfield(expmt.parameters,'blank_duration') && expmt.parameters.blank_duration > 0)
    
    % light OFF label
    blank_avg_occ = round(mean(bocc(btTotal>min_active_period&active))*100)/100;
    blank_mad_occ = round(mad(bocc(btTotal>min_active_period&active))*100)/100;
    n = sum(btTotal>min_active_period&active);
    legendLabel(2)={['Stim OFF: ' strain ' ' treatment ' (u=' num2str(blank_avg_occ)...
        ', MAD=' num2str(blank_mad_occ) ', n=' num2str(n) ')']};
end
legend(legendLabel);
shg

fname = [expmt.figdir expmt.date '_histogram'];
if ~isempty(expmt.figdir) && meta.save
    hgsave(f,fname);
    close(f);
end


% Save data to struct
expmt.Light.avg_occ = locc;
expmt.Blank.avg_occ = bocc;
expmt.Light.active = tTotal>min_active_period&active;
expmt.Blank.active = btTotal>min_active_period&active;

%% Extract handedness from lights ON and lights OFF periods

% blank period
first_half = false(size(trackProps.speed));
first_half(1:round(length(first_half)/2),:) = true;
inc = first_half & trackProps.speed >0.8;
expmt.handedness_First = getHandedness(trackProps,'Include',inc);
inc = repmat(~expmt.Texture.data,1,expmt.nTracks) & trackProps.speed >0.8;
expmt.handedness_Blank = getHandedness(trackProps,'Include',inc);
 inc = ~first_half & trackProps.speed >0.8;
expmt.handedness_Second = getHandedness(trackProps,'Include',inc);
inc = repmat(expmt.Texture.data,1,expmt.nTracks) & trackProps.speed >0.8;
expmt.handedness_Light = getHandedness(trackProps,'Include',inc);

if isfield(meta,'plot') && meta.plot
    if isfield(meta,'handles')
        gui_notify('generating plots',meta.handles.disp_note)
    end
    plotArenaTraces(expmt,'handedness_Blank');
    plotArenaTraces(expmt,'handedness_Light');
end

f=figure(); 
a = expmt.Light.active;
[r,p]=corrcoef([expmt.handedness_First.mu(a)' expmt.handedness_Second.mu(a)'],'rows','pairwise');
sh=scatter(expmt.handedness_First.mu(a),expmt.handedness_Second.mu(a),...
    'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[0.5 0.5 0.5]);
sh.Parent.XLim = [-1 1];
sh.Parent.YLim = [-1 1];
xlabel('stimulus first half \mu');
ylabel('stimulus second half \mu');
dim = [.65 .78 .1 .1];
str = ['r = ' num2str(round(r(2,1)*100)/100) ', p = ' num2str(round(p(2,1)*10000)/10000)...
    ' (n=' num2str(sum(a)) ')'];
annotation('textbox',dim,'String',str,'FitBoxToText','on');
title('slow phototaxis - handedness');

fname = [expmt.figdir expmt.date '_handedness'];
if ~isempty(expmt.figdir) && meta.save
    hgsave(f,fname);
    close(f);
end

%% Generate plots

if isfield(meta,'plot') && meta.plot
    if isfield(meta,'handles')
        gui_notify('generating plots',meta.handles.disp_note)
    end
    plotArenaTraces(expmt);
end

clearvars -except expmt meta

%% Clean up files and wrap up analysis

autoFinishAnalysis(expmt,meta);



function [occ,tOcc,tInc,tDiv,include] = parseBlocks(idx,include,in_light,t)

    % extract block
    include = include(idx{:}(1):idx{:}(2));
    t = t(idx{:}(1):idx{:}(2));
    in_light = in_light(idx{:}(1):idx{:}(2));

    % When one half of the arena is lit
    tmp_t = t(include);                         % ifi for included frames
    tOcc = sum(t(in_light & include))./3600;    % time in the light
    tInc = sum(tmp_t)./3600;                    % time of included frames
    tDiv = (sum(t) - tInc)./3600 ;              % time spent on the divider
    occ = tOcc/tInc;                            % fraction of included time spent in light
    

