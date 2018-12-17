function expmt = slideActivity(expmt)

win_sz = 2;             % size of sliding window (minutes)
stp_sz = 1;             % step size between windows (minutes)
sampling_rate = 0.05;    % sampling rate (minutes)
[win_dat,win_idx] = getSlidingWindow(expmt,'speed',win_sz,stp_sz,sampling_rate);

% get mean and 95% CI
alpha = 0.05;
[mu, ~, ci95, ~] = cellfun(@(x) normfit(x(~isnan(x)),alpha), ...
    num2cell(win_dat,2),'UniformOutput', false);
mu = cat(1,mu{:});
ci95 = cat(2,ci95{:});

% get index tstamps
tStamps = cumsum(expmt.data.time.raw());
tStamps = tStamps(win_idx);
if size(tStamps,1) > size(tStamps,2)
    tStamps = tStamps';
end
clearvars tStamps

% plot activity trace
f = figure; hold on;

% plot raw data
vx = [medfilt1(win_dat,15,[],1); NaN(1,size(win_dat,2))];
vy = [repmat(tStamps',1,size(win_dat,2)); NaN(1,size(win_dat,2))];
ph_raw = patch('XData',vy,'YData',vx,'EdgeColor','k','LineWidth',0.25,...
    'FaceColor','none','EdgeAlpha',0.01);

% plot mean and confidence interval
vx = [tStamps fliplr(tStamps)];
vy = [medfilt1(ci95(1,:),30) medfilt1(fliplr(ci95(2,:)),30)];
ph_ci95=patch(vx,vy,[.8 .8 .8],'FaceAlpha',0.5);
ph_mu = plot(tStamps,medfilt1(mu,30),'r');

% Create time labels and light patches
hr = str2double(expmt.meta.date(12:13));
min = str2double(expmt.meta.date(15:16));
sec = str2double(expmt.meta.date(18:19));
tStart = hr*3600 + min*60 + sec;
tEnd = sum(expmt.data.time.raw());

% find nearest hour
int = 3600;
first_tick = ceil(tStart/int)*int;
if tEnd/3600 < 1
    hr_step = 0.1;
elseif tEnd/3600 < 6
    hr_step = 0.5;
elseif tEnd/3600 < 12
    hr_step = 1;
elseif tEnd/3600 < 24
    hr_step = 2;
elseif tEnd/3600 < 48
    hr_step = 4;
else
    hr_step = 12;
end
    
% find the first tick index
if mod(first_tick/3600,hr_step)
    first_tick = first_tick + (hr_step-mod(first_tick/3600,hr_step))*3600;
end
tTick = first_tick - tStart;
tTick = tTick:int:tEnd;
ft_hr = floor(first_tick/3600);

% generate label strings
tickLabels = cell(length(tTick),1);
for i = 1:length(tickLabels)
    t = tTick(i) + tStart;
    if ft_hr > 23
        ft_hr = 0;
    end
    tickLabels(i) = {sprintf('%02.0f:%02.0f',mod(t/3600,24),mod(t/60,60))};
end

% Bin speed scores into time of day bins
circ.bins = 0:23;
circ.n = NaN(24,expmt.meta.num_traces);
circ.bin_spd = NaN(24,expmt.meta.num_traces);
circ.t = (tStamps + tStart)/3600;

% find indices of each time bin
hr = repmat(floor(mod(circ.t,24)),24,1);
circ.bin_idx = hr - repmat((1:24)',1,size(hr,2)) == 0;

% average speed for each animal in each time bin
for i=1:24
    circ.avg_spd(i,:) = nanmean(win_dat(circ.bin_idx(i,:),:));
end

circ.avg = nanmean(win_dat);
circ.data = win_dat;
expmt.meta.Circadian = circ;
    
% create graded light-dark patches
if strcmpi(expmt.meta.name,'Circadian') && isfield(expmt.data,'Light')
    
    reset(expmt);
    tmp_Light = expmt.data.Light.raw();
    tmp_Light = tmp_Light(win_idx);
    tmp_Light = tmp_Light > 0;
    trans = [0,diff(tmp_Light)];
    dark_trans = find(trans==1);
    dark_trans = [dark_trans,find(trans==-1)];
    dark_trans = sort(dark_trans);
    dark_trans = [1,dark_trans,length(tmp_Light)];
    state = tmp_Light(1);
    ylimits = get(gca,'YLim');

    for i=1:length(dark_trans)-1
        if ~state
            vx = tStamps(dark_trans([i i i+1 i+1]));
            vy = ylimits([2 1 1 2]);
            light_ph = patch(vx,vy,[0.65 0.65 0.65]);
            uistack(light_ph,'bottom');
        end
        state = ~state;
    end
    
    % set legend labels
    legend([light_ph,ph_raw,ph_ci95,ph_mu],...
        {'lights off';'raw';['CI (\alpha=' sprintf('%1.0E)',alpha)];'mean'});
else

    % set legend labels
    legend([ph_raw,ph_ci95,ph_mu],...
        {'raw';['CI (\alpha=' sprintf('%1.0E)',alpha)];'mean'});
end

% save fig
set(gca,'XTick',tTick(1:hr_step:end),'XtickLabel',tickLabels(1:hr_step:end),...
    'XLim',[tStamps(1) tStamps(end)]);
title('Activity Trace');
xlabel('Time of Day');
ylabel('Speed');
fname = [expmt.meta.path.fig expmt.meta.date '_activity trace'];
if ~isempty(expmt.meta.path.fig) && options.save
    hgsave(f,fname);
    close(f);
end

% save results to ExperimentData
expmt.meta.Activity = struct('mean',mu,'CI',ci95,'alpha',alpha,...
    'individual_traces',win_dat,'t_stamps',tStamps,...
    't_ticks',tTick,'t_tick_labels',tickLabels);

