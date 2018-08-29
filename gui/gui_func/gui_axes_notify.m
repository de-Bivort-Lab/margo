function note_handles = gui_axes_notify(ax,msg)


c = [ax.XLim(2)*0.5 ax.YLim(2)*0.035];
th = text(ax,c(1),c(2),msg,'color','k','HitTest','off',...
    'HorizontalAlignment','center','FontWeight','bold');
th.Units = 'normalized';

tsz = th.Extent;
dy = 0.975 - sum(tsz([2 4]));
th.Position(2) = th.Position(2) + dy;

% get patch vertices
th.Units = 'data';
x = [th.Extent(1) sum(th.Extent([1 3]))];
y = [th.Extent(2) diff(th.Extent([4 2]))];
vx = [x(1) x(1) x(2) x(2) x(1)] + 0.1.*[-1 -1 1 1 -1];
vy = [y(1) y(2) y(2) y(1) y(1)] + 0.1.*[-1 1 1 -1 -1];

% draw new patch
ph = patch(ax,'XData',vx,'YData',vy,'FaceColor',[1 1 1],...
    'FaceAlpha',0.5,'EdgeColor','none','HitTest','off');
uistack(ph,'down');

note_handles = {ph;th};

