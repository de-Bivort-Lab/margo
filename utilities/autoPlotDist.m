function [fig_handle, bins] = autoPlotDist(data, filter, varargin)

ah = [];
plot_opts = {'LineWidth'; 2};
for i=1:numel(varargin)
    arg = varargin{i};
    if any(ishghandle(arg)) && strcmpi(arg.Type,'axes')
        hold on;
        ah = arg;
    end
    if ischar(arg)
        switch arg
            case 'PlotOptions'
                i=i+1;
                plot_opts = varargin{i};
        end
    end
end

if ~isempty(ah)
    fh = ah.Parent;
else
    fh = figure();
    ah = gca;
end

% Histogram for stimulus ON period
if min(data) >= 0
    mm = nanmean(data) + nanstd(data)*4;
    inc = (10^(ceil(log10(mm))-1));
    ub = ceil(mm/inc)*inc;
    lb = (nanmean(data) - nanstd(data)*4);
    lb = floor(lb/inc)*inc;
    bins = 0:inc:ub;
else
    lb = -1;
    ub = 1;
    bins = -1:0.2:1;
end

data = data(filter,:);
[kde, x] = ksdensity(data, linspace(lb,ub,100));


lh = plot(x, kde,plot_opts{:});
all_lines = findobj(ah,'-depth',1,'Type','Line');
xdata = arrayfun(@(l) l.XData, all_lines, 'UniformOutput', false);
xdata = cat(2,xdata{:});
ydata = arrayfun(@(l) l.YData, all_lines, 'UniformOutput', false);
ydata = cat(2,ydata{:});
set(ah, 'Xtick', bins, 'XLim', [min(xdata) max(xdata)],...
    'Ylim', [0 max(ydata)*1.1], 'TickLength', [0 0]);
ylabel('probability density');
% add bs and obs patch
x = [x(1) x];
kde = [0 kde];
vx = [x x(end) x(1)];
vy = [kde 0 kde(1)];
ph = patch(vx,vy,lh.Color,'FaceAlpha',0.3);
uistack(ph,'bottom');
fig_handle = fh;
hold off;
