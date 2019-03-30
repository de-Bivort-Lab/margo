function serial_COM_settings_subgui(expmt)

% get all COM devices
com_devices = expmt.hardware.COM.devices;

if all(cellfun(@isempty, com_devices))
   errordlg('No serial COM devices detected'); 
   return
end

% get port names
com_ports = cellfun(@(dev) dev.Port, com_devices, 'UniformOutput', false);

% get com device status
expmt.hardware.COM.status = ...
    cellfun(@(dev) dev.status, com_devices, 'UniformOutput', false);

% set the default device to AUX com (if selected) or the first available port
if ~isempty(expmt.hardware.COM.aux)
    device_idx = find(strcmpi(com_ports,expmt.hardware.COM.aux.Port));
    default_device = expmt.hardware.COM.aux;
else
    device_idx = find(~cellfun(@isempty, com_devices),1);
    default_device = com_devices{device_idx};
end

% load saved settings for the device
[default_device, expmt.hardware.COM.settings, prop_names] = ...
    load_com_settings(default_device, device_idx, expmt.hardware.COM.settings);

%% Determine the size of the UI based on how many elements need to be populated
nControls = 0;
del = [];
info = propinfo(default_device);
for i = 1:length(prop_names)
    field = info.(prop_names{i});
    if (strcmp(field.Constraint,'bounded') && numel(default_device.(prop_names{i}))<2) || strcmp(field.Constraint,'enum')
        nControls = nControls + 1;
    elseif (strcmp(field.Constraint,'none')) 
        nControls = nControls + 1;
    else
        del = [del i];
    end
end

prop_names(del) = [];                % remove non-addressable properties
nColumns = ceil(nControls/12);   % set column number
ctls_per_column = ceil(nControls/nColumns);

%% get units of reference controls to populate UI

gui_fig = findall(groot,'Name','margo');
ref_slider = findall(gui_fig,'Tag','ROI_thresh_slider');
ref_label = findall(gui_fig,'Tag','ROI_thresh_label');
ref_edit = findall(gui_fig,'Tag','edit_IR_intensity');
ref_popup = findall(gui_fig,'Tag','microcontroller_popupmenu');
slider_w = ref_slider.Position(3);
edit_h = ref_edit.Position(4);
edit_w = ref_edit.Position(3)*1.2;
slider_h = edit_h;
menu_h = ref_popup.Position(4);
menu_w = ref_popup.Position(3);
label_h = ref_label.Position(4);
w_per_char = ref_label.Position(3)/numel(ref_label.String)*1.4;
hspacer = ref_edit.Position(3);
pad = edit_h*2;
panel_h = menu_h + pad*2;
current_height = 0;

%%

%  Create and then hide the UI as it is being constructed.
fpos = gui_fig.Position;
col_w = slider_w + edit_w*2 + hspacer;
fig_size = [fpos(1:2)+2 col_w*nColumns (edit_h+pad)*ctls_per_column+pad+panel_h];

% initialize the figure window (disable toolbar)
f = figure('Visible','on','Units','characters',...
    'Position',fig_size,'Name','COM Settings',...
    'CloseRequestFcn',@com_settings_subguiCloseRequestFcn);
set(f,'MenuBar','none','Toolbar','none','resize','off','NumberTitle','off');

% initialize device selection and settings UI panels
select_device_panel = uipanel('Parent',f,'Units','characters',...
    'Position',[0, fig_size(4)-panel_h, fig_size(3) panel_h],...
    'Title','Selected Device');
device_settings_panel = uipanel('Parent',f,'Units','characters',...
    'Position',[0, 0, fig_size(3) fig_size(4)-panel_h],...
    'Title','Device Settings');
fh = device_settings_panel.Position(4);

% initialize the device selection popupmenu
select_device_menu = uicontrol('Style','popupmenu','String',com_ports,...
        'Units','characters','Parent',select_device_panel,'Position',...
        [hspacer, panel_h-menu_h-label_h-pad, menu_w, menu_h],...
        'FontUnits','normalized','Callback',@select_device_Callback);
select_device_label = uicontrol('Style','text','String','Port',...
    'Units','characters','Parent',select_device_panel,'Position',...
    [hspacer, sum(select_device_menu.Position([2 4]))+label_h/4, ...
    4*w_per_char, label_h],'FontUnits','normalized','HorizontalAlignment','left');
select_device_menu.Value = device_idx;

uival(1) = text(0,0,'');
ct = 0;

