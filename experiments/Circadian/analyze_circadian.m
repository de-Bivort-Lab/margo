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


%% get individual area thresholds for separating frames at the ceiling and floor of the well

if isfield(expmt,'Area') && isfield(expmt.Area,'data')
    %%
    % find threshold for each individual
    filt = expmt.Speed.data > 0.3;
    filt = filt & expmt.Area.data > 30*expmt.parameters.mm_per_pix^2;
    Area = expmt.Area.data;
    Area(~filt) = NaN;
    Area = num2cell(Area,1);
    disp('finding area thresholds');
    [area_thresholds, mode_means] = ...
        cellfun(@kthresh_distribution, Area, 'UniformOutput', false);

    % plot individual distributions
    f=figure;
    nCols = ceil(0.125*expmt.nTracks);
    nRows = ceil(expmt.nTracks/nCols);
    for i=1:expmt.nTracks
        subplot(nRows,nCols,i);
        if ~isempty(area_thresholds{i})
            [kde,x] = ksdensity(Area{i});
            plot(x,kde,'k','LineWidth',1);
            hold on
            y = get(gca,'YLim');
            vx = [repmat([mode_means{i}(1) mode_means{i}(2)],2,1); NaN(1,2)];
            vy = repmat([y'; NaN],1,2);
            plot(vx(:),vy(:),'b','LineWidth',0.5);
            plot([area_thresholds{i} area_thresholds{i}],y,'r','LineWidth',0.5);
            hold off
        end
        if mod(i,nCols)==1
            ylabel('density');
        end
        if i>nCols*(nRows-1)
            xlabel('area');
        end
    end
    %%
    
    % save fig
    fname = [expmt.figdir expmt.date '_individual_area_thresholds'];
    if ~isempty(expmt.figdir) && meta.save
        hgsave(f,fname);
        close(f);
    end

    expmt.Area.thresh = area_thresholds;
    expmt.Area.modeMeans = mode_means;
    
    % parse data into arena ceiling and floor frames
    area_thresholds(cellfun(@isempty,area_thresholds))={NaN};
    expmt.Area.ceiling = cellfun(@(x,y) x>y, Area, ...
        area_thresholds,'UniformOutput',false);
    expmt.Area.ceiling = cat(2,expmt.Area.ceiling{:});
    expmt.Area.floor = cellfun(@(x,y) x<y, Area, ...
        area_thresholds,'UniformOutput',false);
    expmt.Area.floor = cat(2,expmt.Area.floor{:});
    
    % get gravity index
    expmt.Gravity.index = (sum(expmt.Area.ceiling)-sum(expmt.Area.floor))./...
        (sum(expmt.Area.ceiling)+sum(expmt.Area.floor));
    
    % parse handedness data into ceiling and floor
    expmt.handedness_ceiling = getHandedness(trackProps,'Include',expmt.Area.ceiling);
    expmt.handedness_floor = getHandedness(trackProps,'Include',expmt.Area.floor);
    
    % bin circumferential velocity into histogram
    bw = 2*pi/25;                                   % bin width
    bins = 0:bw:2*pi;                               % handedness bins
    tmpcv = expmt.handedness.circum_vel;
    tmpcv(expmt.Area.ceiling) = -tmpcv(expmt.Area.ceiling);
    h = histc(tmpcv,bins);
    h = h./repmat(sum(h),size(h,1),1);

    % save to expmt data struct
    expmt.Gravity.angle_histogram = h;
    expmt.Gravity.mu = -sin(sum(h .* repmat((bins' + bw/2),1,size(h,2))));   
    
end
    

%% extract sliding activity window and create plot


if meta.slide
    
win_sz = 2;             % size of sliding window (minutes)
stp_sz = 1;             % step size between windows (minutes)
sampling_rate = 0.05;    % sampling rate (minutes)
[win_dat,win_idx] = getSlidingWindow(expmt,'Speed',win_sz,stp_sz,sampling_rate);

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

% Create time labels and light patches
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
tmp_Light = tmp_Light > 0;
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

% Bin speed scores into time bins

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
expmt.Circadian.data = win_dat;

%% Create traces and time stamp pairs for comparing across experiments

nDays = ceil(max(tmp_tStamps)/(24*3600));
tmp_tStamps = tmp_tStamps + tStart;     % shift time stamps to start at 0:00

if nDays==1
    
    % shift time stamps to time of day and permute trace data
    tmp_tStamps(tmp_tStamps>(24*3600)) = tmp_tStamps(tmp_tStamps>(24*3600))-(24*3600);
    [tmp_tStamps,p] = sort(tmp_tStamps);
    win_dat = win_dat(p,:);
    
    expmt.Circadian.id_trace.data = win_dat;
    expmt.Circadian.id_trace.t = tmp_tStamps;
    if max(diff(tmp_tStamps)) > mean(diff(tmp_tStamps))*2
        [~,expmt.Circadian.id_trace.break] = max(diff(tmp_tStamps));
    end
    
end

% save fig
fname = [expmt.figdir expmt.date '_activity trace'];
if ~isempty(expmt.figdir) && meta.save
    hgsave(f,fname);
    close(f);
end
        
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
