function varargout = integratedtrackinggui(varargin)
% INTEGRATEDTRACKINGGUI MATLAB code for integratedtrackinggui.fig
%      INTEGRATEDTRACKINGGUI, by itself, creates a new INTEGRATEDTRACKINGGUI or raises the existing
%      singleton*.
%
%      H = INTEGRATEDTRACKINGGUI returns the handle to a new INTEGRATEDTRACKINGGUI or the handle to
%      the existing singleton*.
%
%      INTEGRATEDTRACKINGGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in INTEGRATEDTRACKINGGUI.M with the given input arguments.
%
%      INTEGRATEDTRACKINGGUI('Property','Value',...) creates a new INTEGRATEDTRACKINGGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before integratedtrackinggui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to integratedtrackinggui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help integratedtrackinggui

% Last Modified by GUIDE v2.5 08-Mar-2017 11:33:39

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @integratedtrackinggui_OpeningFcn, ...
                   'gui_OutputFcn',  @integratedtrackinggui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before integratedtrackinggui is made visible.
function integratedtrackinggui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to integratedtrackinggui (see VARARGIN)

warning('off','MATLAB:JavaEDTAutoDelegation');

gui_notify('welcome to autotracker',handles.disp_note);

% store panel starting location for reference when resizing
handles.fig_size = handles.gui_fig.Position;
panels = findobj(handles.gui_fig.Children,'Type','uipanel');
for i = 1:length(panels)
    panels(i).UserData = panels(i).Position;
end
handles.left_edge = handles.exp_uipanel.Position(1) + handles.exp_uipanel.Position(3);
handles.vid_uipanel.Position = handles.cam_uipanel.Position;
handles.vid_uipanel.UserData = handles.vid_uipanel.Position;
handles.disp_note.UserData = handles.disp_note.Position;

% disable all panels except cam/video and lighting
handles.exp_uipanel.ForegroundColor = [.5   .5  .5];
set(findall(handles.exp_uipanel, '-property', 'enable'), 'enable', 'off');
handles.tracking_uipanel.ForegroundColor = [.5   .5  .5];
set(findall(handles.tracking_uipanel, '-property', 'enable'), 'enable', 'off');
handles.run_uipanel.ForegroundColor = [.5   .5  .5];
set(findall(handles.run_uipanel, '-property', 'enable'), 'enable', 'off');



