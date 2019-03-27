function togglePanels(gui_handles,state,keywords)

% retrieve all panels
panels = findall(gui_handles.gui_fig,'Type','uipanel');
panel_tags = get(panels,'Tag');

% find panels with matching keywords in tag
has_match = false(numel(panel_tags),1);
for i=1:numel(panel_tags)
    has_match(i) = any(cellfun(@(kw) any(strfind(panel_tags{i},kw)), keywords));
end

% toggle ctls with enable property to STATE
panel_ctls = get(panels(has_match),'Children');
panel_ctls = cat(1,panel_ctls{:});
set(findall(panel_ctls,'-property','Enable'),'Enable',state);