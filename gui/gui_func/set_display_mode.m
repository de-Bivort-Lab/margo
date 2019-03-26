function set_display_mode(disp_menu_handle,mode,varargin)

disable = false;
for i=1:numel(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            case 'Disable'
                i = i+1;
                disable = varargin{i};
        end
    end
end

% switch the display mode and gui menu items
disp_menu_items = get(disp_menu_handle,'Children');
disp_menu_labels = regexp(get(disp_menu_items,'Label'),'^\w*','match');
disp_menu_labels = cat(1,disp_menu_labels{:});
mode_idx = find(strcmpi(disp_menu_labels,mode));

if isempty(mode_idx)
    return
end

if disable
    disp_menu_items(mode_idx).Checked = 'off';
    disp_menu_items(mode_idx).Enable = 'off';
    raw_idx = find(strcmpi(disp_menu_labels,'raw'));
    disp_menu_items(raw_idx).Enable = 'on';
    disp_menu_items(raw_idx).Checked = 'on';
    disp_menu_handle.UserData = 'raw';
    return
end

set(disp_menu_items,'Checked','off');
disp_menu_items(mode_idx).Checked = 'on';
disp_menu_items(mode_idx).Enable = 'on';
disp_menu_handle.UserData = mode;