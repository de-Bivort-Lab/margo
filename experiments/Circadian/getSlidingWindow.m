function varargout = getSlidingWindow(expmt,f,win_sz,stp_sz,varargin)

% extracts time averaged trace of expmt field (f) by sliding a window of length
% win_sz over the data at intervals of stp_sz from the data

%% parse inputs

fh = str2func('nanmean');

for i = 1:length(varargin)
    
    arg = varargin{i};
    
    if ischar(arg)
    	switch arg
            case 'Decimate'
                i=i+1;
                dec_fac = varargin{i};
            case 'Func'
                i=i+1;
                fh = str2func(varargin{i});
        end
    end
end


%%

first_idx = round(length(expmt.(f).data)/win_sz)+1;
r = floor(win_sz/2);
idx = first_idx:stp_sz:length(expmt.(f).data);


% perform the operation
win_dat = NaN(length(idx),expmt.nTracks);
for i = 1:expmt.nTracks
    disp(['sliding window ' num2str(i) ' out of ' num2str(expmt.nTracks)]);
    win_dat(:,i) = arrayfun(@(k) slide_win(expmt.(f).data(:,i),k,r,fh), idx);
end



% assign outputs
for i = 1:nargout
    switch i
        case 1, varargout(i) = {win_dat};
        case 2, varargout(i) = {idx};
        case 3, varargout(i) = {r};
    end
end


%{
% Slide window over speed data
interval_step_num=round(interval/stepSize);
plotData=zeros(length(samplingIndex)-interval_step_num,numFlies);
n=length(samplingIndex)-interval_step_num;
f=round(n/100);
for i=1:n
    tic
    plotData(i,:)=nanmean(speed(samplingIndex(i):samplingIndex(i+interval_step_num)-1,:));
    if mod(i,f)==0
    disp([num2str(((numSteps-i)*toc)*60) ' estimated min remaining']);
    end
end

%%
% Find indices from sampling data closest to motor transitions
mi1=NaN(size(motorON));
mi2=NaN(size(motorOFF));

for i=1:length(motorON);
    d=abs(samplingIndex-motorON(i));
    [v,j]=min(d);
    mi1(i)=j;
    d=abs(samplingIndex-motorOFF(i));
    [v,j]=min(d);
    mi2(i)=j;
end   


%% Plot population mean over time and plot
meanPlot=nanmean(plotData,2);
meanPlot(1)=[];

plot(meanPlot,'r');
hold on
for i=1:length(mi2);
    plot([mi1(i) mi1(i)],[0 max(meanPlot)+1],'Color',[0 1 1],'Linewidth',2);
end

activityTrace = findobj(gca, 'Color', 'r');
uistack(activityTrace, 'top')

%%
plotData(1,:)=[];

%{
for h=1:4
hold on
figure();
    for i=h*24-23:h*24
      subplot(6,4,mod(i-1,24)+1);
      hold on
      plot(smooth(plotData(:,i),ceil(length(plotData)/50)),'r');
        for j=1:length(mi2);
            hold on
            plot([mi1(j) mi1(j)],[0 2],'Color',[0 0 1],'Linewidth',1);
        end
      axis([0 size(plotData,1) 0 2]);
    end
end
%}
circData.tElapsed=tElapsed;
circData.activeFlies=nanmean(speed)>0.01;
circData.numActive=sum(circData.activeFlies);
circData.speed=speed;
circData.motorON=motorON;
circData.motorOFF=motorOFF;
%}


function out = slide_win(dat,idx,r,fh)

    out = feval(fh,dat(idx-r:idx+1,:));