for i = 1:length(prop_names)
    
    field = info.(prop_names{i});
    if strcmp(field.Constraint,'bounded')
        current_height = current_height + edit_h + pad;
        ct = ct + 1;

        uival(i) = uicontrol('Style','edit','string',num2str(default_device.(prop_names{i})),...
            'Units','characters','Parent',device_settings_panel,'Position',...
            [hspacer + col_w*floor((i-1)/ctls_per_column), (fh-current_height), edit_w, edit_h],...
            'Tag',prop_names{i},'FontUnits','normalized','HorizontalAlignment','center','Callback',@edit_Callback);
        
        uival(i).UserData = i;
        uictl(i) = uicontrol('Style','slider','Min',field.ConstraintValue(1),...
            'Max',field.ConstraintValue(2),'value',default_device.(prop_names{i}),...
           'Units','characters','Parent',device_settings_panel,'Position',...
           [sum(uival(i).Position([1,3]))+hspacer/2,...
           (fh-current_height), slider_w, slider_h],...
           'Tag',prop_names{i},'FontUnits','normalized','Callback',@slider_Callback);
       
        uictl(i).UserData = i;
        uilbl(i) = uicontrol('Style','text','string',prop_names{i},...
            'Units','characters','Parent',device_settings_panel,'Position',...
            [hspacer+col_w*floor((i-1)/ctls_per_column) sum(uictl(i).Position([2 4]))+label_h/4 ...
            numel(prop_names{i})*w_per_char label_h],...
            'FontUnits','normalized','HorizontalAlignment','left');
        
        bound1 = sprintf('%0.2f',field.ConstraintValue(2));
        uicontrol('Style','text','string',bound1,...
            'Units','characters','Parent',device_settings_panel,'Position',...
            [sum(uictl(i).Position([1 3]))-numel(bound1)*w_per_char,...
            sum(uictl(i).Position([2 4]))++label_h/4, numel(bound1)*w_per_char, label_h],...
            'FontUnits','normalized','HorizontalAlignment','right');
        
        bound2 = sprintf('%0.2f',field.ConstraintValue(1));
        uicontrol('Style','text','string',bound2,...
            'Units','characters','Parent',device_settings_panel,'Position',...
            [uictl(i).Position(1), sum(uictl(i).Position([2 4]))+label_h/4, ...
            numel(bound2)*w_per_char, label_h],...
            'FontUnits','normalized','HorizontalAlignment','left');      

    end
    
    if strcmp(field.Constraint,'none')
        current_height = current_height + edit_h + pad;
        ct = ct + 1;

        uictl(i) = uicontrol('Style','edit','string',num2str(default_device.(prop_names{i})),...
            'Units','characters','Parent',device_settings_panel,'Position',...
            [hspacer + col_w*floor((i-1)/ctls_per_column), (fh-current_height), edit_w, edit_h],...
            'FontUnits','normalized','HorizontalAlignment','center',...
            'Tag',prop_names{i},'Callback',@edit_Callback);
        
        uictl(i).UserData = i;
        uilbl(i) = uicontrol('Style','text','string',prop_names{i},...
            'Units','characters','Parent',device_settings_panel,'Position',...
            [hspacer+col_w*floor((i-1)/ctls_per_column) sum(uictl(i).Position([2 4]))+label_h/4 ...
            numel(prop_names{i})*w_per_char label_h],...
            'FontUnits','normalized','HorizontalAlignment','left');
    end

    if strcmp(field.Constraint,'enum')
        ct = ct + 1;
        current_height = current_height + menu_h + pad;
        uictl(i) = uicontrol('Style','popupmenu','string',field.ConstraintValue,...
                'Units','characters','Parent',device_settings_panel,'Position',...
                [col_w*floor((i-1)/ctls_per_column)+hspacer, fh-current_height, menu_w, menu_h],...
                'FontUnits','normalized','Tag',prop_names{i},'Callback',@popupmenu_Callback);
        uictl(i).UserData = i;
        uilbl(i) = uicontrol('Style','text','String',prop_names{i},...
            'Units','characters','Parent',device_settings_panel,'Position',...
            [hspacer+col_w*floor((i-1)/ctls_per_column), sum(uictl(i).Position([2 4]))++label_h/4, ...
            numel(prop_names{i})*w_per_char, label_h],...
            'FontUnits','normalized','HorizontalAlignment','left');
        
        % find current value from default_device
        str_list = get(uictl(i),'string');
        cur_val = 1;
        for j = 1:length(str_list)
            if strcmp(default_device.(prop_names{i}),str_list{j})
            cur_val = j;
            end
        end
        
        set(uictl(i),'value',cur_val);

    end
    
    % reset current height to zero for new column
    if ~mod(i,ctls_per_column)
        current_height = 0;
    end

    guiData.uictl = uictl;
    guiData.uival = uival;
    guiData.names = prop_names;
    guiData.idx = device_idx;
    guiData.expmt = expmt;
    guiData.COM_src = default_device;
    set(f,'UserData',guiData);

end
    
end

function slider_Callback(src,event)

pf = src.Parent.Parent;     % get parent fig handle
data = pf.UserData;         % retrieve data stored in fig handle
names = data.names;
vals= data.uival;

% update coupled UI component
set(vals(src.UserData),'string',sprintf('%0.2f',src.Value));