% Choose default command line output for integratedtrackinggui
handles.output = hObject;
handles.axes_handle = gca;
handles.gui_dir = which('autotrackergui');
handles.gui_dir = handles.gui_dir(1:strfind(handles.gui_dir,'\gui\'));
handles.display_menu.UserData = 1;                                           
set(gca,'Xtick',[],'Ytick',[]);
expmt = [];

% initialize array indicating expIDs for experiments with an associated
% parameter subgui. NOTE: any custom experiments with an experiment
% parameters subgui must be added to this list.
handles.parameter_subgui = [3 4];

% popuplate saved profile list and create menu items
% Get existing profile list
load_path =[handles.gui_dir 'profiles\'];
tmp_profiles = ls(load_path);
profiles = cell(size(tmp_profiles,1),1);
remove = [];

for i = 1:size(profiles,1);
    k = strfind(tmp_profiles(i,:),'.mat');          % identify .mat files in dir
    if isempty(k)
        remove = [remove i];                        
    else
        profiles(i) = {tmp_profiles(i,1:k-1)};      % save mat file names
    end
end
profiles(remove)=[];                                % remove non-mat files from list

if size(profiles,1) > 0
    handles.profiles = profiles;
else
    handles.profiles = {'No profiles detected'};
end

% cam setup
expmt.source = 'camera';                    % set the source mode to camera by default
expmt.camInfo = refresh_cam_list(handles);  % query available cameras and camera info

% Initialize teensy for motor and light board control

%Close and delete any open serial objects
if ~isempty(instrfindall)
fclose(instrfindall);                       % Make sure that the COM port is closed
delete(instrfindall);                       % Delete any serial objects in memory
end

% Attempt handshake with light panel teensy
[expmt.COM,handles.aux_COM_list] = identifyMicrocontrollers;


% Update GUI menus with port names
set(handles.microcontroller_popupmenu,'string',expmt.COM);

% Initialize light panel at default values
IR_intensity = str2num(get(handles.edit_IR_intensity,'string'));
White_intensity = str2num(get(handles.edit_White_intensity,'string'));

% Convert intensity percentage to uint8 PWM value 0-255
expmt.light.infrared = uint8((IR_intensity/100)*255);
expmt.light.white = uint8((White_intensity/100)*255);

% Write values to microcontroller
writeInfraredWhitePanel(expmt.COM,1,expmt.light.infrared);
writeInfraredWhitePanel(expmt.COM,0,expmt.light.white);

% generate menu items for AUX COMs and config their callbacks
hParent = findobj('Tag','aux_com_menu');

% remove controls for existing list
del=[];
for i = 1:length(hParent.Children)
    if ~strcmp(hParent.Children(i).Label,'refresh list')
        del = [del i];
    end
end
delete(hParent.Children(del));

if ~isempty(handles.aux_COM_list)
    expmt.AUX_COM = handles.aux_COM_list(1);
end
        
% generate controls for new list
for i = 1:length(handles.aux_COM_list)
    menu_items(i) = uimenu(hParent,'Label',handles.aux_COM_list{i},...
        'Callback',@aux_com_list_Callback);
    if i ==1
        menu_items(i).Separator = 'on';
        menu_items(i).Checked = 'on';
    end
end

% Initialize expmteriment parameters from text boxes in the GUI
handles.edit_ref_depth.Value  =  str2num(get(handles.edit_ref_depth,'String'));
handles.edit_ref_freq.Value = str2num(get(handles.edit_ref_freq,'String'));
handles.edit_exp_duration.Value = str2num(get(handles.edit_exp_duration,'String'));
handles.disp_ROI_thresh.String = num2str(round(handles.ROI_thresh_slider.Value));
handles.disp_track_thresh.String = num2str(round(handles.track_thresh_slider.Value));

% initialize tracking parameters to default values
handles.gui_fig.UserData.speed_thresh = 45;
handles.gui_fig.UserData.distance_thresh = 20;
handles.gui_fig.UserData.vignette_sigma = 0.47;
handles.gui_fig.UserData.vignette_weight = 0.35;
handles.gui_fig.UserData.area_min = 4;
handles.gui_fig.UserData.area_max = 300;
handles.gui_fig.UserData.sort_mode = 'distance';

% save values to expmt master struct
expmt.parameters.speed_thresh = handles.gui_fig.UserData.speed_thresh;
expmt.parameters.distance_thresh = handles.gui_fig.UserData.distance_thresh;
expmt.parameters.vignette_sigma = handles.gui_fig.UserData.vignette_sigma;
expmt.parameters.vignette_weight = handles.gui_fig.UserData.vignette_weight;
expmt.parameters.area_min = handles.gui_fig.UserData.area_min;
expmt.parameters.area_max = handles.gui_fig.UserData.area_max;
expmt.parameters.ref_depth = str2num(get(handles.edit_ref_depth,'String'));
expmt.parameters.ref_freq = str2num(get(handles.edit_ref_freq,'String'));
expmt.parameters.duration = str2num(get(handles.edit_exp_duration,'String'));
expmt.parameters.ROI_thresh = num2str(round(handles.ROI_thresh_slider.Value));
expmt.parameters.track_thresh = num2str(round(handles.track_thresh_slider.Value));
expmt.parameters.sort_mode = 'distance';

expmt.parameters.mm_per_pix = 1;            % set default distance scale 1 mm per pixel
expmt.parameters.units = 'pixels';          % set default units to pixels
expmt.vignette.mode = 'auto';
expmt.expID = 1;

if ~isempty(expmt.camInfo) && ~isempty(expmt.camInfo.activeID)
    [handles.gui_fig.UserData.target_rate, expmt.camInfo] = estimateFrameRate(expmt.camInfo);
else
    handles.gui_fig.UserData.target_rate = 60;
end
expmt.parameters.target_rate = handles.gui_fig.UserData.target_rate;

setappdata(handles.gui_fig,'expmt',expmt);

% generate menu items for saved profiles and config their callbacks
hParent = findobj('Tag','saved_presets_menu');
save_path = [handles.gui_dir 'profiles\'];
for i = 1:length(profiles)
    menu_items(i) = uimenu(hParent,'Label',profiles{i},...
        'Callback',@saved_preset_Callback);
    menu_items(i).UserData.path = [save_path profiles{i} '.mat'];
    menu_items(i).UserData.index = i;
    menu_items(i).UserData.gui_handles = handles;
end

% Update handles structure
guidata(hObject,handles);

% UIWAIT makes integratedtrackinggui wait for user response (see UIRESUME)
% uiwait(handles.gui_fig);

% --- Outputs from this function are returned to the command line.
function varargout = integratedtrackinggui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;






%-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**-*-*-*-*-*-*-* -%
%-*-*-*-*-*-*-*-*-*-*-*-CAMERA FUNCTIONS-*-*-*-*-*-*-*-*-*-*-*-*%
%-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**-*-*-*-*-*-*-*-*%



% --- Executes on selection change in cam_select_popupmenu.
function cam_select_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to cam_select_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment variables
expmt = getappdata(handles.gui_fig,'expmt');

if ~isempty(handles.cam_list(get(hObject,'value')).adaptor)
    
    % get camera adaptor
    adaptor = handles.cam_list(get(hObject,'value')).adaptor;
    
    camInfo = imaqhwinfo(adaptor);
    deviceInfo = camInfo.DeviceInfo(handles.cam_list(get(hObject,'value')).index);
    
    set(handles.cam_mode_popupmenu,'String',deviceInfo.SupportedFormats);
    default_format = deviceInfo.DefaultFormat;

    for i = 1:length(deviceInfo.SupportedFormats)
        if strcmp(default_format,camInfo.DeviceInfo(1).SupportedFormats{i})
            set(handles.cam_mode_popupmenu,'Value',i);
            camInfo.ActiveMode = camInfo.DeviceInfo(1).SupportedFormats(i);
        end
    end
    
    expmt.camInfo = camInfo;
    expmt.camInfo.activeID = handles.cam_list(get(hObject,'value')).index;
    
end

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);
guidata(hObject,handles);



% --- Executes during object creation, after setting all properties.
function cam_select_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cam_select_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on selection change in cam_mode_popupmenu.
function cam_mode_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to cam_mode_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

expmt = getappdata(handles.gui_fig,'expmt');

strCell = get(handles.cam_mode_popupmenu,'string');
expmt.camInfo.ActiveMode = strCell(get(handles.cam_mode_popupmenu,'Value'));

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function cam_mode_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cam_mode_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Cam_confirm_pushbutton.
function Cam_confirm_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Cam_confirm_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

if ~isempty(expmt.camInfo)
    if ~isempty(expmt.camInfo.DeviceInfo)
        cla reset
        imaqreset;
        pause(0.02);
        expmt.camInfo = initializeCamera(expmt.camInfo);
        start(expmt.camInfo.vid);
        
        % Store expmteriment data struct
        setappdata(handles.gui_fig,'expmt',expmt);
        pause(0.2);
        
        % measure frame rate
        [handles.gui_fig.UserData.target_rate, expmt.camInfo] = estimateFrameRate(expmt.camInfo);
        expmt.camInfo.frame_rate = handles.gui_fig.UserData.target_rate;
        
        % adjust aspect ratio of plot to match camera
        colormap('gray');
        im = peekdata(expmt.camInfo.vid,1);
        handles.hImage = imagesc(im);
        handles.axes_handle.Position(3) = ...
            handles.gui_fig.Position(3) - 5 - handles.axes_handle.Position(1);
        res = expmt.camInfo.vid.VideoResolution;
        aspectR = res(2)/res(1);
        plot_aspect = pbaspect;
        fscale = aspectR/plot_aspect(2);

        if fscale < 1
            axes_height_old = handles.axes_handle.Position(4);
            axes_height_new = axes_height_old*fscale;
            handles.axes_handle.Position(4) = axes_height_new;
            handles.axes_handle.Position(2) = handles.axes_handle.Position(2) + axes_height_old - axes_height_new;
        else
            aspectR = res(1)/res(2);
            plot_aspect = pbaspect;
            plot_aspect = plot_aspect./plot_aspect(2);
            fscale = aspectR/plot_aspect(1);
            axes_width_old = handles.axes_handle.Position(3);
            axes_width_new = axes_width_old*fscale;
            handles.axes_handle.Position(3) = axes_width_new;
            handles.gui_fig.Position(3) = ...
                sum(handles.axes_handle.Position([1 3])) + 10;

        end
        
        % set the colormap and axes ticks
        colormap('gray');
        set(gca,'Xtick',[],'Ytick',[]);
        
        % set downstream UI panel enable status
        handles.tracking_uipanel.ForegroundColor = [0 0 0];
        set(findall(handles.tracking_uipanel, '-property', 'enable'), 'enable', 'on');
        handles.distance_scale_menu.Enable = 'on';
        handles.vignette_correction_menu.Enable = 'on';
        
        if ~isfield(expmt,'ROI')
            handles.track_thresh_slider.Enable = 'off';
            handles.accept_track_thresh_pushbutton.Enable = 'off';
            handles.reference_pushbutton.Enable = 'off';
            handles.track_thresh_label.Enable = 'off';
            handles.disp_track_thresh.Enable = 'off';
        end
        
        if ~isfield(expmt,'ref')
            handles.sample_noise_pushbutton.Enable = 'off';
        end
            
        gui_notify('cam settings confirmed',handles.disp_note);
        
        if isfield(expmt,'ROI') && isfield(expmt,'ref') &&  isfield(expmt,'noise')
            expmt = rmfield(expmt,'ROI');
            expmt = rmfield(expmt,'ref');
            expmt = rmfield(expmt,'noise');
            msgbox(['Cam settings changed: saved ROIs, references and ' ...
                'noise statistics have been discarded.']);
            note = 'ROIs, references, and noise statistics reset';
            gui_notify(note,handles.disp_note);
        elseif isfield(expmt,'ROI') && isfield(expmt,'ref')
            expmt = rmfield(expmt,'ROI');
            expmt = rmfield(expmt,'ref');
            msgbox(['Cam settings changed: saved ROIs, references ' ...
                'have been discarded.']);
            note = 'ROIs and references reset';
            gui_notify(note,handles.disp_note);
        elseif isfield(expmt,'ROI')
           expmt = rmfield(expmt,'ROI');
           msgbox(['Cam settings changed: saved ROIs ' ...
                'have been discarded.']);
            note = 'saved ROI positions reset';
            gui_notify(note,handles.disp_note);
        end
        
        % query frame rate
        [handles.gui_fig.UserData.target_rate, expmt.camInfo] = estimateFrameRate(expmt.camInfo);
        
        gui_notify('cam settings confirmed',handles.disp_note);
        note = ['frame rate measured at ' ...
            num2str(round(handles.gui_fig.UserData.target_rate*100)/100) 'fps'];
        gui_notify(note, handles.disp_note);
        note = ['resolution: ' num2str(res(1)) ' x ' num2str(res(2))];
        gui_notify(note, handles.disp_note);
        
    else
        errordlg('Settings not confirmed, no camera detected');
    end
else
    errordlg('No cameras adaptors installed');
end

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);





% --- Executes on button press in Cam_preview_togglebutton.
function Cam_preview_togglebutton_Callback(hObject, eventdata, handles)
% hObject    handle to Cam_preview_togglebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');
clean_gui(handles.axes_handle);

switch get(hObject,'value')
    case 1
        if ~isempty(expmt.camInfo) && ~isfield(expmt.camInfo, 'vid')
            errordlg('Please confirm camera settings')
        else
            preview(expmt.camInfo.vid,handles.hImage);     
            set(hObject,'string','Stop preview','BackgroundColor',[0.8 0.45 0.45]);
        end
    case 0
        if ~isempty(expmt.camInfo) && isfield(expmt.camInfo,'vid');
            stoppreview(expmt.camInfo.vid);
            handles.hImage = imagesc(handles.axes_handle,handles.hImage.CData(:,:,2));
            set(hObject,'string','Start preview','BackgroundColor',[1 1 1]);
        end
end

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);
guidata(hObject,handles);


% --- Executes on selection change in microcontroller_popupmenu.
function microcontroller_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to microcontroller_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns microcontroller_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from microcontroller_popupmenu


% --- Executes during object creation, after setting all properties.
function microcontroller_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to microcontroller_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_IR_intensity_Callback(hObject, eventdata, handles)
% hObject    handle to edit_IR_intensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Initialize light panel at default values

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

expmt.light.infrared = str2num(get(handles.edit_IR_intensity,'string'));

% Convert intensity percentage to uint8 PWM value 0-255
expmt.light.infrared = uint8((expmt.light.infrared/100)*255);

writeInfraredWhitePanel(expmt.COM,1,expmt.light.infrared);

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);


