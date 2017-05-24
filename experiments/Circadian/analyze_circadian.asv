function expmt = analyze_circadian(expmt,varargin)
%
% This function provides a sample analysis function to run after the
% sample bare-bones template 'experimental_template.m'. It takes the
% experimental master data struct (expmt) as an input, processes the data
% to extract features and store them to file. This sample also shows how to
% automatically zip the raw data files after analysis to reduce file size.

%% Parse inputs, read data from hard disk, format in master struct, process centroid data

[expmt,trackProps,meta] = autoDataProcess(expmt,varargin{:});

clearvars -except expmt trackProps meta


%% extract sliding activity window and create plot

expmt.Speed.data = trackProps.speed;
clearvars trackProps
win_sz = 500;
stp_sz = 100;
[win_dat,win_idx] = getSlidingWindow(expmt,'Speed',win_sz,stp_sz);

% get mean and 95% CI
[mu,~,ci95,~] = normfit(win_dat');
expmt.Circadian.trace.mu = mu;
expmt.Circadian.trace.ci95 = ci95;
mu = smooth(mu,20);
ci95(1,:) = smooth(ci95(1,:),20);
ci95(2,:) = smooth(ci95(2,:),20);

% get index tstamps
tStamps = cumsum(expmt.Time.data);
if length(tStamps)~=length(expmt.Speed.data) && isfield(meta,'decimate')...
        && any(strcmp({'Centroid'},meta.decimate))
    
    tStamps = tStamps(mod(1:expmt.nFrames,meta.decfac)==1);
    
end

tmp_tStamps = tStamps(win_idx);
clearvars tStamps
f=figure();
plot(tmp_tStamps,mu,'r','LineWidth',1.3);
vx = [tmp_tStamps' fliplr(tmp_tStamps')];
vy = [ci95(1,:) fliplr(ci95(2,:))];
hold on
ph=patch(vx,vy,[0.8 0.8 0.8]);
uistack(ph,'bottom');

expmt.Circadian.trace.t = tmp_tStamps;

%% Create time labels and light patches
hr = str2double(expmt.date(12:13));
min = str2double(expmt.date(15:16));
sec = str2double(expmt.date(18:19));
tStart = hr*3600 + min*60 + sec;
tEnd = sum(expmt.Time.data);

% find nearest hour
int = 3600;
first_tick = ceil(tStart/int)*int;
tTick = first_tick - tStart;
tTick = tTick:int:tEnd;
ft_hr = floor(first_tick/3600);

% generate label strings
tickLabels = cell(length(tTick),1);
min_str = '00';
for i = 1:length(tickLabels)
    
    tickLabels(i) = {[num2str(ft_hr) ':' min_str]};
    ft_hr = ft_hr+1;
    
    if ft_hr > 23
        ft_hr = 0;
    end
end
set(gca,'XTick',tTick,'XtickLabel',tickLabels);

expmt.Circadian.trace.tTick = tTick;
expmt.Circadian.trace.tickLabels = tickLabels;

% create graded light-dark patches
tmp_Light = expmt.Light.data;
if length(tmp_Light)~=length(expmt.Light.data) && isfield(meta,'decimate')...
        && any(strcmp({'Centroid'},meta.decimate))
    
    tmp_Light = tmp_Light(mod(1:expmt.nFrames,meta.decfac)==1);
    
end
tmp_Light = tmp_Light(win_idx);
tmp_Light = tmp_Light > 127;
trans = [0;diff(tmp_Light)];
dark_trans = find(trans==1);
dark_trans = [dark_trans;find(trans==-1)];
dark_trans = sort(dark_trans);
dark_trans = [1;dark_trans;length(tmp_Light)];
state = tmp_Light(1);
ylimits = get(gca,'YLim');

for i=1:length(dark_trans)-1
    if ~state
        vx = tmp_tStamps(dark_trans([i i i+1 i+1]));
        vy = ylimits([2 1 1 2]);
        ph = patch(vx,vy,[0.65 0.65 0.65]);
        uistack(ph,'bottom');
    end
    state = ~state;
end

ylabel('Speed');
xlabel('Time of day');
legend({'lights OFF';'95% CI';'mean speed'});
title('Circadian activity trace');

%% Bin speed scores into time bins

% bin by time of day
expmt.Circadian.bins = 0:23;
expmt.Circadian.n = NaN(24,expmt.nTracks);
expmt.Circadian.idx = false(24,size(win_dat,1));
expmt.Circadian.bin_spd = NaN(24,expmt.nTracks);

% find the range of indices of windat that encompass each hour time bin
% from tmp_tStamps
for i = 1:length(tickLabels)
    
    idx = str2double(tickLabels{i}(1:find(tickLabels{i}==':')-1));
    if idx == 0
        idx = 24;
    end
    
    switch i
        case 1
            filter = tmp_tStamps <= tTick(i);
            expmt.Circadian.idx(idx,:) = expmt.Circadian.idx(idx,:) | filter';
        case length(tickLabels)
            filter = tmp_tStamps > tTick(i-1) & tmp_tStamps <= tTick(i);
            expmt.Circadian.idx(idx,:) = expmt.Circadian.idx(idx,:) | filter';
            
            idx = idx+1;
            if idx > 24
                idx=1;
            end
            filter = tmp_tStamps > tTick(i);
            expmt.Circadian.idx(idx,:) = expmt.Circadian.idx(idx,:) | filter';
        otherwise
            filter = tmp_tStamps > tTick(i-1) & tmp_tStamps <= tTick(i);
            expmt.Circadian.idx(idx,:) = expmt.Circadian.idx(idx,:) | filter';
    end
end

% average speed for each animal in each time bin
for i=1:24
    expmt.Circadian.avg_spd(i,:) = nanmean(win_dat(expmt.Circadian.idx(i,:),:));
end

% store normalized speed
norm_speed = win_dat - repmat(mu,1,expmt.nTracks);
for i=1:24
    expmt.Circadian.norm_spd(i,:) = nanmean(norm_speed(expmt.Circadian.idx(i,:),:));
end

expmt.Circadian.avg = nanmean(win_dat);


%%

% save fig
fname = [expmt.figdir expmt.date '_activity trace'];
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

autoFinishAnalysis(expmt,meta)
