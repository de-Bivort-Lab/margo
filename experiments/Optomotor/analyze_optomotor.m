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
%{
expmt.Orientation.data = expmt.Orientation.data.*pi./180;
expmt.Optomotor.data = expmt.Orientation.data;
expmt.Optomotor.bins = -pi/2:pi/25:pi/2;

for i = 1:expmt.nTracks
    expmt.Optomotor.data(i,expmt.Texture.data(i,:)) = -expmt.Optomotor.data(i,expmt.Texture.data(i,:));
    expmt.Optomotor.include(:,i) = expmt.handedness.include(:,i)' & expmt.StimStatus.data(i,:);
    expmt.Baseline.include(:,i) = expmt.handedness.include(:,i)' & ~expmt.StimStatus.data(i,:);
    h = histc(expmt.Optomotor.data(i,expmt.Optomotor.include(:,i)),expmt.Optomotor.bins);
    expmt.Optomotor.hist(:,i) = h./sum(h);
end

off_spd=NaN(expmt.nTracks,1);
on_spd=NaN(expmt.nTracks,1);

for i = 1:expmt.nTracks
    
    off_spd(i)=nanmean(trackProps.speed(expmt.Baseline.include(:,i),i));
    on_spd(i)=nanmean(trackProps.speed(expmt.Optomotor.include(:,i),i));
    
end
%}

[iOFFr,iOFFc]=find(diff(expmt.StimStatus.data')==-1);
iOFFr=iOFFr+1;
nTrials=NaN(expmt.nTracks,1);

for i=1:expmt.nTracks
    nTrials(i)=sum(iOFFc==i);
end

[iONr,iONc]=find(diff(expmt.StimStatus.data')==1);
iONr=iONr+1;
[iOFFr,iOFFc]=find(diff(expmt.StimStatus.data')==-1);
iOFFr=iOFFr+1;

% Stimulus triggered averaging of each stimulus bout
win_sz = expmt.parameters.stim_int;     % Size of the window on either side of the stimulus in sec
win_start=NaN(size(iONr,1),expmt.nTracks);
win_stop=NaN(size(iOFFr,1),expmt.nTracks);
tElapsed = cumsum(expmt.Time.data);

%
% Start by finding tStamps
for i=1:expmt.nTracks
    disp(i)
    tStamps=tElapsed(iONr(iONc==i));
    tON=tStamps-win_sz;
    tOFF=tStamps+win_sz;
    [v,start] = min(abs(repmat(tElapsed,1,length(tON))-repmat(tON',size(tElapsed,1),1))); 
    [v,stop] = min(abs(repmat(tElapsed,1,length(tON))-repmat(tOFF',size(tElapsed,1),1)));
    win_start(1:length(tStamps),i)=start;
    win_stop(1:length(tStamps),i)=stop;
    clearvars start stop tON tOFF tStamps
end

clearvars tElapsed iONc iONr iOFFc iOFFr

win_start(sum(~isnan(win_start),2)==0,:)=[];
win_stop(sum(~isnan(win_stop),2)==0,:)=[];
nPts=max(max(win_stop-win_start));
da=NaN(nPts,size(win_start,1),expmt.nTracks);

turning=expmt.Orientation.data;
turning=diff(turning');
%turning(trackProps.speed<0.7) = 0;
%turning = diff(turning);
turning = [zeros(1,size(turning,2));turning];
turning(turning>90) = turning(turning>90) - 180;
turning(turning<-90) = turning(turning<-90) + 180;
turning(expmt.Texture.data & expmt.StimStatus.data)=-turning(expmt.Texture.data & expmt.StimStatus.data);

tmp_tdist = turning;
tmp_tdist(~expmt.StimStatus.data)=NaN;
tmp_r = nansum(tmp_tdist);
tmp_tot = nansum(abs(tmp_tdist));
opto_bias = tmp_r./tmp_tot;

t0=round(nPts/2);
off_spd=NaN(expmt.nTracks,1);
on_spd=NaN(expmt.nTracks,1);


for i=1:expmt.nTracks
    
    off_spd(i)=nanmean(trackProps.speed(~expmt.StimStatus.data(:,i),i));
    on_spd(i)=nanmean(trackProps.speed(expmt.StimStatus.data(:,i),i));
    
    % Integrate change in heading angle over the entire stimulus bout
    for j=1:sum(~isnan(win_start(:,i)))
        tmpTurn=turning(win_start(j,i):win_stop(j,i),i);
        %tmpTurn(tmpTurn > pi*0.95 | tmpTurn < -pi*0.95)=0;
        if ~isempty(tmpTurn)
            tmpTurn=interp1(1:length(tmpTurn),tmpTurn,linspace(1,length(tmpTurn),nPts));
            if nanmean(trackProps.speed(win_start(j,i):win_stop(j,i),i))>0.1
            da(1:t0,j,i)=cumsum(tmpTurn(1:t0));
            da(t0+1:end,j,i)=cumsum(tmpTurn(t0+1:end));
            end
        end
    end
end



active=nTrials>2;

%% Generate plots

figure();
optoplots=squeeze(nanmedian(da,2));
clearvars da tmpTurn win_start win_stop
[v,p]=sort(mean(optoplots(t0+1:end,:)));
p_optoplots=optoplots(:,p);
%p_cormap=cormap(p,:);
hold on
for i=1:expmt.nTracks
    plot(smooth(p_optoplots(:,i),20),'Color',rand(1,3),'linewidth',2);
end

axis([0 size(optoplots,1) min(min(optoplots)) max(max(optoplots))]);
hold on
plot(nanmean(optoplots(:,active),2),'k-','LineWidth',3);
plot([t0 t0],[min(min(optoplots)) max(max(optoplots))],'k--','LineWidth',2);
hold off
set(gca,'Xtick',linspace(1,size(optoplots,1),7),'XtickLabel',round(linspace(-win_sz,win_sz,7)*10)/10);
ylabel('cumulative d\theta (rad)')
xlabel('time to stimulus onset')
title('Change in heading direction before and after optomotor stimulus')


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