% --- Executes during object creation, after setting all properties.
function edit_IR_intensity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_IR_intensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_White_intensity_Callback(hObject, eventdata, handles)
% hObject    handle to edit_White_intensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

White_intensity = str2num(get(handles.edit_White_intensity,'string'));

% Convert intensity percentage to uint8 PWM value 0-255
expmt.light.white = uint8((White_intensity/100)*255);
writeInfraredWhitePanel(expmt.COM,0,expmt.light.white);

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_White_intensity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_White_intensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in save_path_button1.
function save_path_button1_Callback(hObject, eventdata, handles)
% hObject    handle to save_path_button1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');
mat_dir = handles.gui_dir(1:strfind(handles.gui_dir,'MATLAB\')+6);
default_path = [mat_dir 'autotracker_data\'];
if exist(default_path,'dir') ~= 7
    mkdir(default_path);
    msg_title = 'New Data Path';
    message = ['Autotracker has automatically generated a new default directory'...
        ' for data in ' default_path];
    
    % Display info
    waitfor(msgbox(message,msg_title));
end    

[fpath]  =  uigetdir(default_path,'Select a save destination');
expmt.fpath = fpath;
set(handles.save_path,'string',fpath);

% if experiment parameters are set, enable experiment run panel
if expmt.expID > 1 && ~isempty(handles.save_path.String)
    set(findall(handles.run_uipanel, '-property', 'enable'),'enable','on');
end


% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);






function save_path_Callback(hObject, eventdata, handles)
% hObject    handle to save_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of save_path as text
%        str2double(get(hObject,'String')) returns contents of save_path as a double


% --- Executes during object creation, after setting all properties.
function save_path_CreateFcn(hObject, eventdata, handles)
% hObject    handle to save_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function labels_uitable_CreateFcn(hObject, eventdata, handles)
% hObject    handle to labels_uitable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

data=cell(10,11);
data(:) = {''};
set(hObject, 'Data', data);
expmt.labels = data;

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);




% --- Executes when entered data in editable cell(s) in labels_uitable.
function labels_uitable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to labels_uitable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

expmt.labels{eventdata.Indices(1), eventdata.Indices(2)} = {''};
expmt.labels{eventdata.Indices(1), eventdata.Indices(2)} = eventdata.NewData;

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);




function edit_ref_depth_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ref_depth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

handles.edit_ref_depth.Value = str2num(get(handles.edit_ref_depth,'String'));
expmt.parameters.ref_depth = handles.edit_ref_depth.Value;

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_ref_depth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ref_depth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_ref_freq_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ref_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

handles.edit_ref_freq.Value = str2num(get(handles.edit_ref_freq,'String'));
expmt.parameters.ref_freq = handles.edit_ref_freq.Value;

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);




% --- Executes during object creation, after setting all properties.
function edit_ref_freq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ref_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_exp_duration_Callback(hObject, eventdata, handles)
% hObject    handle to edit_exp_duration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

handles.edit_exp_duration.Value = str2num(get(handles.edit_exp_duration,'String'));
expmt.parameters.duration = handles.edit_exp_duration.Value;


% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);




% --- Executes during object creation, after setting all properties.
function edit_exp_duration_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_exp_duration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

keep_gui_state = false;

if isfield(expmt, 'fpath') == 0 
    errordlg('Please specify Save Location')
elseif ~isfield(expmt, 'camInfo')
    errordlg('Please confirm camera settings')
elseif ~isfield(expmt,'ROI')
    errordlg('Please run ROI detection before starting tracking');
elseif ~isfield(expmt,'ref')
    errordlg('Please acquire a reference image before beginning tracking');
elseif ~isfield(expmt,'noise')
    errordlg('Please run noise sampling before starting tracking');
else
    switch expmt.expID
    	case 2
            projector_escape_response;
        case 3
            projector_optomotor;
        case 4
            expmt = run_slowphototaxis(expmt,handles);
        case 5
            if ~isfield(expmt,'AUX_COM') || isempty(expmt.AUX_COM)
                errordlg('No aux COM assigned for LED Y-maze');
                keep_gui_state = true;
            else
                expmt = run_ledymaze(expmt,handles);
                expmt = analyze_ledymaze(expmt, handles);
            end
        case 6
            expmt = run_arenacircling(expmt,handles);
            analyze_arenacircling(expmt,handles);
        case 7
            expmt = run_ymaze(expmt,handles);
            analyze_ymaze(expmt,handles);
        case 8
            expmt = run_basictracking(expmt,handles);     % Run expmt
            analyze_basictracking(expmt,handles,0);
            
    end
    
    % remove saved rois, images, and noise statistics from prev experiment
    if isfield(expmt,'ROI') && ~keep_gui_state
        expmt = rmfield(expmt,'ROI');
        expmt = rmfield(expmt,'ref');
        expmt = rmfield(expmt,'noise');
        expmt = rmfield(expmt,'labels');
        msgbox(['Experiment complete: saved ROIs, references, ' ...
            'noise statistics, and labels have been reset.']);
        note = 'ROIs, references, and noise statistics reset';
        gui_notify(note,handles.disp_note);

        % set downstream UI panel enable status
        handles.tracking_uipanel.ForegroundColor = [0 0 0];
        set(findall(handles.tracking_uipanel, '-property', 'enable'), 'enable', 'off');
        set(findall(handles.exp_uipanel, '-property', 'enable'), 'enable', 'off');
        set(findall(handles.run_uipanel, '-property', 'enable'), 'enable', 'off');
    end
        
end

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);


% --- Executes on slider movement.
function ROI_thresh_slider_Callback(hObject, eventdata, handles)
% hObject    handle to ROI_thresh_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

expmt.parameters.ROI_thresh = get(handles.ROI_thresh_slider,'Value');
set(handles.disp_ROI_thresh,'string',num2str(round(expmt.parameters.ROI_thresh)));
guidata(hObject,handles);

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);


% --- Executes during object creation, after setting all properties.
function ROI_thresh_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ROI_thresh_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in accept_ROI_thresh_pushbutton.
function accept_ROI_thresh_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to accept_ROI_thresh_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

set(handles.accept_ROI_thresh_pushbutton,'value',1);
guidata(hObject,handles);

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);



function edit_frame_rate_Callback(hObject, eventdata, handles)
% hObject    handle to edit_frame_rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_frame_rate as text
%        str2double(get(hObject,'String')) returns contents of edit_frame_rate as a double


% --- Executes during object creation, after setting all properties.
function edit_frame_rate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_frame_rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in exp_select_popupmenu.
function exp_select_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to exp_select_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

expmt.expID = get(handles.exp_select_popupmenu,'Value');    % index of the experiment in exp list
names = get(handles.exp_select_popupmenu,'string');         % name of the experiment
expmt.Name = names{expmt.expID};                            % store name in master struct
expmt.parameters = trimParameters(expmt.parameters, handles);                 % remove all experiment specific parameters

% enable Experiment Parameters pushbutton if expID has an associated subgui
if ismember(expmt.expID,handles.parameter_subgui)
    handles.exp_parameter_pushbutton.Enable = 'on';
else
    handles.exp_parameter_pushbutton.Enable = 'off';
end

% if experiment parameters are set, enable experiment run panel
if expmt.expID > 1 && ~isempty(handles.save_path.String)
    set(findall(handles.run_uipanel, '-property', 'enable'),'enable','on');
end

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);
guidata(hObject,handles);

% Hints: contents = cellstr(get(hObject,'String')) returns exp_select_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from exp_select_popupmenu


