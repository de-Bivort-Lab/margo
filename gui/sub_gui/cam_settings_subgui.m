function cam_settings_subgui(expmt)

% check to see if a camera exists
if ~isfield(expmt.hardware.cam,'AdaptorName') || ...
        ~isfield(expmt.hardware.cam,'DeviceIDs') || ...
        ~isfield(expmt.hardware.cam,'ActiveMode')
    return;
end

% get device properties
if ~isfield(expmt.hardware.cam,'vid') || ...
        (isfield(expmt.hardware.cam,'vid') && ~isvalid(expmt.hardware.cam.vid))
    imaqreset;
    pause(0.1);
    vid = videoinput(expmt.hardware.cam.AdaptorName,expmt.hardware.cam.DeviceIDs{1},expmt.hardware.cam.ActiveMode{:});
else
    vid = expmt.hardware.cam.vid;
end
if strcmpi(vid.Running,'on')
    dn = findobj('Tag','disp_note');
    gui_notify('closing open camera session to adjust settings',dn);
    stop(vid);
end

src = getselectedsource(vid);
info = propinfo(src);
names = fieldnames(info);

if isfield(expmt.hardware.cam,'settings') && strcmpi(vid.Running,'off')
    
    % query saved cam settings
    [i_src,i_set]=cmpCamSettings(src,expmt.hardware.cam.settings);
    set_names = fieldnames(expmt.hardware.cam.settings);
    
    for i = 1:length(i_src)
        if ~isfield(info.(names{i_src(i)}),'ReadOnly') || ...
                ~strcmpi(info.(names{i_src(i)}).ReadOnly,'always')
            
            src.(names{i_src(i)}) = ...
                expmt.hardware.cam.settings.(set_names{i_set(i)});
        end
    end
else
    prop_names = fieldnames(src);
    has_readonly = find(cellfun(@(n) isfield(info.(n),'ReadOnly'), prop_names));
    is_readonly = cellfun(@(n) strcmpi(info.(n).ReadOnly,'always'), ...
        prop_names(has_readonly));
    prop_names(has_readonly(is_readonly))=[];
    prop_vals = cellfun(@(n) src.(n), prop_names, 'UniformOutput', false);
    settings = cat(1,prop_names',prop_vals');
    expmt.hardware.cam.settings = struct(settings{:});
end



name_lengths = zeros(length(names),1);
for i = 1:length(names)
    name_lengths(i) = numel(names{i});
end
hscale = max(name_lengths);

%% Determine the size of the UI based on how many elements need to be populated
nControls = 0;
del = [];
for i = 1:length(names)
    field = info.(names{i});
    if (strcmp(field.Constraint,'bounded')&&numel(src.(names{i}))<2) || strcmp(field.Constraint,'enum')
        nControls = nControls + 1;
    else
        del = [del i];
    end
end

names(del) = [];                % remove non-addressable properties
nColumns = ceil(nControls/12);   % set column number

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
current_height = 0;

%%

%  Create and then hide the UI as it is being constructed.
fpos = gui_fig.Position;
col_w = slider_w + edit_w*2 + hspacer;
fig_size = [fpos(1:2)+2 col_w*nColumns (edit_h+pad)*12+pad];

f = figure('Visible','on','Units','characters',...
    'Position',fig_size,'Name','Camera Settings');
set(f,'MenuBar','none','Toolbar','none','resize','off','NumberTitle','off');

% initialize ui scaling components
uival(1) = uicontrol('Style','text','string','','Position',[0 0 0 0]);
fw = f.Position(3);
fh = f.Position(4);

ct = 0;


for i = 1:length(names)
    
    field = info.(names{i});
    if strcmp(field.Constraint,'bounded')
        current_height = current_height + edit_h + pad;
        ct = ct + 1;

        uival(i) = uicontrol('Style','edit','string',num2str(src.(names{i})),...
            'Units','characters','Position',...
            [hspacer + col_w*floor((i-1)/12), ...
            (fh-current_height), edit_w, edit_h],...
            'FontUnits','normalized','HorizontalAlignment','center','Callback',@edit_Callback);
        
        uival(i).UserData = i;
        uictl(i) = uicontrol('Style','slider','Min',field.ConstraintValue(1),...
            'Max',field.ConstraintValue(2),'value',src.(names{i}),...
           'Units','characters','Position',...
           [sum(uival(i).Position([1,3]))+hspacer/2,...
           (fh-current_height), slider_w, slider_h],...
           'FontUnits','normalized','Callback',@slider_Callback);
       
        uictl(i).UserData = i;
        uilbl(i) = uicontrol('Style','text','string',names{i},...
            'Units','characters','Position',...
            [hspacer+col_w*floor((i-1)/12) sum(uictl(i).Position([2 4]))++label_h/4 ...
            numel(names{i})*w_per_char label_h],...
            'FontUnits','normalized','HorizontalAlignment','left');
        
        bound1 = sprintf('%0.2f',field.ConstraintValue(2));
        uicontrol('Style','text','string',bound1,...
            'Units','characters','Position',...
            [sum(uictl(i).Position([1 3]))-numel(bound1)*w_per_char,...
            sum(uictl(i).Position([2 4]))++label_h/4, numel(bound1)*w_per_char, label_h],...
            'FontUnits','normalized','HorizontalAlignment','right');
        
        bound2 = sprintf('%0.2f',field.ConstraintValue(1));
        uicontrol('Style','text','string',bound2,...
            'Units','characters','Position',...
            [uictl(i).Position(1), sum(uictl(i).Position([2 4]))++label_h/4, ...
            numel(bound2)*w_per_char, label_h],...
            'FontUnits','normalized','HorizontalAlignment','left');
