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

expmt.Speed.data = trackProps.speed;
clearvars trackProps

%% extract sliding activity window and create plot


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
minute = str2double(expmt.date(15:16));
sec = str2double(expmt.date(18:19));
tStart = hr*3600 + minute*60 + sec;
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
    
    win_idx = str2double(tickLabels{i}(1:find(tickLabels{i}==':')-1));
    if win_idx == 0
        win_idx = 24;
    end
    
    switch i
        case 1
            filter = tmp_tStamps <= tTick(i);
            expmt.Circadian.idx(win_idx,:) = expmt.Circadian.idx(win_idx,:) | filter';
        case length(tickLabels)
            filter = tmp_tStamps > tTick(i-1) & tmp_tStamps <= tTick(i);
            expmt.Circadian.idx(win_idx,:) = expmt.Circadian.idx(win_idx,:) | filter';
            
            win_idx = win_idx+1;
            if win_idx > 24
                win_idx=1;
            end
            filter = tmp_tStamps > tTick(i);
            expmt.Circadian.idx(win_idx,:) = expmt.Circadian.idx(win_idx,:) | filter';
        otherwise
            filter = tmp_tStamps > tTick(i-1) & tmp_tStamps <= tTick(i);
            expmt.Circadian.idx(win_idx,:) = expmt.Circadian.idx(win_idx,:) | filter';
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

%% find time stamps for motor activity

tStamps = cumsum(expmt.Time.data)+tStart;
tPulse = sum(expmt.parameters.lights_OFF([1 2]).*[3600 60]) + expmt.parameters.ramp_time*60;
tPulse = tPulse:3600/expmt.parameters.pulse_per_hour:tStamps(end);
[~,win_idx] = min(abs(repmat(tStamps,1,length(tPulse)) - repmat(tPulse,length(tStamps),1)));
tPulse(expmt.Light.data(win_idx)>10)=[];
win_idx(expmt.Light.data(win_idx)>10)=[];
tInitiate = tPulse;
tPulse = tPulse - 30*60;
tStop = tPulse + 30*60*2;

% get indices of window starts and stops
[~,win_start] = min(abs(repmat(tStamps,1,length(tPulse)) - repmat(tPulse,length(tStamps),1)));
[~,win_stop] = min(abs(repmat(tStamps,1,length(tStop)) - repmat(tStop,length(tStamps),1)));
expmt.Circadian.motor.idx = [win_start' win_stop'];
win_sz = max(win_stop-win_start);
expmt.Circadian.motor.bouts = NaN(win_sz,expmt.nTracks,length(win_start));

% collect bouts in window
for i = 1:length(win_start)
    
    ns=win_stop(i)-win_start(i)+1;
    expmt.Circadian.motor.bouts(:,:,i) = interp1(1:ns,...
        expmt.Speed.data(win_start(i):win_stop(i),:),linspace(1,ns,win_sz));
    
end

% get indices of motor pulse for trace plot
tStamps = expmt.Circadian.trace.t + tStart;
hold on
ah = gca;
for i=1:length(tPulse)
    plot([tInitiate(i) tInitiate(i)]-tStart,ah.YLim,'k--','Linewidth',1.5);
end
hold off


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