% --- Executes during object creation, after setting all properties.
function exp_select_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to exp_select_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_time_remaining_Callback(hObject, eventdata, handles)
% hObject    handle to edit_time_remaining (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_time_remaining as text
%        str2double(get(hObject,'String')) returns contents of edit_time_remaining as a double


% --- Executes during object creation, after setting all properties.
function edit_time_remaining_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_time_remaining (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in exp_parameter_pushbutton.
function exp_parameter_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to exp_parameter_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

if expmt.expID<2
    errordlg('Please select an experiment first')
else
    switch expmt.expID

        case 3
            
                tmp_param = optomotor_parameter_gui(expmt.parameters);
                if ~isempty(tmp_param)
                    expmt.parameters = tmp_param;
                end

             
        case 4                       

                tmp_param = slowphototaxis_parameter_gui(expmt.parameters);
                if ~isempty(tmp_param)
                    expmt.parameters = tmp_param;
                end               
                
    end
end



% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);



% --- Executes on button press in refresh_COM_pushbutton.
function refresh_COM_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to refresh_COM_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Refresh items on the COM ports

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

   
% Attempt handshake with light panel teensy
[expmt.COM,handles.aux_COM_list] = identifyMicrocontrollers;

if ~isempty(handles.aux_COM_list)
% Update GUI menus with port names
set(handles.microcontroller_popupmenu,'string',expmt.COM);
else
set(handles.microcontroller_popupmenu,'string','COM not detected');
end

guidata(hObject,handles);

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);


% --- Executes on button press in enter_labels_pushbutton.
function enter_labels_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to enter_labels_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');


tmp_lbl = label_subgui(expmt);
if ~isempty(tmp_lbl)
    expmt.labels = tmp_lbl;
end



% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);



% --- Executes on slider movement.
function track_thresh_slider_Callback(hObject, eventdata, handles)
% hObject    handle to track_thresh_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

expmt.parameters.track_thresh = get(handles.track_thresh_slider,'Value');
set(handles.disp_track_thresh,'string',num2str(round(expmt.parameters.track_thresh)));

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);


guidata(hObject,handles);




% --- Executes during object creation, after setting all properties.
function track_thresh_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to track_thresh_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in accept_track_thresh_pushbutton.
function accept_track_thresh_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to accept_track_thresh_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

set(handles.accept_track_thresh_pushbutton,'value',1);

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);



