function handles = defaultConfigureGUI(handles)

warning('off','MATLAB:JavaEDTAutoDelegation');
warning('off','imaq:peekdata:tooManyFramesRequested');
set(handles.gui_fig,'doublebuffer','off');

if exist([handles.gui_dir 'profiles/deviceID.txt'],'file')
    fID = fopen([handles.gui_dir 'profiles/deviceID.txt']);
    handles.deviceID=char(fread(fID))';
    fclose(fID);
    
    webop = weboptions('Timeout',0.25);
    status=true;
    try
        webread(['http://lab.debivort.org/mu.php?id=' ...
            handles.deviceID '&st=2'],webop);
    catch
        status = false;
    end
    if ~status
        gui_notify(...
            'unable to connect to http://lab.debivort.org',handles.disp_note);
    end
    
    
end
handles.display_menu.UserData = 1;     
gui_notify('welcome to autotracker',handles.disp_note);

% configure the figure window
root = get(0);
ndisp = size(root.MonitorPositions,1);
npix = NaN(ndisp,1);
for i=1:ndisp
    npix(i) = prod(root.MonitorPositions(i,[3 4]));
end
handles.root = root;
[~,idx] = max(npix);
x = root.MonitorPositions(idx,1);
y = root.MonitorPositions(idx,2) + root.MonitorPositions(idx,4)*0.1;
w = root.MonitorPositions(idx,3);
h = root.MonitorPositions(idx,4)*0.9;
handles.int_pos = handles.gui_fig.Position;
handles.gui_fig.Units = 'pixels';
handles.gui_fig.Position(1) = x;
handles.gui_fig.Position(2) = y;
handles.gui_fig.Position(3) = w;
handles.gui_fig.Position(4) = h;
handles.gui_fig.Units = 'points';

%handles.gui_fig.Position(2) = pdisp_res(4) - handles.gui_fig.Position(4);
%handles.gui_fig.Units = 'points';


% store panel starting location for reference when resizing
c=findobj(handles.gui_fig.Children,'Tag','cam_uipanel');
dh = (handles.gui_fig.Position(4) - c.Position(4)) - c.Position(2)-3;
panels = findobj(handles.gui_fig.Children,'Type','uipanel');
for i = 1:length(panels)
    panels(i).Position(2) = panels(i).Position(2) + dh;
    panels(i).UserData = panels(i).Position;
end

rp = findobj('Tag','run_uipanel');
bp = findobj('Tag','bottom_uipanel');
dn = findobj('Tag','disp_note');
bp.Position(2) = 3;
dh = (rp.Position(2) - bp.Position(2)) - bp.Position(4);
bp.Position(4) = rp.Position(2) - bp.Position(2);
dn.Position(4) = dn.Position(4)+ dh;
bp.UserData = bp.Position;

handles.left_edge = ...
    handles.exp_uipanel.Position(1) + handles.exp_uipanel.Position(3);
handles.vid_uipanel.Position = handles.cam_uipanel.Position;
handles.vid_uipanel.UserData = handles.vid_uipanel.Position;
handles.disp_note.UserData = handles.disp_note.Position;
handles.fig_size = handles.gui_fig.Position;


% disable all panels except cam/video and lighting
handles.exp_uipanel.ForegroundColor = [.5   .5  .5];
set(findall(handles.exp_uipanel, '-property', 'Enable'), 'Enable', 'off');
handles.tracking_uipanel.ForegroundColor = [.5   .5  .5];
set(findall(handles.tracking_uipanel, '-property', 'Enable'), 'Enable', 'off');
handles.run_uipanel.ForegroundColor = [.5   .5  .5];
set(findall(handles.run_uipanel, '-property', 'Enable'), 'Enable', 'off');

% Choose default command line output for autotracker
handles.gui_fig.UserData.edit_rois = false;
handles.axes_handle = gca;
set(gca,'Xtick',[],'Ytick',[],'XLabel',[],'YLabel',[]);

% popuplate saved profile list and create menu items
% Get existing profile list
load_path =[handles.gui_dir 'profiles/'];
tmp_profiles = ls(load_path);
profiles = cell(size(tmp_profiles,1),1);
remove = [];

for i = 1:size(profiles,1);
    k = strfind(tmp_profiles(i,:),'.mat');       % identify .mat files in dir
    if isempty(k)
        remove = [remove i];                        
    else
        profiles(i) = {tmp_profiles(i,1:k-1)};   % save mat file names
    end
end
profiles(remove)=[];                             % remove non-mat files from list

if size(profiles,1) > 0
    handles.profiles = profiles;
else
    handles.profiles = {'No profiles detected'};
end

% generate menu items for saved profiles and config their callbacks
hParent = findobj('Tag','saved_presets_menu');
save_path = [handles.gui_dir 'profiles/'];
fh = @(hObject,eventdata)...
        autotracker('saved_preset_Callback',...
            hObject,eventdata,guidata(hObject));

for i = 1:length(profiles)
    menu_items(i) = uimenu(hParent,'Label',profiles{i},...
                        'Callback',fh);
    menu_items(i).UserData.path = [save_path profiles{i} '.mat'];
    menu_items(i).UserData.index = i;
    menu_items(i).UserData.gui_handles = handles;
end