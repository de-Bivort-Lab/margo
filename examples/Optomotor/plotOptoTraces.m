function plotOptoTraces(cumang,active,parameters,varargin)

win_sz = parameters.stim_int;

for i = 1:length(varargin)
    if ischar(varargin{i})
    switch varargin{i}
        case 'title'
            titstr = varargin{i+1};
        case 'Ylim'
            ylimit = varargin{i+1};
    end
    end
end

optoplots=squeeze(nanFilteredMedian(cumang(:,:,:),2));
t0 = round(length(optoplots)/2);
tOFF = t0 + round((parameters.stim_duration/win_sz)*size(optoplots,1)/2);
nTracks = size(optoplots,2);

hold on
for i=1:nTracks
    if active(i)
        plot(1:t0-1,meanFilter(optoplots(1:t0-1,i),20),'Color',rand(1,3),'linewidth',2);
        plot(t0+1:length(optoplots),meanFilter(optoplots(t0+1:end,i),20),'Color',rand(1,3),'linewidth',2);
    end
end

hold on
plot(1:t0-1,nanFilteredMean(optoplots(1:t0-1,active),2),'k-','LineWidth',3);
plot(t0+1:length(optoplots),nanFilteredMean(optoplots(t0+1:end,active),2),'k-','LineWidth',4);
plot([t0 t0],[min(min(optoplots)) max(max(optoplots))],'k--','LineWidth',2);
hold off
set(gca,'Xtick',linspace(1,size(optoplots,1),7),'XtickLabel',round(linspace(-win_sz,win_sz,7)*10)/10);
ylabel('cumulative d\theta (rad)')
xlabel('time to stimulus onset')

if exist('titstr','var')
    title(titstr);
else
    title('Change in heading direction before and after optomotor stimulus');
end

if exist('ylimit','var')
    axis([0 size(optoplots,1) ylimit(1) ylimit(2)]);
else
    axis([0 size(optoplots,1) min(min(optoplots)) max(max(optoplots))]);
end

hold on
x = [t0 t0 tOFF tOFF];
y=ylim;
y = [y(2) y(1) y(1) y(2)];
ph=patch(x,y,[0.9 0.9 0.9]);
uistack(ph,'bottom');
hold off