function edit_numObj_Callback(hObject, eventdata, handles)
% hObject    handle to edit_numObj (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_numObj as text
%        str2double(get(hObject,'String')) returns contents of edit_numObj as a double


% --- Executes during object creation, after setting all properties.
function edit_numObj_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_numObj (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_object_num_Callback(hObject, eventdata, handles)
% hObject    handle to edit_object_num (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_object_num as text
%        str2double(get(hObject,'String')) returns contents of edit_object_num as a double


% --- Executes during object creation, after setting all properties.
function edit_object_num_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_object_num (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in reg_test_pushbutton.
function reg_test_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to reg_test_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in aux_COM_popupmenu.
function aux_COM_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to aux_COM_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns aux_COM_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from aux_COM_popupmenu

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

% Update GUI menus with port names
set(handles.aux_COM_popupmenu,'string',handles.aux_COM_list);

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);




% --- Executes during object creation, after setting all properties.
function aux_COM_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to aux_COM_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in refresh_aux_COM_pushbutton.
function refresh_aux_COM_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to refresh_aux_COM_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

% Attempt handshake with light panel teensy
[lightBoardPort,handles.aux_COM_list] = identifyMicrocontrollers;

% Assign unidentified ports to LED ymaze menu
if ~isempty(handles.aux_COM_list)
handles.aux_COM_port = handles.aux_COM_list(1);
else
handles.aux_COM_list = 'COM not detected';
handles.aux_COM_port = {handles.aux_COM_list};
end

% Update GUI menus with port names
set(handles.aux_COM_popupmenu,'string',handles.aux_COM_list);

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);




% --- Executes on selection change in param_prof_popupmenu.
function param_prof_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to param_prof_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(handles.param_prof_popupmenu,'value') ~= 1
    profiles = get(handles.param_prof_popupmenu,'string');
    profile = profiles(get(handles.param_prof_popupmenu,'value'));
    expmt = loadSavedParameters(handles,profile{:});
end

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);
guidata(hObject,handles);






% --- Executes during object creation, after setting all properties.
function param_prof_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to param_prof_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% Get existing profile list
gui_dir = which('autotrackergui');
gui_dir = gui_dir(1:strfind(gui_dir,'\gui\'));
load_path =[gui_dir 'profiles\'];
tmp_profiles = ls(load_path);
profiles = cell(size(tmp_profiles,1)+1,1);
profiles(1) = {'Select saved settings'};
remove = [];

for i = 1:size(profiles,1)-1;
    k = strfind(tmp_profiles(i,:),'.mat');
    if isempty(k)
        remove = [remove i+1];
    else
        profiles(i+1) = {tmp_profiles(i,1:k-1)};
    end
end

profiles(remove)=[];
if size(profiles,1) > 1
    set(hObject,'string',profiles);
else
    set(hObject,'string',{'No profiles detected'});
end


% --- Executes on button press in save_params_pushbutton.
function save_params_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to save_params_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

% set profile save path
save_path = [handles.gui_dir 'profiles\'];

[FileName,PathName] = uiputfile('*.mat','Enter name for new profile',save_path);

if any(FileName)
    replace = exist(strcat(PathName,FileName),'file')==2;
    save(strcat(PathName,FileName),'expmt');

    if replace
        profile_name = FileName(1:strfind(FileName,'.mat')-1);
        profiles = get(handles.param_prof_popupmenu,'string');
        
        for i = 1:length(profiles)
            if strcmp(profile_name,profiles{i});
                ri = i;
            end
        end
        
        profiles(ri) = {profile_name};
        set(handles.param_prof_popupmenu,'string',profiles);
        set(handles.param_prof_popupmenu,'value',ri);
        
    else
        profile_name = FileName(1:strfind(FileName,'.mat')-1);
        profiles = get(handles.param_prof_popupmenu,'string');
        profiles(1) = {'Select saved settings'};
        profiles(size(profiles,1)+1) = {profile_name};
        set(handles.param_prof_popupmenu,'string',profiles);
        set(handles.param_prof_popupmenu,'value',size(profiles,1));
    end
end


% --- Executes during object deletion, before destroying properties.
function ROI_thresh_slider_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to ROI_thresh_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in reference_pushbutton.
function reference_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to reference_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment variables
expmt = getappdata(handles.gui_fig,'expmt');

if isfield(expmt,'ROI')
    expmt = initializeRef(handles,expmt);
    handles.sample_noise_pushbutton.Enable = 'on';          % enable downstream control
else
    errordlg('ROI detection must be run before initializing references')
end

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);
guidata(hObject,handles);




% --- Executes on button press in sample_noise_pushbutton.
function sample_noise_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to sample_noise_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment variables
expmt = getappdata(handles.gui_fig,'expmt');

if isfield(expmt,'ref')
    
    expmt = sampleNoise(handles,expmt);
    
    % enable downstream controls
    handles.exp_uipanel.ForegroundColor = [0 0 0];
    ctls = findall(handles.exp_uipanel, '-property', 'enable'); % get control handles
    
    
    for i = 1:length(ctls)
        if strcmp(ctls(i).Tag,'exp_parameter_pushbutton')
            switch ctls(i).Enable                               % query state of exp_param_push
                case 'off'
                    del = i;                                    % remove from list if set to off
                case 'on'
                    del = [];
            end
        end
    end
    ctls(del) = [];
    
    % set controls in list to on
    set(ctls, 'enable', 'on');
    
    if ismember(expmt.expID,handles.parameter_subgui)
        handles.exp_parameter_pushbutton.Enable = 'on';
    end
    
    % if experiment parameters are set, enable experiment run panel
    if expmt.expID > 1 && ~isempty(handles.save_path.String)
        set(findall(handles.run_uipanel, '-property', 'enable'),'enable','on');
    end
    
else
    errordlg('Reference image required to sample tracking noise')
end

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);
guidata(hObject,handles);


% --- Executes on button press in auto_detect_ROIs_pushbutton.
function auto_detect_ROIs_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to auto_detect_ROIs_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment variables
expmt = getappdata(handles.gui_fig,'expmt');

% autodetect ROIs
if strcmp(expmt.source,'camera') && isfield(expmt.camInfo,'vid')
    
    expmt = autoROIs(handles, expmt);
    
    % enable downstream ui controls
    handles.track_thresh_slider.Enable = 'on';
    handles.accept_track_thresh_pushbutton.Enable = 'on';
    handles.reference_pushbutton.Enable = 'on';
    handles.track_thresh_label.Enable = 'on';
    handles.disp_track_thresh.Enable = 'on';
    
elseif strcmp(expmt.source,'camera')
    errordlg('Confirm camera and camera settings before running ROI detection');
end

if strcmp(expmt.source,'video') && isfield(expmt,'video')
     
    expmt = autoROIs(handles,expmt);
    
    % enable downstream UI controls
    handles.track_thresh_slider.Enable = 'on';
    handles.accept_track_thresh_pushbutton.Enable = 'on';
    handles.reference_pushbutton.Enable = 'on';
    handles.track_thresh_label.Enable = 'on';
    handles.disp_track_thresh.Enable = 'on';
    
elseif strcmp(expmt.source,'video')
    errordlg('Select valid video path before running ROI detection');
end



% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);
guidata(hObject,handles);




% ***************** Menu Items ******************** %




% --------------------------------------------------------------------
function hardware_props_menu_Callback(hObject, eventdata, handles)
% hObject    handle to hardware_props_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function display_menu_Callback(hObject, eventdata, handles)
% hObject    handle to display_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function cam_settings_menu_Callback(hObject, eventdata, handles)
% hObject    handle to cam_settings_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment variables
expmt = getappdata(handles.gui_fig,'expmt');

% run camera settings gui
expmt = cam_settings_subgui(handles,expmt);

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);
guidata(hObject,handles);




% --------------------------------------------------------------------
function proj_settings_menu_Callback(hObject, eventdata, handles)
% hObject    handle to proj_settings_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function file_menu_Callback(hObject, eventdata, handles)
% hObject    handle to file_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% --------------------------------------------------------------------
function display_difference_menu_Callback(hObject, eventdata, handles)
% hObject    handle to display_difference_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

chk = get(hObject,'checked');

if strcmp(chk,'off')
    handles.display_menu.UserData = 2;
    set(handles.display_difference_menu,'checked','on');
    set(handles.display_raw_menu,'checked','off');
    set(handles.display_threshold_menu,'checked','off');
    set(handles.display_reference_menu,'checked','off');
    set(handles.display_none_menu,'checked','off');
end

guidata(hObject,handles);


% --------------------------------------------------------------------
function display_raw_menu_Callback(hObject, eventdata, handles)
% hObject    handle to display_raw_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

chk = get(hObject,'checked');

if strcmp(chk,'off')
    handles.display_menu.UserData = 1;
    set(handles.display_difference_menu,'checked','off');
    set(handles.display_raw_menu,'checked','on');
    set(handles.display_threshold_menu,'checked','off');
    set(handles.display_reference_menu,'checked','off');
    set(handles.display_none_menu,'checked','off');
end

guidata(hObject,handles);


% --------------------------------------------------------------------
function display_threshold_menu_Callback(hObject, eventdata, handles)
% hObject    handle to display_threshold_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

chk = get(hObject,'checked');

if strcmp(chk,'off')
    handles.display_menu.UserData = 3;
    set(handles.display_difference_menu,'checked','off');
    set(handles.display_raw_menu,'checked','off');
    set(handles.display_threshold_menu,'checked','on');
    set(handles.display_reference_menu,'checked','off');
    set(handles.display_none_menu,'checked','off');
end

guidata(hObject,handles);

% --------------------------------------------------------------------
function display_reference_menu_Callback(hObject, eventdata, handles)
% hObject    handle to display_reference_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

chk = get(hObject,'checked');

if strcmp(chk,'off')
    handles.display_menu.UserData = 4;
    set(handles.display_difference_menu,'checked','off');
    set(handles.display_raw_menu,'checked','off');
    set(handles.display_threshold_menu,'checked','off');
    set(handles.display_reference_menu,'checked','on');
    set(handles.display_none_menu,'checked','off');
end

guidata(hObject,handles);


% --------------------------------------------------------------------
function display_none_menu_Callback(hObject, eventdata, handles)
% hObject    handle to display_none_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

chk = get(hObject,'checked');

if strcmp(chk,'off')
    handles.display_menu.UserData = 5;
    set(handles.display_difference_menu,'checked','off');
    set(handles.display_raw_menu,'checked','off');
    set(handles.display_threshold_menu,'checked','off');
    set(handles.display_reference_menu,'checked','off');
    set(handles.display_none_menu,'checked','on');
end

guidata(hObject,handles);


% --------------------------------------------------------------------
function reg_proj_menu_Callback(hObject, eventdata, handles)
% hObject    handle to reg_proj_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

expmt = getappdata(handles.gui_fig,'expmt');

if isfield(expmt,'reg_params')
    % Turn infrared and white background illumination off during registration
    writeInfraredWhitePanel(expmt.COM,1,0);
    writeInfraredWhitePanel(expmt.COM,0,0);

    msg_title = ['Projector Registration Tips'];
    spc = [' '];
    intro = ['Please check the following before continuing to ensure successful registration:'];
    item1 = ['1.) Both the infrared and white lights for imaging illumination are set to OFF. '...
        'Make sure the projector is the only light source visible to the camera'];
    item2 = ['2.) Camera is not imaging through infrared filter. '...
        'Projector display should be visible through the camera.'];
    item3 = ['3.) Projector is connected to the computer, turned on and set to desired resolution.'];
    item4 = ['4.) Camera shutter speed is adjusted to match the refresh rate of the projector.'...
        ' This will appear as moving streaks in the camera if not properly adjusted.'];
    item5 = ['5.) Both camera and projector are in fixed positions and will not need to be adjusted'...
        ' after registration.'];
    item6 = ['6.) The projector is set as the most external display (ie. the highest number display). Hint: '...
        'this is the most likely problem if the projector is connected but psych Toolbox is drawing to '...
        'the primary display. MATLAB must be restarted before this change will take effect.'];
    closing = ['Click OK to continue with the registration'];
    message = {intro spc item1 spc item2 spc item3 spc item4 spc item5 spc item6 spc closing};

    % Display registration tips
    waitfor(msgbox(message,msg_title));

    % Register projector
    reg_projector(expmt,handles);

    % Reset infrared and white lights to prior values
    writeInfraredWhitePanel(expmt.COM,1,expmt.light.infrared);
    writeInfraredWhitePanel(expmt.COM,0,expmt.light.white);
else
    errordlg('Set registration parameters before running projector registration.');
end

guidata(hObject, handles);


% --------------------------------------------------------------------
function reg_params_menu_Callback(hObject, eventdata, handles)


% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

if isfield(expmt,'reg_params')
    tmp = registration_parameter_subgui(expmt);
    if ~isempty(tmp)
        expmt.reg_params = tmp;
    end
else
        tmp = registration_parameter_subgui();
    if ~isempty(tmp)
        expmt.reg_params = tmp;
    end
end

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);


% --------------------------------------------------------------------
function reg_error_menu_Callback(hObject, eventdata, handles)
% hObject    handle to reg_error_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

expmt = getappdata(handles.gui_fig,'expmt');

if isfield(expmt,'reg_params')
    % Turn infrared and white background illumination off during registration
    writeInfraredWhitePanel(expmt.COM,1,0);
    writeInfraredWhitePanel(expmt.COM,0,0);

    msg_title = ['Registration Error Measurment'];
    spc = [' '];
    intro = ['Please check the following before continuing to ensure successful registration:'];
    item1 = ['1.) Both the infrared and white lights for imaging illumination are set to OFF. '...
        'Make sure the projector is the only light source visible to the camera'];
    item2 = ['2.) Camera is not imaging through infrared filter. '...
        'Projector display should be visible through the camera.'];
    item3 = ['3.) Projector is connected to the computer, turned on and set to desired resolution.'];
    item4 = ['4.) Camera shutter speed is adjusted to match the refresh rate of the projector.'...
        ' This will appear as moving streaks in the camera if not properly adjusted.'];
    item5 = ['5.) Both camera and projector are in fixed positions and will not need to be adjusted'...
        ' after registration.'];
    item6 = ['6.) The projector is set as the most external display (ie. the highest number display). Hint: '...
        'this is the most likely problem if the projector is connected but psych Toolbox is drawing to '...
        'the primary display. MATLAB must be restarted before this change will take effect.'];
    closing = ['Click OK to continue with the registration'];
    message = {intro spc item1 spc item2 spc item3 spc item4 spc item5 spc item6 spc closing};

    % Display registration tips
    waitfor(msgbox(message,msg_title));

    % Register projector
    projector_testFit(expmt,handles);

    % Reset infrared and white lights to prior values
    writeInfraredWhitePanel(expmt.COM,1,expmt.light.infrared);
    writeInfraredWhitePanel(expmt.COM,0,expmt.light.white);
