function resize_fig_bounds(fig)

uipanels = findall(fig,'Type','uipanel');

set(uipanels,'Units','points');
corners = arrayfun(@(p) p.Position, uipanels, 'UniformOutput', false);
corners = cat(1,corners{:});
corners(:,3:4) = corners(:,1:2) + corners(:,3:4);

fig.Units = 'points';
fig.Position(3) = max(corners(:,3));

