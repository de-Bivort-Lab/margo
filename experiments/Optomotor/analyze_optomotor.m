function expmt = analyze_optomotor(expmt,varargin)
%
% This function provides a sample analysis function to run after the
% sample bare-bones template 'experimental_template.m'. It takes the
% experimental master data struct (expmt) as an input, processes the data
% to extract features and store them to file. This sample also shows how to
% automatically zip the raw data files after analysis to reduce file size.

%% Parse inputs, read data from hard disk, format in master struct, process centroid data

[expmt,trackProps,options] = autoDataProcess(expmt,varargin{:});

clearvars -except expmt options

%% Analyze stimulus response


[da,opto_index,nTrials,stimdir_dist,total_dist] = ...
    extractOptoTraces(expmt.StimStatus.data,expmt,trackProps.speed);
[v,~] = sort(da(~isnan(da)));
llim = v(round(0.05*length(v)));
ulim = v(round(0.95*length(v)));

%get activity filter
a=~isnan(da);
trialnum_thresh = 40;
sampling =(squeeze(sum(sum(a(:,1:trialnum_thresh,:))))./(size(da,1)*size(da,2)));
active = nTrials>trialnum_thresh & sampling > 0.01;
expmt.Optomotor.index = opto_index;
expmt.Optomotor.n = nTrials;
expmt.Optomotor.active = active;
expmt.Optomotor.sdist = stimdir_dist;
expmt.Optomotor.tdist = total_dist;

% bootstrap optomotor index
nReps = 1000;
[expmt.Optomotor.bootstrap,~,f]=bootstrap_optomotor(expmt,nReps,'Optomotor');

fname = [expmt.meta.path.fig expmt.meta.date '_bs_opto'];
if ~isempty(expmt.meta.path.fig) && options.save
    hgsave(f,fname);
    close(f);
end

% create plot and save fig
f=figure();
plotOptoTraces(da,active,expmt.parameters);

fname = [expmt.meta.path.fig expmt.meta.date '_combined'];
if ~isempty(expmt.meta.path.fig) && options.save
    hgsave(f,fname);
    close(f);
end



%% extract traces by contrast

