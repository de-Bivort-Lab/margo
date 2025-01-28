function [varargout] = extractOptoTraces(include,expmt)

dec_scale = 1;  % factor by which to decimate the data

% Find indices of stimulus ON/OFF transitions
[~,iOFFc]=find(diff(include)==-1);
nTrials=NaN(expmt.meta.num_traces,1);

for i=1:expmt.meta.num_traces
    nTrials(i)=sum(iOFFc==i);           % number of stim presentations for each animal
end

[iONr,iONc]=find(diff(include)==1);     % OFF to ON
iONr=iONr+1;
[iOFFr,~]=find(diff(include)==-1);      % ON to OFF
iOFFr=iOFFr+1;

iONr = ceil(iONr./dec_scale);
iOFFr = ceil(iOFFr./dec_scale);

% Stimulus triggered averaging of each stimulus bout
win_sz = expmt.parameters.stim_int;                         % Size of the window on either side of the stimulus in sec
win_start=NaN(size(iONr,1),expmt.meta.num_traces);
win_stop=NaN(size(iOFFr,1),expmt.meta.num_traces);
tElapsed = cumsum(expmt.data.time.raw());                         % time elapsed @ each frame
tElapsed = tElapsed(mod(1:length(tElapsed),dec_scale)==0);
search_win = round(win_sz/nanFilteredMean(expmt.data.time.raw())*1.5);    % window around stim Off->On index to search for best tStamp


% Start by finding tStamps win_sz on either side of stim ON->OFF index
for i=1:expmt.meta.num_traces
    
    idx = iONr(iONc==i);                % frame indices of transitions for current fly
    idx(idx>length(tElapsed)) = length(tElapsed);
    tStamps=tElapsed(idx);              % tStamps of stim OFF -> ON
    tON=tStamps-win_sz;                 % tStamps of edges of the stim-centered window
    tOFF=tStamps+win_sz;
    
    % find frames with the closest matching tStamps for the window edges
    lbs = idx - search_win;             % narrow search to nearby indices to speed up search
    lbs(lbs<1) = 1;
    ubs = idx + search_win;
    ubs(ubs>length(tElapsed)) = length(tElapsed);

    for j = 1:length(lbs)
        
        [v,start] = min(abs(tElapsed(lbs(j):ubs(j)) - tON(j)));     % time diff to window start
        [v,stop] = min(abs(tElapsed(lbs(j):ubs(j)) - tOFF(j)));     % time diff to window stop
        win_start(j,i)=start + lbs(j) - 1;
        win_stop(j,i)=stop + lbs(j) - 1;
        
    end
    
    clearvars start stop tON tOFF tStamps
end

clearvars tElapsed iONc iONr iOFFc iOFFr
win_start(sum(~isnan(win_start),2)==0,:)=[];
win_stop(sum(~isnan(win_stop),2)==0,:)=[];

nPts=max(max(win_stop-win_start));                  % max number of frames out of all windows
cumang=NaN(nPts,size(win_start,1),expmt.meta.num_traces);   % intialize cumulative change in angle placeholder

% get change in angle at each frame
turning = expmt.data.orientation.raw();
turning = turning(mod(1:length(turning),dec_scale)==0,:);
turning = diff(turning);
turning = [zeros(1,size(turning,2));turning];       % pad first frame with zero to equal total frame number

% shift all values to be between -180 and 180 (from 360->0 single frame
% artifacts), and adjust all values to be with respect to the stimulus such
% that all turns in the direction of the stimulus rotation are negative
tex = expmt.data.Texture.raw(...
    mod(1:length(expmt.data.Texture.raw()),dec_scale)==0,:);
inc = include(mod(1:length(include),dec_scale)==0,:);
turning(turning>90) = turning(turning>90) - 180;    
turning(turning<-90) = turning(turning<-90) + 180;
turning(tex&inc)=-turning(tex&inc);

tdist = turning;
tdist(~inc)=NaN;
tmp_r = sum(tdist, 'omitnan');
tmp_tot = sum(abs(tdist), 'omitnan');
avg_index = tmp_r./tmp_tot;
total_dist=NaN(size(win_start,1),expmt.meta.num_traces);
stimdir_dist=NaN(size(win_start,1),expmt.meta.num_traces);


t0=round(nPts/2);
off_spd=NaN(expmt.meta.num_traces,1);
on_spd=NaN(expmt.meta.num_traces,1);


for i=1:expmt.meta.num_traces
    
    off_spd(i)=nanFilteredMean(expmt.data.speed.raw(~inc(:,i),i));
    on_spd(i)=nanFilteredMean(expmt.data.speed.raw(inc(:,i),i));
    
    % Integrate change in heading angle over the entire stimulus bout
    for j=1:sum(~isnan(win_start(:,i)))
        
        tmpTurn=turning(win_start(j,i):win_stop(j,i),i);
        tmp_tdist=tdist(win_start(j,i):win_stop(j,i),i);
        stimdir_dist(j,i) = sum(tmp_tdist, 'omitnan');
        total_dist(j,i) = sum(abs(tmp_tdist), 'omitnan');

        if ~isempty(tmpTurn)
            tmpTurn=interp1(1:length(tmpTurn),tmpTurn,linspace(1,length(tmpTurn),nPts));
            if nanFilteredMean(expmt.data.speed.raw(win_start(j,i):win_stop(j,i),i))>0.1
            cumang(1:t0,j,i)=cumsum(tmpTurn(1:t0));
            cumang(t0+1:end,j,i)=cumsum(tmpTurn(t0+1:end));
            end
        end
    end
end

for i = 1:nargout
    switch i
        case 1, varargout{i}=cumang;
        case 2, varargout{i}=avg_index;
        case 3, varargout{i}=nTrials;
        case 4, varargout{i}=stimdir_dist;
        case 5, varargout{i}=total_dist;
    end
end



%{
function [cumang,opto_index]=getOptoIndex(t,inc,wst,wsp,spd,nPts,t0)

off_spd = nanFilteredMean(spd{:}(~inc{:}));
on_spd = nanFilteredMean(spd{:}(inc{:}));

idx = num2cell([wst{:}(~isnan(wst{:})) wsp{:}(~isnan(wsp{:}))],2);
[cumang,opto_index] = arrayfun(@(k) extractSingleBout(k,t,spd,nPts,t0),...
    idx,'UniformOutput',false);
opto_index = [opto_index{:}];


% Integrate change in heading angle over the entire stimulus bout
function [cumang,opto_index] = extractSingleBout(idx,t,spd,nPts,t0)

tmp_t=t{:}(idx{:}(1):idx{:}(2));

if ~isempty(tmp_t)
    
    tmp_t=interp1(1:length(tmp_t),tmp_t,linspace(1,length(tmp_t),nPts));
    cumang = NaN(size(tmp_t));
    
    if nanFilteredMean(spd{:}(idx{:}(1):idx{:}(2)))>0.1
        cumang(1:t0)=cumsum(tmp_t(1:t0));
        cumang(t0+1:end)=cumsum(tmp_t(t0+1:end));
        tmp_r = sum(tmp_t, 'omitnan');
        tmp_tot = sum(abs(tmp_t), 'omitnan');
        opto_index = tmp_r./tmp_tot;
    else
        cumang = [];
        opto_index = NaN;
    end
end
%}