else
    errordlg('Set registration parameters before running projector registration.');
end

guidata(hObject, handles);



% --------------------------------------------------------------------
function tracking_menu_Callback(hObject, eventdata, handles)
% hObject    handle to tracking_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function advanced_tracking_menu_Callback(hObject, eventdata, handles)
% hObject    handle to advanced_tracking_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

advancedTrackingParam_subgui(expmt,handles);
expmt.parameters.speed_thresh = handles.gui_fig.UserData.speed_thresh;
expmt.parameters.distance_thresh = handles.gui_fig.UserData.distance_thresh;
expmt.parameters.vignette_sigma = handles.gui_fig.UserData.vignette_sigma;
expmt.parameters.vignette_weight = handles.gui_fig.UserData.vignette_weight;
expmt.parameters.area_min = handles.gui_fig.UserData.area_min;
expmt.parameters.area_max = handles.gui_fig.UserData.area_max;
             
% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);


% --------------------------------------------------------------------
function distance_scale_menu_Callback(hObject, eventdata, handles)
% hObject    handle to distance_scale_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

tmp=setDistanceScale_subgui(handles,expmt.parameters);
delete(findobj('Tag','imline'));
if ~isempty(tmp)
    expmt.parameters.distance_scale = tmp;
    
    % update speed, distance, and area thresholds
    handles.gui_fig.UserData.speed_thresh =...
        handles.gui_fig.UserData.speed_thresh .* tmp.mm_per_pixel ./ expmt.parameters.mm_per_pix;
    handles.gui_fig.UserData.distance_thresh =...
        handles.gui_fig.UserData.distance_thresh .* tmp.mm_per_pixel ./ expmt.parameters.mm_per_pix;
    handles.gui_fig.UserData.area_min =...
        handles.gui_fig.UserData.area_min .* ((tmp.mm_per_pixel./expmt.parameters.mm_per_pix)^2);
    handles.gui_fig.UserData.area_max =...
        handles.gui_fig.UserData.area_max .* ((tmp.mm_per_pixel./expmt.parameters.mm_per_pix)^2);
    
    % set new parameter
    expmt.parameters.mm_per_pix = tmp.mm_per_pixel;
    
    if expmt.parameters.mm_per_pix ~= 1
        expmt.parameters.units = 'millimeters';
    end
end

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);


% --------------------------------------------------------------------
function Untitled_4_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function speed_thresh_menu_Callback(hObject, eventdata, handles)
% hObject    handle to speed_thresh_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function ROI_distance_thresh_menu_Callback(hObject, eventdata, handles)
% hObject    handle to ROI_distance_thresh_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Untitled_7_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Untitled_8_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when gui_fig is resized.
function gui_fig_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to gui_fig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get expmt data struct
expmt = getappdata(handles.gui_fig,'expmt');
axpos = handles.axes_handle.Position;

% calculate delta width and height
if isfield(handles,'fig_size')
    
    dw = handles.fig_size(3) - hObject.Position(3);
    dh = handles.fig_size(4) - hObject.Position(4);


    % adjust panel position to be constant
    panels = findobj(handles.gui_fig.Children,'Type','uipanel');
    for i = 1:length(panels)
        panels(i).Position(2) = panels(i).UserData(2) - dh;
    end

    handles.bottom_uipanel.Position(2) = handles.bottom_uipanel.UserData(2);
    handles.disp_note.Position(2) = handles.disp_note.UserData(2);
    if handles.bottom_uipanel.UserData(4) - dh > 0
        handles.bottom_uipanel.Position(4) = handles.bottom_uipanel.UserData(4) - dh;
    end
    if handles.disp_note.UserData(4) - dh > 0
            handles.disp_note.Position(4) = handles.disp_note.UserData(4) - dh;
    end
    
    if isfield(expmt.camInfo,'vid')

        handles.axes_handle.Position(3) = handles.gui_fig.Position(3) - handles.axes_handle.Position(1) - 10;
        handles.axes_handle.Position(4) = handles.gui_fig.Position(4) - handles.axes_handle.Position(2) - 5;

        res = expmt.camInfo.vid.VideoResolution;
        aspectR = res(2)/res(1);
        plot_aspect = pbaspect;
        fscale = aspectR/plot_aspect(2);

        axes_height_old = handles.axes_handle.Position(4);
        axes_height_new = axes_height_old*fscale;

        if axes_height_new + 10 > handles.gui_fig.Position(4)
     
            aspectR = res(1)/res(2);
            plot_aspect = pbaspect;
            plot_aspect = plot_aspect./plot_aspect(2);
            fscale = aspectR/plot_aspect(1);
            axes_width_old = handles.axes_handle.Position(3);
            axes_width_new = axes_width_old*fscale;
            handles.axes_handle.Position(3) = axes_width_new;
            
        else
            
            handles.axes_handle.Position(4) = axes_height_new;
            handles.axes_handle.Position(2) = handles.axes_handle.Position(2) + axes_height_old - axes_height_new;   
            
        end
        
    end

end

guidata(hObject,handles);


% --------------------------------------------------------------------
function load_video_menu_Callback(hObject, eventdata, handles)
% hObject    handle to load_video_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function saved_presets_menu_Callback(hObject, eventdata, handles)
% hObject    handle to saved_presets_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in vid_preview_togglebutton.
function vid_preview_togglebutton_Callback(hObject, eventdata, handles)
% hObject    handle to vid_preview_togglebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% update button appearance
if hObject.Value
    hObject.String = 'Stop Preview';
    hObject.BackgroundColor = [0.85 0.65 0.65];
else
    hObject.String = 'Start Preview';
    hObject.BackgroundColor = [0.94 0.94 0.94];
end

% get expmt data struct
expmt = getappdata(handles.gui_fig,'expmt');

if isfield(expmt,'video')
    
    % initialize axes and image settings
    if hObject.Value
        
        % adjust aspect ratio of plot to match camera
        colormap('gray');
        if isfield(expmt.video,'fID')
            vh = expmt.video.res(1);
            vw = expmt.video.res(2);
        else
            vh = expmt.video.vid.Height;
            vw = expmt.video.vid.Width;
        end
        im = uint8(zeros(vh,vw));
        handles.hImage = image(im,'Parent',handles.axes_handle);
        handles.axes_handle.XTick = [];
        handles.axes_handle.YTick = [];
        handles.axes_handle.Position(3) = ...
            handles.gui_fig.Position(3) - 5 - handles.axes_handle.Position(1);
        aspectR = vh/vw;
        plot_aspect = pbaspect;
        fscale = aspectR/plot_aspect(2);

        if fscale < 1
            axes_height_old = handles.axes_handle.Position(4);
            axes_height_new = axes_height_old*fscale;
            handles.axes_handle.Position(4) = axes_height_new;
            handles.axes_handle.Position(2) = handles.axes_handle.Position(2) + axes_height_old - axes_height_new;
        else
            aspectR = vw/vh;
            plot_aspect = pbaspect;
            plot_aspect = plot_aspect./plot_aspect(2);
            fscale = aspectR/plot_aspect(1);
            axes_width_old = handles.axes_handle.Position(3);
            axes_width_new = axes_width_old*fscale;
            handles.axes_handle.Position(3) = axes_width_new;
            handles.gui_fig.Position(3) = ...
                sum(handles.axes_handle.Position([1 3])) + 10;
        end       
        
        if isfield(expmt.video,'fID')
            handles.hImage.CDataMapping = 'scaled';
        else
            handles.hImage.CDataMapping = 'direct'; 
        end
    end
    

    
    % stream frames to the axes until the preview button is unticked
    ct=0;
    while hObject.Value
        
        tic
        ct = ct+1;
        
        % get next frame and update image
        [im, expmt.video] = nextFrame(expmt.video,handles);
        if size(im,3)>1
            im=im(:,:,2);
        end
        handles.hImage.CData = im; 
        
        % clear image and draw to screen
        clearvars im
        drawnow
        
        % update frame rate and frames remaining
        handles.edit_frame_rate.String = num2str(round(1/toc*10)/10);
        handles.edit_time_remaining.String = num2str(expmt.video.nFrames - ct);
 
    end
    

    
