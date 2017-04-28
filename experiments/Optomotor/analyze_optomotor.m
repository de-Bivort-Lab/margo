function expmt = analyze_optomotor(expmt,varargin)
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
    prcn = [prcn '=>' prcn];
    
    % read .bin file
    expmt.(f).fID = fopen(path,'r');

    
    % if field is centroid, reshape to (frames x dim x nTracks)
    if strcmp(f,'Centroid')
        expmt.(f).data = fread(expmt.(f).fID,prcn);
        expmt.(f).data = reshape(expmt.(f).data,dim(1),dim(2),expmt.nFrames);
        expmt.(f).data = permute(expmt.(f).data,[3 2 1]);
        expmt.drop_ct = expmt.drop_ct ./ expmt.nFrames;
    
    elseif strcmp(f,'Time')
        expmt.(f).data = fread(expmt.(f).fID,prcn);
        
    elseif ~strcmp(f,'VideoData') || ~strcmp(f,'VideoIndex')
        expmt.(f).data = fread(expmt.(f).fID,[expmt.(f).dim(1) expmt.nFrames],prcn);
        expmt.(f).data = expmt.(f).data';
        
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

figdir = [expmt.fdir 'figures\'];
mkdir(figdir);

[da,opto_bias,nTrials] = extractOptoTraces(expmt.StimStatus.data,expmt,trackProps.speed);
[v,~] = sort(da(~isnan(da)));
llim = v(round(0.05*length(v)));
ulim = v(round(0.95*length(v)));

%get activity filter
a=~isnan(da);
trialnum_thresh = 40;
sampling =(squeeze(sum(sum(a(:,1:trialnum_thresh,:))))./(size(da,1)*size(da,2)));
active = nTrials>trialnum_thresh & sampling > 0.01;
expmt.Optomotor.bias = opto_bias;
expmt.Optomotor.n = nTrials;
expmt.Optomotor.active = active;

% create plot and save fig
f=figure();
plotOptoTraces(da,active,expmt.parameters);
fname = [figdir expmt.fLabel '_combined'];
hgsave(f,fname);
close(f);

%% extract traces by contrast

if isfield(expmt,'Contrast')
    
    dim = ceil((length(expmt.sweep.contrasts)+1)/3);
    f=figure();
    expmt.Contrast.values = expmt.sweep.contrasts;
    expmt.Contrast.bias = NaN(length(expmt.sweep.contrasts),expmt.nTracks);
    expmt.Contrast.active = false(length(expmt.sweep.contrasts),expmt.nTracks);
    
    for i = 1:length(expmt.sweep.contrasts)
        
        % extract subset traces
        subplot(dim,3,i);
        subset = expmt.StimStatus.data & repmat(expmt.Contrast.data == expmt.sweep.contrasts(i),1,expmt.nTracks);
        [da,opto_bias,nTrials] = extractOptoTraces(subset,expmt,trackProps.speed);
        expmt.Contrast.bias(i,:) = opto_bias;
        
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
    for i = 1:length(expmt.sweep.contrasts)
        avg_trace = [avg_trace nanmean(expmt.Contrast.bias(i,expmt.Contrast.active(i,:)))];
    end
    plot(avg_trace,'Linewidth',3);
    title('avg. trace');
    xlabel('contrast')
    ylabel('opto score')
    set(gca,'Xtick',1:length(avg_trace),'XtickLabel',expmt.sweep.contrasts);    
    fname = [figdir expmt.fLabel '_contrast_sweep'];
    hgsave(f,fname);
    close(f);
        
    
end

%% extract traces by angular velocity

if isfield(expmt,'AngularVel')
    
    dim = ceil((length(expmt.sweep.ang_vel)+1)/3);
    expmt.AngularVel.values = expmt.sweep.ang_vel;
    expmt.AngularVel.bias = NaN(length(expmt.sweep.ang_vel),expmt.nTracks);
    expmt.AngularVel.active = false(length(expmt.sweep.ang_vel),expmt.nTracks);
    f=figure();
    
    for i = 1:length(expmt.sweep.ang_vel)
        
        % extract subset traces
        subplot(dim,3,i);
        subset = expmt.StimStatus.data & repmat(expmt.AngularVel.data == expmt.sweep.ang_vel(i),1,expmt.nTracks);
        [da,opto_bias,nTrials] = extractOptoTraces(subset,expmt,trackProps.speed);
        
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
        expmt.AngularVel.bias(i,:) = opto_bias;
    end
    
    subplot(dim,3,i+1);
    avg_trace = [];
    for i = 1:length(expmt.sweep.ang_vel)
        avg_trace = [avg_trace nanmean(expmt.AngularVel.bias(i,expmt.AngularVel.active(i,:)))];
    end
    plot(avg_trace,'Linewidth',3);
    title('avg. trace');
    xlabel('stim \omega  (deg/s)')
    ylabel('opto score')
    set(gca,'Xtick',1:length(avg_trace),'XtickLabel',expmt.sweep.ang_vel);    
    fname = [figdir expmt.fLabel '_angvelocity_sweep'];
    hgsave(f,fname);
    close(f);
    
end

%% extract traces by spatial frequency

if isfield(expmt,'SpatialFreq')
    
    dim = ceil((length(expmt.sweep.spatial_freq)+1)/3);

    f=figure();
    expmt.SpatialFreq.values = expmt.sweep.ang_vel;
    expmt.SpatialFreq.bias = NaN(length(expmt.sweep.ang_vel),expmt.nTracks);
    expmt.SpatialFreq.active = false(length(expmt.sweep.ang_vel),expmt.nTracks);
    
    for i = 1:length(expmt.sweep.spatial_freq)
        
        % extract subset traces
        subplot(dim,3,i);
        subset = expmt.StimStatus.data & repmat(expmt.SpatialFreq.data == expmt.sweep.spatial_freq(i),1,expmt.nTracks);
        [da,opto_bias,nTrials] = extractOptoTraces(subset,expmt,trackProps.speed);
        
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
        
        expmt.SpatialFreq.bias(i,:) = opto_bias;
        expmt.SpatialFreq.active(i,:) = active;
        
    end
    
    subplot(dim,3,i+1);
    avg_trace = [];
    for i = 1:length(expmt.sweep.spatial_freq)
        avg_trace = [avg_trace nanmean(expmt.SpatialFreq.bias(i,expmt.SpatialFreq.active(i,:)))];
    end
    plot(avg_trace,'Linewidth',3);
    title('avg. trace');
    xlabel('stim nCycles/360°)')
    ylabel('opto score')
    set(gca,'Xtick',1:length(avg_trace),'XtickLabel',expmt.sweep.ang_vel);    
    fname = [figdir expmt.fLabel '_spatialfreq_sweep'];
    hgsave(f,fname);
    close(f);
    
end



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

