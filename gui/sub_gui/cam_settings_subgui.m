function [expmt_out] = cam_settings_subgui(handles,expmt_in)

% get device properties
if ~isfield(expmt_in.camInfo,'vid')
    imaqreset;
    pause(0.1);
    vid = videoinput(expmt_in.camInfo.AdaptorName,expmt_in.camInfo.DeviceIDs{1},expmt_in.camInfo.ActiveMode{:});
else
    vid = expmt_in.camInfo.vid;
    if strcmp(vid.Running,'on')
        stop(vid);
    end   
end

src = getselectedsource(vid);
info = propinfo(src);
names = fieldnames(info);

if isfield(expmt_in.camInfo,'settings')
    
    % query saved cam settings
    [i_src,i_set]=cmpCamSettings(src,expmt_in.camInfo.settings);
    set_names = fieldnames(expmt_in.camInfo.settings);
    
    for i = 1:length(i_src)
        src.(names{i_src(i)}) = expmt_in.camInfo.settings.(set_names{i_set(i)});
    end
    
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

%%

%  Create and then hide the UI as it is being constructed.
font_scale = 6;
f = figure('Visible','on','Position',...
    [400,100,(hscale*font_scale + 250)*nColumns,600],'Name','Camera Settings');
set(f,'MenuBar','none','Toolbar','none','resize','off','NumberTitle','off');

% initialize ui scaling components
col_w = (hscale*font_scale + 225);
uival(1) = uicontrol('Style','text','string','','Position',[0 0 0 0]);
fw = f.Position(3);
fh = f.Position(4);
slider_height = 15;
menu_height = 15;
label_height = 15;
spacing = 30;
current_height = 0;
ct = 0;


for i = 1:length(names)
    
    field = info.(names{i});
    if strcmp(field.Constraint,'bounded')
        current_height = current_height + slider_height + spacing;
        ct = ct + 1;

        uival(i) = uicontrol('Style','edit','string',num2str(src.(names{i})),'Position',...
            [hscale*font_scale + 30 + col_w*floor((i-1)/12), (fh-current_height), 60, label_height],...
            'HorizontalAlignment','left','Callback',@edit_Callback);
        uival(i).UserData = i;
        uictl(i) = uicontrol('Style','slider','Min',field.ConstraintValue(1),...
            'Max',field.ConstraintValue(2),'value',src.(names{i}),...
           'Position',[sum(uival(i).Position([1,3]))+15,(fh-current_height),125,slider_height],...
           'Callback',@slider_Callback);
        uictl(i).UserData = i;
        uilbl(i) = uicontrol('Style','text','string',names{i},'Position',...
            [10+ col_w*floor((i-1)/12) uictl(i).Position(2) hscale*font_scale label_height],...
            'HorizontalAlignment','right');
        uicontrol('Style','text','string',num2str(round(field.ConstraintValue(2)*100)/100),'Position',...
            [uictl(i).Position(1)+uictl(i).Position(3)-60 uictl(i).Position(2)-17 60 label_height],...
            'HorizontalAlignment','right','Units','normalized');
        uicontrol('Style','text','string',num2str(round(field.ConstraintValue(1)*100)/100),'Position',...
            [uictl(i).Position(1) uictl(i).Position(2)-17 20 label_height],...
            'HorizontalAlignment','left','Units','normalized');
        uictl(i).Units = 'normalized';
        uilbl(i).Units = 'normalized';
        uival(i).Units = 'normalized';
        

    end

    if strcmp(field.Constraint,'enum')
        ct = ct + 1;
        current_height = current_height + slider_height + spacing;
        uictl(i) = uicontrol('Style','popupmenu','string',field.ConstraintValue,...
                'Position',[hscale*font_scale+col_w*floor((i-1)/12) + 30,fh - current_height,60,slider_height],...
                'Callback',@popupmenu_Callback);
        uictl(i).UserData = i;
        uilbl(i) = uicontrol('Style','text','string',names{i},'Position',...
            [10+col_w*floor((i-1)/12) uictl(i).Position(2) hscale*font_scale label_height],...
            'HorizontalAlignment','right');
        
        uictl(i).Units = 'normalized';
        uilbl(i).Units = 'normalized';
        
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
    guiData.expmt_in = expmt_in;
    guiData.cam_src = src;
    set(f,'UserData',guiData);

end
    
%%
while ishghandle(f)
    pause(0.001);
    if isprop(f,'UserData')
    expmt_out = f.UserData.expmt_in;
    end
end

end

function slider_Callback(src,event)

    pf = get(src,'parent');     % get parent fig handle
    data = pf.UserData;         % retrieve data stored in fig handle
    names = data.names;
    vals= data.uival;
    
    % update coupled UI component
    set(vals(src.UserData),'string',num2str(get(src,'value')));
    
    % update camera source and settings
    data.expmt_in.camInfo.settings.(names{src.UserData}) = get(src,'value');
    data.cam_src.(names{src.UserData}) = get(src,'value');
    set(pf,'UserData',data);

end

function popupmenu_Callback(src,event)

    pf = get(src,'parent');         % get parent fig handle
    data = pf.UserData;             % retrieve data stored in fig handle
    names = data.names;
    str_list = get(src,'string');
    
    % update camera source and settings with current value of src.string
    data.expmt_in.camInfo.settings.(names{src.UserData}) = str_list{get(src,'value')};
    data.cam_src.(names{src.UserData}) = str_list{get(src,'value')};
    set(pf,'UserData',data);

end

function edit_Callback(src,event)

    pf = get(src,'parent');     % get parent fig and stored data
    data = pf.UserData;
    names = data.names;
    ctls = data.uictl;
    
    % update coupled UI component
    set(ctls(src.UserData),'value',str2num(get(src,'string')));
    
    % update camera source and settings with current value of src.string
    data.expmt_in.camInfo.settings.(names{src.UserData}) = str2num(get(src,'string'));
    data.cam_src.(names{src.UserData}) = str2num(get(src,'string'));
    set(pf,'UserData',data); 
    
end