else
    errordlg('No video file path specified')
    hObject.String = 'Start Preview';
    hObject.BackgroundColor = [0.94 0.94 0.94];
    hObject.Value = 0;
end


% --- Executes on button press in pushbutton23.
function pushbutton23_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in vid_select_popupmenu.
function vid_select_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to vid_select_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get expmt data struct
expmt = getappdata(handles.gui_fig,'expmt');

% update current video object
expmt.video.vid = VideoReader([expmt.video.fdir expmt.video.fnames{hObject.Value}]);

% set expmt data struct
setappdata(handles.gui_fig,'expmt',expmt);



% Hints: contents = cellstr(get(hObject,'String')) returns vid_select_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from vid_select_popupmenu


% --- Executes during object creation, after setting all properties.
function vid_select_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vid_select_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_video_dir_Callback(hObject, eventdata, handles)
% hObject    handle to edit_video_dir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_video_dir as text
%        str2double(get(hObject,'String')) returns contents of edit_video_dir as a double


% --- Executes during object creation, after setting all properties.
function edit_video_dir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_video_dir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in video_files_pushbutton.
function video_files_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to video_files_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get expmt data struct
expmt = getappdata(handles.gui_fig,'expmt');

% get video files from file browser
tmp_video = uigetvids(expmt);

% update gui with video info
if ~isempty(tmp_video)
    expmt.video = tmp_video;
    handles.edit_video_dir.String = expmt.video.fdir;
    handles.vid_select_popupmenu.String = expmt.video.fnames;
    handles.edit_time_remaining.String = num2str(expmt.video.nFrames);
    
    % set downstream UI panel enable status
    handles.tracking_uipanel.ForegroundColor = [0 0 0];
    set(findall(handles.tracking_uipanel, '-property', 'enable'), 'enable', 'on');
    handles.distance_scale_menu.Enable = 'on';
    handles.vignette_correction_menu.Enable = 'on';
    handles.vid_select_popupmenu.Enable = 'on';
    handles.vid_preview_togglebutton.Enable = 'on';
    handles.select_video_label.Enable = 'on';

    if ~isfield(expmt,'ROI')
        handles.track_thresh_slider.Enable = 'off';
        handles.accept_track_thresh_pushbutton.Enable = 'off';
        handles.reference_pushbutton.Enable = 'off';
        handles.track_thresh_label.Enable = 'off';
        handles.disp_track_thresh.Enable = 'off';
    end

    if ~isfield(expmt,'ref')
        handles.sample_noise_pushbutton.Enable = 'off';
    end
end

% set expmt data struct
setappdata(handles.gui_fig,'expmt',expmt);


% --------------------------------------------------------------------
function select_source_menu_Callback(hObject, eventdata, handles)
% hObject    handle to select_source_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function source_camera_menu_Callback(hObject, eventdata, handles)
% hObject    handle to source_camera_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get expmt data struct
expmt = getappdata(handles.gui_fig,'expmt');

% update gui controls
if strcmp(expmt.source,'video')
    % disable all panels except cam/video and lighting
    handles.exp_uipanel.ForegroundColor = [.5   .5  .5];
    set(findall(handles.exp_uipanel, '-property', 'enable'), 'enable', 'off');
    handles.tracking_uipanel.ForegroundColor = [.5   .5  .5];
    set(findall(handles.tracking_uipanel, '-property', 'enable'), 'enable', 'off');
    handles.run_uipanel.ForegroundColor = [.5   .5  .5];
    set(findall(handles.run_uipanel, '-property', 'enable'), 'enable', 'off');
    handles.time_remaining_text.String = 'time remaining';
    handles.edit_time_remaining.String = '00:00:00';
    handles.vignette_correction_menu.Enable = 'off';
    handles.distance_scale_menu.Enable = 'off';
end

if strcmp(handles.cam_uipanel.Visible,'off')
    handles.cam_uipanel.Visible = 'on';
end

if strcmp(handles.vid_uipanel.Visible,'on')
    handles.vid_uipanel.Visible = 'off';
    handles.edit_video_dir.String = '';
    handles.vid_select_popupmenu.String = 'No video files loaded';
end

% remove video object
if isfield(expmt,'video')
    expmt = rmfield(expmt,'video');
end

% set source
expmt.source = 'camera';

% set expmt data struct
setappdata(handles.gui_fig,'expmt',expmt);




% --------------------------------------------------------------------
function source_video_menu_Callback(hObject, eventdata, handles)
% hObject    handle to source_video_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get expmt data struct
expmt = getappdata(handles.gui_fig,'expmt');

if strcmp(expmt.source,'camera')
    % disable all panels except cam/video and lighting
    handles.exp_uipanel.ForegroundColor = [.5   .5  .5];
    set(findall(handles.exp_uipanel, '-property', 'enable'), 'enable', 'off');
    handles.tracking_uipanel.ForegroundColor = [.5   .5  .5];
    set(findall(handles.tracking_uipanel, '-property', 'enable'), 'enable', 'off');
    handles.run_uipanel.ForegroundColor = [.5   .5  .5];
    set(findall(handles.run_uipanel, '-property', 'enable'), 'enable', 'off');
    handles.time_remaining_text.String = 'frames remaining';
    handles.edit_time_remaining.String = '-';
    handles.vignette_correction_menu.Enable = 'off';
    handles.distance_scale_menu.Enable = 'off';
    handles.vid_select_popupmenu.Enable = 'off';
    handles.vid_preview_togglebutton.Enable = 'off';
    handles.select_video_label.Enable = 'off';
    
    if isfield(expmt,'video')
        handles.ROI_thresh_slider.Enable = 'on';
        handles.accept_ROI_thresh_pushbutton.Enable = 'on';
        handles.disp_ROI_thresh.Enable = 'on';
        handles.auto_detect_ROIs_pushbutton.Enable = 'on';
        handles.text_object_num.Enable = 'on';
        handles.edit_object_num.Enable = 'on';
    end      
end

if strcmp(handles.vid_uipanel.Visible,'off')
    handles.vid_uipanel.Visible = 'on';
    handles.vid_uipanel.Position = handles.cam_uipanel.Position;
end

if strcmp(handles.cam_uipanel.Visible,'on')
    handles.cam_uipanel.Visible = 'off';
end

% remove video object
if isfield(expmt.camInfo,'vid') || isfield(expmt.camInfo,'src')
    expmt.camInfo = rmfield(expmt.camInfo,'vid');
    expmt.camInfo = rmfield(expmt.camInfo,'src');
end

% set source
expmt.source = 'video';

% set expmt data struct
setappdata(handles.gui_fig,'expmt',expmt);



% --------------------------------------------------------------------
function vignette_correction_menu_Callback(hObject, eventdata, handles)

expmt = getappdata(handles.gui_fig,'expmt');        % get expmt data struct
clean_gui(handles.axes_handle);                     % clear drawn objects
vid = true;

% Setup the camera and/or video object
if strcmp(expmt.source,'camera') && strcmp(expmt.camInfo.vid.Running,'off')
    
    % Clear old video objects
    imaqreset
    pause(0.2);

    % Create camera object with input parameters
    expmt.camInfo = initializeCamera(expmt.camInfo);
    start(expmt.camInfo.vid);
    pause(0.1);
    
elseif strcmp(expmt.source,'video') 
    
    % open video object from file
    expmt.video.vid = ...
        VideoReader([expmt.video.fdir expmt.video.fnames{gui_handles.vid_select_popupmenu.Value}]);
    
    expmt.video.ct = gui_handles.vid_select_popupmenu.Value;    % get file number in list

elseif ~strcmp(expmt.camInfo.vid.Running,'on')
    errordlg('Must confirm a camera or video source before correcting vignetting');
    vid = false;