if isfield(expmt,'sweep')
    
    dim = ceil((length(expmt.sweep.contrasts)+1)/3);
    f=figure();
    expmt.Contrast.values = expmt.sweep.contrasts;
    expmt.Contrast.index = NaN(length(expmt.sweep.contrasts),expmt.meta.num_traces);
    expmt.Contrast.active = false(length(expmt.sweep.contrasts),expmt.meta.num_traces);
    
    for i = 1:length(expmt.sweep.contrasts)
        
        % extract subset traces
        subplot(dim,3,i);
        subset = expmt.StimStatus.data & repmat(expmt.Contrast.data == expmt.sweep.contrasts(i),1,expmt.meta.num_traces);
        [da,opto_index,nTrials] = extractOptoTraces(subset,expmt,trackProps.speed);
        expmt.Contrast.index(i,:) = opto_index;
        
        % filter data for activity
        a=~isnan(da);
        trialnum_thresh = round(median(nTrials)*0.5);
        active = nTrials > trialnum_thresh;
        sampling = false(size(active));
        sampling(active) = (squeeze(sum(sum(a(:,1:trialnum_thresh,active))))...
            ./(size(da,1)*size(da,2))) > 0.01;
        active = sampling;
        expmt.Contrast.active(i,:) = active;
        
        % plot traces
        titstr = ['contrast = ' num2str(expmt.sweep.contrasts(i))];
        plotOptoTraces(da,active,expmt.parameters,'title',titstr,'Ylim',[llim ulim]);
    end

    subplot(dim,3,i+1);
    avg_trace = [];
    ci_trace = [];
    for i = 1:length(expmt.sweep.contrasts)
        [m,~,ci95,~] = normfit(expmt.Contrast.index(i,expmt.Contrast.active(i,:))');
        avg_trace = [avg_trace m];
        ci_trace = [ci_trace ci95];
    end
    plot(avg_trace,'Linewidth',3);
    vx = [1:length(avg_trace) fliplr(1:length(avg_trace))];
    vy = [ci_trace(1,:) fliplr(ci_trace(2,:))];
    hold on
    ph = patch(vx,vy,[0 0.9 0.9],'FaceAlpha',0.3);
    uistack(ph,'bottom');
    title('avg. trace');
    xlabel('contrast')
    ylabel('opto index')
    set(gca,'Xtick',1:length(avg_trace),'XtickLabel',expmt.sweep.contrasts);
    legend({'95%CI' 'index'})
    
    fname = [expmt.meta.path.fig expmt.meta.date '_con_swp'];
    if ~isempty(expmt.meta.path.fig) && options.save
        hgsave(f,fname);
        close(f);
    end
    
end

%% extract traces by angular velocity

if isfield(expmt,'sweep')
    
    dim = ceil((length(expmt.sweep.ang_vel)+1)/3);
    expmt.AngularVel.values = expmt.sweep.ang_vel;
    expmt.AngularVel.index = NaN(length(expmt.sweep.ang_vel),expmt.meta.num_traces);
    expmt.AngularVel.active = false(length(expmt.sweep.ang_vel),expmt.meta.num_traces);
    f=figure();
    
    for i = 1:length(expmt.sweep.ang_vel)
        
        % extract subset traces
        subplot(dim,3,i);
        subset = expmt.StimStatus.data & repmat(expmt.AngularVel.data == expmt.sweep.ang_vel(i),1,expmt.meta.num_traces);
        [da,opto_index,nTrials] = extractOptoTraces(subset,expmt,trackProps.speed);
        
        % filter data for activity
        a=~isnan(da);
        trialnum_thresh = round(median(nTrials)*0.5);
        active = nTrials > trialnum_thresh;
        sampling = false(size(active));
        sampling(active) = (squeeze(sum(sum(a(:,1:trialnum_thresh,active))))...
            ./(size(da,1)*size(da,2))) > 0.01;
        active = sampling;
        
        
        % create plots
        titstr = ['angular velocity = ' num2str(expmt.sweep.ang_vel(i))];
        plotOptoTraces(da,active,expmt.parameters,'title',titstr,'Ylim',[llim ulim]);
        
        expmt.AngularVel.active(i,:) = active;
        expmt.AngularVel.index(i,:) = opto_index;
    end
    
    subplot(dim,3,i+1);
    avg_trace = [];
    ci_trace = [];
    for i = 1:length(expmt.sweep.ang_vel)
        [m,~,ci95,~] = normfit(expmt.AngularVel.index(i,expmt.AngularVel.active(i,:))');
        avg_trace = [avg_trace m];
        ci_trace = [ci_trace ci95];
    end
    plot(avg_trace,'Linewidth',3);
    vx = [1:length(avg_trace) fliplr(1:length(avg_trace))];
    vy = [ci_trace(1,:) fliplr(ci_trace(2,:))];
    hold on
    ph = patch(vx,vy,[0 0.9 0.9],'FaceAlpha',0.3);
    uistack(ph,'bottom');
    title('avg. trace');
    legend({'95%CI' 'index'})
    xlabel('stim \omega  (deg/s)')
    ylabel('opto index')
    set(gca,'Xtick',1:length(avg_trace),'XtickLabel',expmt.sweep.ang_vel);    

    fname = [expmt.meta.path.fig expmt.meta.date '_angv_swp'];
    if ~isempty(expmt.meta.path.fig) && options.save
        hgsave(f,fname);
        close(f);
    end
    
end

%% extract traces by spatial frequency

if isfield(expmt,'sweep')
    
    dim = ceil((length(expmt.sweep.spatial_freq)+1)/3);

    f=figure();
    expmt.SpatialFreq.values = expmt.sweep.ang_vel;
    expmt.SpatialFreq.index = NaN(length(expmt.sweep.ang_vel),expmt.meta.num_traces);
    expmt.SpatialFreq.active = false(length(expmt.sweep.ang_vel),expmt.meta.num_traces);
    
    for i = 1:length(expmt.sweep.spatial_freq)
        
        % extract subset traces
        subplot(dim,3,i);
        subset = expmt.StimStatus.data & repmat(expmt.SpatialFreq.data == expmt.sweep.spatial_freq(i),1,expmt.meta.num_traces);
        [da,opto_index,nTrials] = extractOptoTraces(subset,expmt,trackProps.speed);
        
        % filter data for activity
        a=~isnan(da);
        trialnum_thresh = round(median(nTrials)*0.5);
        active = nTrials > trialnum_thresh;
        sampling = false(size(active));
        sampling(active) = (squeeze(sum(sum(a(:,1:trialnum_thresh,active))))...
            ./(size(da,1)*size(da,2))) > 0.01;
        active = sampling;
        
        % create plots
        titstr = ['num. cycles = ' num2str(expmt.sweep.spatial_freq(i))];
        plotOptoTraces(da,active,expmt.parameters,'title',titstr,'Ylim',[llim ulim]);
        
        expmt.SpatialFreq.index(i,:) = opto_index;
        expmt.SpatialFreq.active(i,:) = active;
        
    end
    
    subplot(dim,3,i+1);
    avg_trace = [];
    ci_trace = [];
    for i = 1:length(expmt.sweep.spatial_freq)
        [m,~,ci95,~] = normfit(expmt.SpatialFreq.index(i,expmt.SpatialFreq.active(i,:))');
        avg_trace = [avg_trace m];
        ci_trace = [ci_trace ci95];
    end
    plot(avg_trace,'Linewidth',3);
    vx = [1:length(avg_trace) fliplr(1:length(avg_trace))];
    vy = [ci_trace(1,:) fliplr(ci_trace(2,:))];
    hold on
    ph = patch(vx,vy,[0 0.9 0.9],'FaceAlpha',0.3);
    uistack(ph,'bottom');
    title('avg. trace');
    legend({'95%CI' 'index'})
    xlabel('stim nCycles/360°')
    ylabel('opto index')
    set(gca,'Xtick',1:length(avg_trace),'XtickLabel',expmt.sweep.spatial_freq);  

    fname = [expmt.meta.path.fig expmt.meta.date '_spatf_swp'];
    if ~isempty(expmt.meta.path.fig) && options.save
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

autoFinishAnalysis(expmt,options);

