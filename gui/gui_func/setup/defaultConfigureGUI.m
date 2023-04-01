function handles = defaultConfigureGUI(handles)

warning('off','MATLAB:JavaEDTAutoDelegation');
warning('off','imaq:peekdata:tooManyFramesRequested');
set(handles.gui_fig,'doublebuffer','off');

if exist([handles.gui_dir 'profiles/deviceID.txt'],'file')

    fID = fopen([handles.gui_dir 'profiles/deviceID.txt']);
    handles.deviceID = fread(fID, '*char');
    fclose(fID);
    
    updateMonitor(handles.deviceID, MonitorStatuses.ACTIVE)
end

handles.display_menu.UserData = 'raw';     
gui_notify('welcome to margo',handles.disp_note);

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
handles.gui_fig.Units = 'characters';


% store panel starting location for reference when resizing
c=findobj(handles.gui_fig.Children,'Tag','cam_uipanel');
dh = (handles.gui_fig.Position(4) - c.Position(4)) - c.Position(2)- 0.005*handles.gui_fig.Position(4);
panels = findobj(handles.gui_fig.Children,'Type','uipanel');
for i = 1:length(panels)
    panels(i).Position(2) = panels(i).Position(2) + dh;
    panels(i).UserData = panels(i).Position;
end

rp = findobj('Tag','run_uipanel');
bp = findobj('Tag','bottom_uipanel');
dn = findobj('Tag','disp_note');
bp.Position(2) = 0.005*handles.gui_fig.Position(4);
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

% Choose default command line output for margo
handles.gui_fig.UserData.edit_rois = false;
handles.axes_handle = gca;
set(gca,'Xtick',[],'Ytick',[],'XLabel',[],'YLabel',[]);

% get experiment nums and function handles
experiments = struct('name','','run','','analyze','','sub_gui','');
par_dir = [handles.gui_dir 'experiments'];
dinfo = dir(par_dir);
dinfo(arrayfun(@(d) any(d.name=='.'), dinfo)) = [];
experiments = repmat(experiments, numel(dinfo), 1);
del = [];
handles.parameter_subgui = {};
for i=1:numel(experiments)
    
    experiments(i).name = dinfo(i).name;
    exp_dir = [par_dir '/' dinfo(i).name];
    run = recursiveSearch(exp_dir,'keyword','run_','ext','.m');
    if ~isempty(run)
        [~,run,~] = fileparts(run{1});
        experiments(i).run = str2func(run);
    else
        del = [del i];
    end
    analyze = recursiveSearch(exp_dir,'keyword','analyze_','ext','.m');
    if ~isempty(analyze)
        [~,analyze,~] = fileparts(analyze{1});
        experiments(i).analyze = str2func(analyze);
    end  
    sub_gui = recursiveSearch(exp_dir,'keyword','gui','ext','.m');
    if ~isempty(sub_gui)
        [~,sub_gui,~] = fileparts(sub_gui{1});
        experiments(i).sub_gui = str2func(sub_gui);
        handles.parameter_subgui = [handles.parameter_subgui; {dinfo(i).name}];
    end  
end

% delete improperly formatted experiments from the list
experiments(del) = [];
handles.experiments = experiments;
handles.exp_select_popupmenu.String = ...
    arrayfun(@(e) e.name, experiments, 'UniformOutput', false);