% update camera source and settings
data.expmt.hardware.COM.settings{data.idx}.(names{src.UserData}) = get(src,'value');
data.COM_src.(names{src.UserData}) = get(src,'value');
set(pf,'UserData',data);

end

function popupmenu_Callback(src,event)

pf = src.Parent.Parent;         % get parent fig handle
data = pf.UserData;             % retrieve data stored in fig handle
names = data.names;
str_list = src.String;

% update camera source and settings with current value of s_obj.string
info = propinfo(data.COM_src);
if isfield(info,names{src.UserData})
    switch info.(names{src.UserData}).Type
        case 'double'
            data.COM_src.(names{src.UserData}) = str2double(str_list{src.Value});
            data.expmt.hardware.COM.settings{data.idx}.(names{src.UserData})...
                = str2double(str_list{src.Value});
        case 'string'
            data.COM_src.(names{src.UserData}) = str_list{src.Value};
            data.expmt.hardware.COM.settings{data.idx}.(names{src.UserData})...
                = str_list{get(src,'value')};
    end
end

set(pf,'UserData',data);

end

function edit_Callback(src,event)

pf = src.Parent.Parent;     % get parent fig and stored data
data = pf.UserData;
names = data.names;
ctls = data.uictl;

% update camera source and settings with current value of s_obj.string
val = str2double(get(src,'string'));
if isnan(val)
   val = src.String; 
end
info = propinfo(data.COM_src);
if isfield(info,(names{src.UserData})) && ...
        isfield(info.(names{src.UserData}),'Constraint') && ...
         strcmpi(info.(names{src.UserData}).Constraint,'bounded')
    if val < info.(names{src.UserData}).ConstraintValue(1)
        val = info.(names{src.UserData}).ConstraintValue(1);
    elseif val > info.(names{src.UserData}).ConstraintValue(2)
        val = info.(names{src.UserData}).ConstraintValue(2);
    end
end

% update coupled UI component Experiment Data
if ischar(val)
    set(ctls(src.UserData),'String',val);
else
    set(ctls(src.UserData),'value',val);
    src.String = sprintf('%i',val);
end
data.expmt.hardware.COM.settings{data.idx}.(names{src.UserData}) = val;  
data.COM_src.(names{src.UserData}) = val;
set(pf,'UserData',data); 
    
end


function select_device_Callback(src,event)

% get expmt data
pf = src.Parent.Parent;
expmt = pf.UserData.expmt;

% disable all device settings ctls
settings_uipanel = findall(pf,'Title','Device Settings','Type','uipanel');
settings_ctls = findall(settings_uipanel,'-property','Enable');
set(settings_ctls,'Enable','off');

% load saved settings for the device
dev = expmt.hardware.COM.devices{src.Value};
[dev, settings, props] = load_com_settings(dev, src.Value, expmt.hardware.COM.settings);
pf.UserData.COM_src = dev;
pf.UserData.idx = src.Value;
expmt.hardware.COM.settings = settings;
settings = settings{src.Value};


% get control tags and match to settings
settings_ctls = findall(settings_ctls,'-property','Tag');
ctl_tags = get(settings_ctls,'Tag');
has_tag = ~cellfun(@isempty, ctl_tags);
settings_ctls(~has_tag) = [];
ctl_tags(~has_tag) = [];

for i=1:numel(props)
    ctl_idx = find(strcmp(ctl_tags,props{i}));
    for j=1:numel(ctl_idx)
        val = settings.(props{i});
        switch  settings_ctls(ctl_idx(j)).Style
            case 'edit'
                if ischar(val)
                    settings_ctls(ctl_idx(j)).String = val;
                else
                    settings_ctls(ctl_idx(j)).String = sprintf('%i',val);
                end
            edit_Callback(settings_ctls(ctl_idx(j)),[]);

            case 'popupmenu'
                menu_idx = find(strcmpi(settings_ctls(ctl_idx(j)).String,val));
                if numel(menu_idx==1)
                    settings_ctls(ctl_idx).Value = menu_idx;
                end
            popupmenu_Callback(settings_ctls(ctl_idx(j)),[]);
        end
    end
end

% re-enable all device settings ctls
settings_uipanel = findall(pf,'Title','Device Settings','Type','uipanel');
settings_ctls = findall(settings_uipanel,'-property','Enable');
set(settings_ctls,'Enable','on');
    
end


function com_settings_subguiCloseRequestFcn(src,event)

% reset device status
expmt = src.UserData.expmt;
devices = expmt.hardware.COM.devices;
status = expmt.hardware.COM.status;

for i=1:numel(status)
    switch status{i}
        case 'open'
            if strcmpi(devices{i},'closed')
                fopen(devices{i});
            end
        case 'closed'
            if strcmpi(devices{i},'open')
                fclose(devices{i});
            end
    end
end

delete(src);

end