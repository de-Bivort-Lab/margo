function note_handles = gui_axes_notify(ax,msg)

c = [ax.XLim(2)*0.5 ax.YLim(2)*0.035];
th = text(ax,c(1),c(2),msg,'color','m',...
    'HorizontalAlignment','center','FontWeight','bold');

if ~iscell(msg)
    msg = {msg};
end

% get patch vertices
nchar = max(cellfun(@numel,msg));
dx = (nchar*th.FontSize*0.9)/2;
dy = (numel(msg)*th.FontSize+40)/2;
vx = c(1)+dx.*[-1 -1 1 1 -1];
vy = c(2)+dy.*[-1 1 1 -1 -1];

% draw new patch
ph = patch(ax,'XData',vx,'YData',vy,'FaceColor',[1 1 1],...
    'FaceAlpha',0.35,'EdgeColor','none');
uistack(ph,'down');

note_handles = {ph;th};

