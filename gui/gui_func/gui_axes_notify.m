function note_handles = gui_axes_notify(ax,msg,varargin)

% set default characteristics and parse inputs
color = 'k';
fontsize = 12;
position = [ax.XLim(2)*0.5 ax.YLim(2)*0.035];
align = 'center';
alpha = 0.75;
for i=1:numel(varargin)
    arg = varargin{i};
    if ischar(arg)
        switch arg
            case 'color'
                i=i+1;
                color = varargin{i};
            case 'FontSize'
                i=i+1;
                fontsize = varargin{i};
            case 'Position'
                i=i+1;
                position = varargin{i};
            case 'Alignment'
                i=i+1;
                align = varargin{i};
            case 'FaceAlpha'
                i=i+1;
                alpha = varargin{i};
        end
    end
end

th = text(position(1),position(2),msg,'color',color,'Parent',ax,'HitTest','off',...
    'HorizontalAlignment',align,'FontWeight','bold','FontSize',fontsize);
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
ph = patch(ax,'XData',vx,'YData',vy,'FaceColor',[1 1 1],'Parent',ax,...
    'FaceAlpha',alpha,'EdgeColor','none','HitTest','off');
uistack(ph,'down');

note_handles = {ph;th};

