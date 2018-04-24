function expmt = analyze_circadian(expmt,varargin)
%
% This function provides a sample analysis function to run after the
% sample bare-bones template 'experimental_template.m'. It takes the
% experimental master data struct (expmt) as an input, processes the data
% to extract features and store them to file. This sample also shows how to
% automatically zip the raw data files after analysis to reduce file size.

%% Parse inputs, read data from hard disk, format in master struct, process centroid data

[expmt,options] = autoDataProcess(expmt,varargin{:});

clearvars -except expmt trackProps options


%% get individual area thresholds for separating frames at the ceiling and floor of the well

if isfield(expmt,'Area') && isfield(expmt.Area,'map') && ...
        isfield(options,'area_thresh') && options.area_thresh
    
    % find threshold for each individual
    moving = expmt.Speed.map.Data.raw > 0.8;
    a= expmt.Area.map.Data.raw;
    a(~moving) = NaN;
    a = num2cell(expmt.Area.map.Data.raw,2);
    if isfield(options,'handles')
        gui_notify('finding area thresholds',options.handles.disp_note);
    end
    [ints,means,sigmas] = cellfun(@fitBimodalHist,a,'UniformOutput',false);
    expmt.Area.thresh = NaN(expmt.nTracks,1);
    expmt.Area.thresh(~cellfun(@isempty,ints)) = [ints{:}];
    expmt.Area.modeMeans = NaN(expmt.nTracks,2);
    expmt.Area.modeMeans(~cellfun(@isempty,means),:) = [means{:}]';
    expmt.Area.modeSigmas = NaN(expmt.nTracks,2);
    expmt.Area.modeSigmas(~cellfun(@isempty,sigmas),:) = [sigmas{:}]';
    
    % parse data into arena ceiling and floor frames
    ints(cellfun(@isempty,ints))={NaN};
    expmt.Area.ceiling = cellfun(@(x,y) x>y, a,ints,'UniformOutput',false);
    expmt.Area.ceiling = cat(1,expmt.Area.ceiling{:});
    expmt.Area.floor = cellfun(@(x,y) x<y, a,ints,'UniformOutput',false);
    expmt.Area.floor = cat(1,expmt.Area.floor{:});
    clear a moving
    
    % get gravity index
    expmt.Gravity.index = (sum(expmt.Area.ceiling,2)-sum(expmt.Area.floor,2))./...
        (sum(expmt.Area.ceiling,2)+sum(expmt.Area.floor,2));   
    
end
    

%% extract sliding activity window and create plot


if options.slide
    
    win_sz = 700;
    stp_sz = 350;
    if isfield(options,'handles')
        gui_notify('sliding speed window, may take a few minutes',options.handles.disp_note);
    end
    [win_dat,win_idx] = getSlidingWindow(expmt,'Speed',win_sz,stp_sz);

    % get mean and 95% CI
    [mu,~,ci95,~] = normfit(win_dat');
    expmt.Circadian.trace.mu = mu;
    expmt.Circadian.trace.ci95 = ci95;
    mu = medfilt1(mu);
    ci95(1,:) = medfilt1(ci95(1,:));
    ci95(2,:) = medfilt1(ci95(2,:));

    % get index tstamps
    tStamps = cumsum(expmt.Time.map.Data.raw);
    if length(tStamps)~=length(expmt.Speed.map.Data.raw) && isfield(options,'decimate')...
            && any(strcmp({'Centroid'},options.decimate))

        tStamps = tStamps(mod(1:expmt.nFrames,options.decfac)==1);

    end

    tmp_tStamps = tStamps(win_idx);
    if size(tmp_tStamps,1) > size(tmp_tStamps,2)
        tmp_tStamps = tmp_tStamps';
    end
    clearvars tStamps
    f=figure();
    ph_mu = plot(tmp_tStamps,mu,'r','LineWidth',1.3);
    vx = [tmp_tStamps fliplr(tmp_tStamps)];
    vy = [ci95(1,:) fliplr(ci95(2,:))];
    hold on
    ph_ci95=patch(vx,vy,[0.8 0.8 0.8]);
    uistack(ph_ci95,'bottom');

    expmt.Circadian.trace.t = tmp_tStamps;

    % Create time labels and light patches
    hr = str2double(expmt.date(12:13));
    min = str2double(expmt.date(15:16));
    sec = str2double(expmt.date(18:19));
    tStart = hr*3600 + min*60 + sec;
    tEnd = sum(expmt.Time.map.Data.raw);

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
    tmp_Light = expmt.Light.map.Data.raw;
    if length(tmp_Light)~=length(expmt.Light.map.Data.raw) && isfield(options,'decimate')...
            && any(strcmp({'Centroid'},options.decimate))

        tmp_Light = tmp_Light(mod(1:expmt.nFrames,options.decfac)==1);

    end
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
            vx = tmp_tStamps(dark_trans([i i i+1 i+1]));
            vy = ylimits([2 1 1 2]);
            ph = patch(vx,vy,[0.65 0.65 0.65]);
            uistack(ph,'bottom');
        end
        state = ~state;
    end

    ylabel('Speed');
    xlabel('Time of day');
    legend([ph,ph_ci95,ph_mu],{'lights OFF';'95% CI';'mean speed'});
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
                
            case length(tickLabels)
                filter = tmp_tStamps > tTick(i-1) & tmp_tStamps <= tTick(i);
                idx = idx+1;
                if idx > 24
                    idx=1;
                end
                filter = tmp_tStamps > tTick(i);
                
            otherwise
                filter = tmp_tStamps > tTick(i-1) & tmp_tStamps <= tTick(i);
        end
        
        [~,filter] = matchDim(expmt.Circadian.idx(idx,:),filter);
        disp(sum(filter))
        expmt.Circadian.idx(idx,:) = expmt.Circadian.idx(idx,:) | filter;
        
    end

    % average speed for each animal in each time bin
    for i=1:24
        expmt.Circadian.avg_spd(i,:) = nanmean(win_dat(expmt.Circadian.idx(i,:),:));
    end

    % store normalized speed
    [mu,win_dat] = matchDim(mu,win_dat);
    norm_speed = win_dat - repmat(mu,1,expmt.nTracks);
    for i=1:24
        expmt.Circadian.norm_spd(i,:) = nanmean(norm_speed(expmt.Circadian.idx(i,:),:));
    end

    expmt.Circadian.avg = nanmean(win_dat);
    expmt.Circadian.data = win_dat;

    % Create traces and time stamp pairs for comparing across experiments

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
    if ~isempty(expmt.figdir) && options.save
        hgsave(f,fname);
        close(f);
    end
        
end

%% Generate plots

if isfield(options,'plot') && options.plot
    if isfield(options,'handles')
        gui_notify('generating plots',options.handles.disp_note)
    end
    plotArenaTraces(expmt);
end

clearvars -except expmt options

%% Clean up files and wrap up analysis

autoFinishAnalysis(expmt,options)