end


if vid
    
    % Take single frame
    if strcmp(expmt.source,'camera')
        im = peekdata(expmt.camInfo.vid,1);
    else
        [im, expmt.video] = nextFrame(expmt.video,gui_handles);
    end
    
    % extract green channel if format is RGB
    if size(im,3)>1
        im = im(:,:,2);
    end
    
    % if an image already exists, display a preview of the vignette correction
    imh = findobj(handles.axes_handle,'-depth',3,'Type','image');
    imh.CData = im;
    
    % display instructions
    msg = ['Click and drag to draw a rectangle to select a dimly lit ROI or '...
        'region within an ROI. For best results, make sure the selection is '...
        'representative of the dimmest regions of the dimmest ROIs and '...
        'do not include additional ROIs in the selection.'];
    waitfor(msgbox(msg));

    % get ROI from the image
    roi = getrect(handles.axes_handle);
    roi(3) = roi(1) + roi(3);
    roi(4) = roi(2) + roi(4);
    expmt.vignette.im =filterVignetting(im,roi);
    expmt.vignette.mode = 'manual';
    
    imh.CData = im - expmt.vignette.im;
    text(handles.axes_handle.XLim(2)*0.01,handles.axes_handle.YLim(2)*0.01,...
        'Vignette Correction Preview','Color',[1 0 0]);
    
end

% set expmt data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);

function saved_preset_Callback(hObject, eventData)


gui_fig = hObject.Parent.Parent.Parent;     % get gui handles
expmt_new = getappdata(gui_fig,'expmt');        % get expmt data struct
load(hObject.UserData.path);

% load new settings in from file
expmt = load_settings(expmt,expmt_new,hObject.UserData.gui_handles);

% save loaded settings to master struct
setappdata(gui_fig,'expmt',expmt);  

guidata(gui_fig,hObject.UserData.gui_handles);


% --------------------------------------------------------------------
function save_new_preset_menu_Callback(hObject, eventdata, handles)
% hObject    handle to save_new_preset_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

if isfield(expmt.camInfo,'vid')
    expmt.camInfo = rmfield(expmt.camInfo,'vid');
end

if isfield(expmt.camInfo,'src')
    expmt.camInfo = rmfield(expmt.camInfo,'src');
end

% set profile save path
save_path = [handles.gui_dir 'profiles\'];

[FileName,PathName] = uiputfile('*.mat','Enter name for new profile',save_path);

if any(FileName)
    
    replace = exist(strcat(PathName,FileName),'file')==2;
    save(strcat(PathName,FileName),'expmt');

    if ~replace
        
        profile_name = FileName(1:strfind(FileName,'.mat')-1);
        hMenu = findobj('Tag','saved_presets_menu');
        new_menu_item = uimenu(hMenu,'Label',profile_name,...
        'Callback',@saved_preset_Callback);
        new_menu_item.UserData.index = length(hMenu.Children)+1;
        new_menu_item.UserData.path = strcat(PathName,FileName);
        new_menu_item.UserData.gui_handles = handles;
        
    end
end


% --------------------------------------------------------------------
function aux_com_menu_Callback(hObject, eventdata, handles)
% hObject    handle to aux_com_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function refresh_COM_menu_Callback(hObject, eventdata, handles)
% hObject    handle to refresh_COM_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%Close and delete any open serial objects
if ~isempty(instrfindall)
    fclose(instrfindall);           % Make sure that the COM port is closed
    delete(instrfindall);           % Delete any serial objects in memory
end

expmt = getappdata(handles.gui_fig,'expmt');                    % load master data struct

% Attempt handshake with light panel teensy
[expmt.COM,handles.aux_COM_list] = identifyMicrocontrollers;

% Update GUI menus with port names
set(handles.microcontroller_popupmenu,'string',expmt.COM);

% Initialize light panel at default values
IR_intensity = str2num(get(handles.edit_IR_intensity,'string'));
White_intensity = str2num(get(handles.edit_White_intensity,'string'));

% Convert intensity percentage to uint8 PWM value 0-255
expmt.light.infrared = uint8((IR_intensity/100)*255);
expmt.light.white = uint8((White_intensity/100)*255);

% Write values to microcontroller
writeInfraredWhitePanel(expmt.COM,1,expmt.light.infrared);
writeInfraredWhitePanel(expmt.COM,0,expmt.light.white);

% generate menu items for AUX COMs and config their callbacks
hParent = findobj('Tag','aux_com_menu');

% remove controls for existing list
del=[];
for i = 1:length(hParent.Children)
    if ~strcmp(hParent.Children(i).Label,'refresh list')
        del = [del i];
    end
end
delete(hParent.Children(del));

if isfield(expmt,'AUX_COM')
    expmt = rmfield(expmt,'AUX_COM');
end
        
% generate controls for new list
for i = 1:length(handles.aux_COM_list)
    menu_items(i) = uimenu(hParent,'Label',handles.aux_COM_list{i},...
        'Callback',@aux_com_list_Callback);
    if i ==1
        menu_items(i).Separator = 'on';
    end
end

% save loaded settings to master struct
setappdata(handles.gui_fig,'expmt',expmt);  
guidata(hObject,handles);

function aux_com_list_Callback(hObject, eventData)

gui_fig = hObject.Parent.Parent.Parent;                 % get gui_handle
expmt = getappdata(gui_fig,'expmt');                    % load master data struct

% update the gui menu and COM list
switch hObject.Checked
    
    case 'on'                                           
        
        hObject.Checked = 'off';                        % uncheck gui item if checked
        if length(expmt.AUX_COM)<2
            expmt = rmfield(expmt,'AUX_COM');           % remove AUX_COM if only one in list
        else
            del = [];                                   % delete the appropriate index in list if multiple items
            for i = 1:length(expmt.AUX_COM)
                if strcmp(expmt.AUX_COM{i},hObject.Label)
                	del = i;
                end
            end
            expmt.AUX_COM(del) = [];
        end

    case 'off'
        
        hObject.Checked = 'on';                                         % check the item if unchecked
        if isfield(expmt,'AUX_COM')
            expmt.AUX_COM(length(expmt.AUX_COM)+1) = {hObject.Label};   % add to the AUX_COM list
        else
            expmt.AUX_COM(1) = {hObject.Label};
        end
end



% save loaded settings to master struct
setappdata(gui_fig,'expmt',expmt);  


% --------------------------------------------------------------------
function refresh_cam_menu_Callback(hObject, eventdata, handles)
% hObject    handle to refresh_cam_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

expmt = getappdata(handles.gui_fig,'expmt');            % fetch master data struct
refresh = warningbox_subgui;                            % display warning and ask user whether or not to continue
if strcmp(refresh,'OK')
    expmt.camInfo = refresh_cam_list(handles);          % reset cameras and refresh gui lists
end

% save loaded settings to master struct
setappdata(handles.gui_fig,'expmt',expmt);  




% --- Executes on button press in pause_togglebutton.
function pause_togglebutton_Callback(hObject, eventdata, handles)
% hObject    handle to pause_togglebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

switch hObject.Value
    case 1
        hObject.String = 'Paused';
        hObject.BackgroundColor = [0.85 0.65 0.65];
    case 0
        hObject.String = 'Pause';
        hObject.BackgroundColor = [0.502 0.7529 0.8392];
end


% --- Executes on button press in record_vid_radiobutton.
function record_vid_radiobutton_Callback(hObject, eventdata, handles)
% hObject    handle to record_vid_radiobutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of record_vid_radiobutton


% --- Executes during object creation, after setting all properties.
function record_vid_radiobutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to record_vid_radiobutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --------------------------------------------------------------------
function record_video_menu_Callback(hObject, eventdata, handles)
% hObject    handle to record_video_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

switch hObject.Checked
    case 'off'
        hObject.Checked = 'on';
    case 'on'
        hObject.Checked = 'off';
end


function edit_dist_thresh_Callback(hObject, eventdata, handles)
% hObject    handle to edit_dist_thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.gui_fig.UserData.distance_thresh = str2num(hObject.String);
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_dist_thresh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_dist_thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_speed_thresh_Callback(hObject, eventdata, handles)
% hObject    handle to edit_speed_thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.gui_fig.UserData.speed_thresh = str2num(hObject.String);
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_speed_thresh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_speed_thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
