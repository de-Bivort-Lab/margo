function expmt = analyze_tempphototaxis(expmt,varargin)
%
% This function provides a sample analysis function to run after the
% sample bare-bones template 'experimental_template.m'. It takes the
% experimental master data struct (expmt) as an input, processes the data
% to extract features and store them to file. This sample also shows how to
% automatically zip the raw data files after analysis to reduce file size.

%% Parse inputs, read data from hard disk, format in master struct, process centroid data

[expmt,options] = autoDataProcess(expmt,varargin{:});

clearvars -except expmt options

%% Analyze stimulus response

% add new properties to LightStatus
props = {'n';'iti';'trans';'occ'};
addprops(expmt.data.LightStatus, props);

% get stimulus transitions
stim_trans = diff([zeros(1,expmt.meta.num_traces);expmt.data.LightStatus.raw()]);
[r,c] = find(stim_trans ~= 0);
expmt.data.LightStatus.trans = cell(expmt.meta.num_traces,1);
expmt.data.LightStatus.n = NaN(expmt.meta.num_traces,1);
expmt.data.LightStatus.iti = NaN(expmt.meta.num_traces,1);
for i = 1:expmt.meta.num_traces
    expmt.data.LightStatus.trans(i) = {r(c==i)};
    expmt.data.LightStatus.iti(i) = mean(diff(expmt.data.LightStatus.trans{i})).*nanFilteredMean(expmt.data.time.raw());
    expmt.data.LightStatus.n(i) = length(expmt.data.LightStatus.trans{i});
end

expmt.data.LightStatus.occ = nanFilteredMean(expmt.data.LightStatus.raw());

%{
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


% Calculate occupancy for each fly in both blank and photo_stim conditions
for i=1:expmt.meta.num_traces
    
    % When one half of the arena is lit
    off_divider = abs(div_dist{i})>div_thresh(i)*2;                       % data mask for trials where fly is clearly in one half or the other
    include = off_divider & expmt.Texture.data;
    [occ,tOcc,tInc,tDiv,inc] = arrayfun(@(k) parseBlocks(k,include,...  % extract occupancy for each stimulus block
        in_Light{i},expmt.data.time.raw()), lb, 'UniformOutput',false);
    expmt.Light.include(:,i) = inc;                                     % light status for included frames
    expmt.Light.tOcc(:,i) = tOcc;                                       % total time in the light
    expmt.Light.tInc(:,i) = tInc;                                       % time of included frames
    expmt.Light.tDiv(:,i) = tDiv;                                       % time on stim divider
    expmt.Light.occ(:,i) = occ;                                         % fractional time in light of included frames
    clearvars occ tOcc tInc tDiv inc
    
    % When both halfs of the arena are unlit
    include = off_divider & ~expmt.Texture.data;
    [occ,tOcc,tInc,tDiv,inc] = arrayfun(@(k) parseBlocks(k,include,...  % extract occupancy for each stimulus block
        in_Light{i},expmt.data.time.raw()), bb, 'UniformOutput',false);
    expmt.Blank.include(:,i) = inc;                                     % light status for included frames
    expmt.Blank.tOcc(:,i) = tOcc;                                       % total time in the light
    expmt.Blank.tInc(:,i) = tInc;
    expmt.Blank.tDiv(:,i) = tDiv;
    expmt.Blank.occ(:,i) = occ;  
    
end
%}

%% Get centroid relative to stimulus

% stimang = expmt.StimAngle;
% stimang(stimang>180)=stimang(stimang>180)-360;
% stimang = stimang * pi ./ 180;
% cen_theta = trackProps.theta - repmat(stimang',expmt.meta.num_frames,1);
% clearvars stimang
% 
% stim_cen.data = NaN(size(expmt.data.centroid.raw()));
% stim_cen.data(:,1,:) = trackProps.r .* cos(cen_theta);
% stim_cen.data(:,2,:) = trackProps.r .* sin(cen_theta);
% expmt.meta.StimCen = stim_cen;

%% Bootstrap data to measure overdispersion
%{
nReps = 1000;
[expmt.Light.bs,f] = bootstrap_slowphototaxis(expmt,nReps,'Light');
fname = [expmt.meta.path.fig expmt.meta.date '_light_bs'];
if ~isempty(expmt.meta.path.fig) && options.save
    hgsave(f,fname);
    close(f);
end

if ~isfield(expmt.parameters,'blank_duration') || ...
        (isfield(expmt.parameters,'blank_duration') && expmt.parameters.blank_duration > 0)
    
    [expmt.Blank.bs,f] = bootstrap_slowphototaxis(expmt,nReps,'Blank');
    fname = [expmt.meta.path.fig expmt.meta.date '_dark_bs'];
    if ~isempty(expmt.meta.path.fig) && options.save
        hgsave(f,fname);
        close(f);
    end
    
end


%% Generate plots

% Minimum time spent off the boundary divider (hours)
min_active_period = 0.2 * sum(expmt.data.time.raw()(expmt.Texture.data), 'omitnan')/3600;        
active = nanFilteredMean(trackProps.speed) > 0.1;
tTotal = sum(cell2mat(expmt.Light.tInc), 'omitnan');
btTotal = sum(cell2mat(expmt.Blank.tInc), 'omitnan');
locc = nanFilteredMean(cell2mat(expmt.Light.occ));
bocc = nanFilteredMean(cell2mat(expmt.Blank.occ));

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
    strain=expmt.meta.strain;
end
if isfield(expmt,'Treatment')
    treatment=expmt.meta.treatment;
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

fname = [expmt.meta.path.fig expmt.meta.date '_histogram'];
if ~isempty(expmt.meta.path.fig) && options.save
    hgsave(f,fname);
    close(f);
end


% Save data to struct
expmt.Light.avg_occ = locc;
expmt.Blank.avg_occ = bocc;
expmt.Light.active = tTotal>min_active_period&active;
expmt.Blank.active = btTotal>min_active_period&active;
%}

clearvars -except expmt options

%% Clean up files and wrap up analysis

autoFinishAnalysis(expmt,options);



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
    

