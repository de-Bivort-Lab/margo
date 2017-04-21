function [cumang,opto_bias,nTrials] = extractOptoTraces(include,expmt,speed)

[iOFFr,iOFFc]=find(diff(include)==-1);
iOFFr=iOFFr+1;
nTrials=NaN(expmt.nTracks,1);

for i=1:expmt.nTracks
    nTrials(i)=sum(iOFFc==i);
end

[iONr,iONc]=find(diff(include)==1);
iONr=iONr+1;
[iOFFr,iOFFc]=find(diff(include)==-1);
iOFFr=iOFFr+1;

% Stimulus triggered averaging of each stimulus bout
win_sz = expmt.parameters.stim_int;     % Size of the window on either side of the stimulus in sec
win_start=NaN(size(iONr,1),expmt.nTracks);
win_stop=NaN(size(iOFFr,1),expmt.nTracks);
tElapsed = cumsum(expmt.Time.data);
search_win = round(win_sz/nanmean(expmt.Time.data)*1.5);


% Start by finding tStamps
for i=1:expmt.nTracks
    
    idx = iONr(iONc==i);
    tStamps=tElapsed(idx);
    tON=tStamps-win_sz;
    tOFF=tStamps+win_sz;
    lbs = idx - search_win;
    lbs(lbs<1) = 1;
    ubs = idx + search_win;
    ubs(ubs>length(tElapsed)) = length(tElapsed);
    
    for j = 1:length(lbs)
        
        [v,start] = min(abs(tElapsed(lbs(j):ubs(j)) - tON(j))); 
        [v,stop] = min(abs(tElapsed(lbs(j):ubs(j)) - tOFF(j)));
        win_start(j,i)=start + lbs(j) - 1;
        win_stop(j,i)=stop + lbs(j) - 1;
        
    end
    
    clearvars start stop tON tOFF tStamps
end

clearvars tElapsed iONc iONr iOFFc iOFFr

win_start(sum(~isnan(win_start),2)==0,:)=[];
win_stop(sum(~isnan(win_stop),2)==0,:)=[];
nPts=max(max(win_stop-win_start));
cumang=NaN(nPts,size(win_start,1),expmt.nTracks);

turning=expmt.Orientation.data;
turning=diff(turning);
turning = [zeros(1,size(turning,2));turning];
turning(turning>90) = turning(turning>90) - 180;
turning(turning<-90) = turning(turning<-90) + 180;
turning(expmt.Texture.data&include)=-turning(expmt.Texture.data&include);

tmp_tdist = turning;
tmp_tdist(~include)=NaN;
tmp_r = nansum(tmp_tdist);
tmp_tot = nansum(abs(tmp_tdist));
opto_bias = tmp_r./tmp_tot;

t0=round(nPts/2);
off_spd=NaN(expmt.nTracks,1);
on_spd=NaN(expmt.nTracks,1);


for i=1:expmt.nTracks
    
    off_spd(i)=nanmean(speed(~include(:,i),i));
    on_spd(i)=nanmean(speed(include(:,i),i));
    
    % Integrate change in heading angle over the entire stimulus bout
    for j=1:sum(~isnan(win_start(:,i)))
        tmpTurn=turning(win_start(j,i):win_stop(j,i),i);
        %tmpTurn(tmpTurn > pi*0.95 | tmpTurn < -pi*0.95)=0;
        if ~isempty(tmpTurn)
            tmpTurn=interp1(1:length(tmpTurn),tmpTurn,linspace(1,length(tmpTurn),nPts));
            if nanmean(speed(win_start(j,i):win_stop(j,i),i))>0.1
            cumang(1:t0,j,i)=cumsum(tmpTurn(1:t0));
            cumang(t0+1:end,j,i)=cumsum(tmpTurn(t0+1:end));
            end
        end
    end
end