%         uictl(i).Units = 'normalized';
%         uilbl(i).Units = 'normalized';
%         uival(i).Units = 'normalized';
        

    end

    if strcmp(field.Constraint,'enum')
        ct = ct + 1;
        current_height = current_height + menu_h + pad;
        uictl(i) = uicontrol('Style','popupmenu','string',field.ConstraintValue,...
                'Units','characters','Position',...
                [col_w*floor((i-1)/12)+hspacer, fh-current_height, menu_w, menu_h],...
                'FontUnits','normalized','Callback',@popupmenu_Callback);
        uictl(i).UserData = i;
        uilbl(i) = uicontrol('Style','text','string',names{i},...
            'Units','characters','Position',...
            [hspacer+col_w*floor((i-1)/12), sum(uictl(i).Position([2 4]))++label_h/4, ...
            numel(names{i})*w_per_char, label_h],...
            'FontUnits','normalized','HorizontalAlignment','left');
        
%         uictl(i).Units = 'normalized';
%         uilbl(i).Units = 'normalized';
        
        % find current value from src
        str_list = get(uictl(i),'string');
        cur_val = 1;
        for j = 1:length(str_list)
            if strcmp(src.(names{i}),str_list{j})
            cur_val = j;
            end
        end
        
        set(uictl(i),'value',cur_val);

    end
    
    % reset current height to zero for new column
    if ~mod(i,12)
        current_height = 0;
    end

    guiData.uictl = uictl;
    guiData.uival = uival;
    guiData.names = names;
    guiData.expmt = expmt;
    guiData.cam_src = src;
    set(f,'UserData',guiData);

end
    
if (strcmpi(vid.Previewing,'off') && strcmpi(vid.Running,'on'))
    set(findall(f,'-property','Enable'),'Enable','off');
end
end

function slider_Callback(src,event)

    pf = get(src,'parent');     % get parent fig handle
    data = pf.UserData;         % retrieve data stored in fig handle
    names = data.names;
    vals= data.uival;
    
    % update coupled UI component
    set(vals(src.UserData),'string',sprintf('%0.2f',src.Value));
    
    % update camera source and settings
    data.expmt.hardware.cam.settings.(names{src.UserData}) = get(src,'value');
    data.cam_src.(names{src.UserData}) = get(src,'value');
    set(pf,'UserData',data);

end

function popupmenu_Callback(src,event)

    pf = get(src,'parent');         % get parent fig handle
    data = pf.UserData;             % retrieve data stored in fig handle
    names = data.names;
    str_list = get(src,'string');
    
    % update camera source and settings with current value of src.string
    data.expmt.hardware.cam.settings.(names{src.UserData}) = str_list{get(src,'value')};  
    data.cam_src.(names{src.UserData}) = str_list{get(src,'value')};
    set(pf,'UserData',data);

end

function edit_Callback(src,event)

    pf = get(src,'parent');     % get parent fig and stored data
    data = pf.UserData;
    names = data.names;
    ctls = data.uictl;
    
    % update camera source and settings with current value of src.string
    val = str2double(get(src,'string'));
    info = propinfo(data.cam_src);
    if isfield(info,(names{src.UserData})) && ...
            isfield(info.(names{src.UserData}),'Constraint')
        if val < info.(names{src.UserData}).ConstraintValue(1)
            val = info.(names{src.UserData}).ConstraintValue(1);
        elseif val > info.(names{src.UserData}).ConstraintValue(2)
            val = info.(names{src.UserData}).ConstraintValue(2);
        end
    end
    
    % update coupled UI component Experiment Data
    set(ctls(src.UserData),'value',val);   
    data.expmt.hardware.cam.settings.(names{src.UserData}) = val;  
    data.cam_src.(names{src.UserData}) = val;
    src.String = sprintf('%0.2f',val);
    set(pf,'UserData',data); 
    
end