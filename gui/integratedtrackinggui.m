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

% Last Modified by GUIDE v2.5 13-Feb-2017 14:16:23

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

% store panel starting location for reference when resizing
handles.fig_size = handles.gui_fig.Position;
panels = findobj(handles.gui_fig.Children,'Type','uipanel');
for i = 1:length(panels)
    panels(i).UserData = panels(i).Position;
end
lighting_uipanel = findobj(handles.gui_fig.Children,'Title','Lighting');
handles.left_edge = lighting_uipanel.Position(1) + lighting_uipanel.Position(3);
handles.vid_uipanel.Position = handles.cam_uipanel.Position;


% Choose default command line output for integratedtrackinggui
handles.output = hObject;
handles.axes_handle = gca;
handles.gui_dir = which('autotrackergui');
handles.gui_dir = handles.gui_dir(1:strfind(handles.gui_dir,'\gui\'));
handles.display_menu.UserData = 1;
set(handles.ROI_thresh_slider,'value',0.15);
set(gca,'Xtick',[],'Ytick',[]);
expmt = [];

% Query available camera and modes
imaqreset
c = imaqhwinfo;

if ~isempty(c.InstalledAdaptors)
    
    % Select default adaptor for connected camera(s)
    ct=0;   
    cam_list = struct('name','','adaptor','','index',[]);

    for i = 1:length(c.InstalledAdaptors)
        camInfo = imaqhwinfo(c.InstalledAdaptors{i});
        if ~isempty(camInfo.DeviceIDs) && ~exist('adaptor','var')
            adaptor = i;
            for j = 1:length(camInfo.DeviceIDs)
                ct = ct + 1;
                cam_list(ct).name = camInfo.DeviceInfo(j).DeviceName;
                cam_list(ct).adaptor = c.InstalledAdaptors{adaptor};
                cam_list(ct).index = j;
            end
        end
    end
    handles.cam_list = cam_list;
    
    % populate camera select menu
    if exist('adaptor','var')
        camInfo = imaqhwinfo(c.InstalledAdaptors{adaptor});
        set(handles.cam_select_popupmenu,'string',{cam_list(:).name});
    end 
    

    % Set the device to default format and populate mode pop-up menu
    if ~isempty(camInfo.DeviceInfo);
    set(handles.cam_mode_popupmenu,'String',camInfo.DeviceInfo(1).SupportedFormats);
    default_format = camInfo.DeviceInfo.DefaultFormat;

        for i = 1:length(camInfo.DeviceInfo(1).SupportedFormats)
            if strcmp(default_format,camInfo.DeviceInfo(1).SupportedFormats{i})
                set(handles.cam_mode_popupmenu,'Value',i);
                camInfo.ActiveMode = camInfo.DeviceInfo(1).SupportedFormats(i);
            end
        end

    else
    set(handles.cam_select_popupmenu,'String','Camera not detected');
    set(handles.cam_mode_popupmenu,'String','');
    end
    
    camInfo.activeID = 1;
    expmt.camInfo = camInfo;
    
else
    expmt.camInfo=[];
    set(handles.cam_select_popupmenu,'String','No camera adaptors installed');
    set(handles.cam_mode_popupmenu,'String','');
end
    


% Initialize teensy for motor and light board control

%Close and delete any open serial objects
if ~isempty(instrfindall)
fclose(instrfindall);           % Make sure that the COM port is closed
delete(instrfindall);           % Delete any serial objects in memory
end

% Attempt handshake with light panel teensy
[expmt.teensy_port,ports] = identifyMicrocontrollers;

% Update GUI menus with port names
set(handles.microcontroller_popupmenu,'string',expmt.teensy_port);

% Initialize light panel at default values
IR_intensity = str2num(get(handles.edit_IR_intensity,'string'));
White_intensity = str2num(get(handles.edit_White_intensity,'string'));

% Convert intensity percentage to uint8 PWM value 0-255
expmt.IR_intensity = uint8((IR_intensity/100)*255);
expmt.White_intensity = uint8((White_intensity/100)*255);

% Write values to microcontroller
writeInfraredWhitePanel(expmt.teensy_port,1,expmt.IR_intensity);
writeInfraredWhitePanel(expmt.teensy_port,0,expmt.White_intensity);

% Initialize expmteriment parameters from text boxes in the GUI
handles.edit_ref_depth.Value  =  str2num(get(handles.edit_ref_depth,'String'));
handles.edit_ref_freq.Value = str2num(get(handles.edit_ref_freq,'String'));
handles.edit_exp_duration.Value = str2num(get(handles.edit_exp_duration,'String'));
expmt.parameters.ROI_thresh = get(handles.ROI_thresh_slider,'Value');
expmt.parameters.tracking_thresh = get(handles.track_thresh_slider,'Value');

% initialize tracking parameters to default values
handles.gui_fig.UserData.speed_thresh = 45;
handles.gui_fig.UserData.distance_thresh = 20;
handles.gui_fig.UserData.vignette_sigma = 0.47;
handles.gui_fig.UserData.vignette_weight = 0.35;
handles.gui_fig.UserData.area_min = 4;
handles.gui_fig.UserData.area_max = 300;

if ~isempty(expmt.camInfo)
    handles.gui_fig.UserData.target_rate = round(estimateFrameRate(expmt.camInfo)*10)/10;
else
    handles.gui_fig.UserData.target_rate = 60;
end

setappdata(handles.gui_fig,'expmt',expmt);

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
        pause(0.5);
        
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
        
        colormap('gray');
        set(gca,'Xtick',[],'Ytick',[]);
        
        if isfield(expmt,'ROI') && isfield(expmt,'ref') &&  isfield(expmt,'noise')
            rmfield(expmt,'ROI');
            rmfield(expmt,'ref');
            rmfield(expmt,'noise');
            msgbox(['Cam settings changed: saved ROIs, references and ' ...
                'noise statistics have been discarded.']);
        elseif isfield(expmt,'ROI') && isfield(expmt,'ref')
            rmfield(expmt,'ROI');
            rmfield(expmt,'ref');
            msgbox(['Cam settings changed: saved ROIs, references ' ...
                'have been discarded.']);
        elseif isfield(expmt,'ROI')
           rmfield(expmt,'ROI');
           msgbox(['Cam settings changed: saved ROIs ' ...
                'have been discarded.']);
        end
        
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
            set(hObject,'string','Start preview','BackgroundColor',[1 1 1]);
        end
end

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);


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

expmt.IR_intensity = str2num(get(handles.edit_IR_intensity,'string'));

% Convert intensity percentage to uint8 PWM value 0-255
expmt.IR_intensity = uint8((expmt.IR_intensity/100)*255);

writeInfraredWhitePanel(expmt.teensy_port,1,expmt.IR_intensity);

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
expmt.White_intensity = uint8((White_intensity/100)*255);
writeInfraredWhitePanel(expmt.teensy_port,0,expmt.White_intensity);

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

data = cell(5,8);
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

if isfield(expmt, 'fpath') == 0 
    errordlg('Please specify Save Location')
elseif ~isfield(expmt, 'camInfo')
    errordlg('Please confirm camera settings')
else
    switch expmt.expID
    	case 2
            projector_escape_response;
        case 3
            projector_optomotor;
        case 4
            projector_slow_phototaxis;
        case 5
            autoTracker_led;
        case 6
            autoTracker_arena;
        case 7
            expmt = experiment_template(expmt,handles);     % Run expmt
            analysis_template(expmt,'plot');
            
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
set(handles.disp_ROI_thresh,'string',num2str(round(100*expmt.parameters.ROI_thresh)/100));
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

expmt.expID = get(handles.exp_select_popupmenu,'Value');
names = get(handles.exp_select_popupmenu,'string');
expmt.Name = names{expmt.expID};
expmt.parameters = trimParameters(handles);

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


% --- Executes on button press in begin_reg_button.
function begin_reg_button_Callback(hObject, eventdata, handles)
% hObject    handle to begin_reg_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');


% Turn infrared and white background illumination off during registration
writeInfraredWhitePanel(expmt.teensy_port,1,0);
writeInfraredWhitePanel(expmt.teensy_port,0,0);

msg_title = ['Projector Registration Tips'];
spc = [' '];
intro = ['Please check the following before continuing to ensure successful registration:'];
item1 = ['1.) Both the infrared and white lights for imaging illumination are set to OFF. '...
    'Make sure the projector is the only light source visible to the camera'];
item2 = ['2.) Camera is not imaging through infrared filter. '...
    'Projector display should be visible through the camera.'];
item3 = ['3.) Projector is turned on and set to desired resolution.'];
item4 = ['4.) Camera shutter speed is adjusted to match the refresh rate of the projector.'...
    ' This will appear as moving streaks in the camera if not properly adjusted.'];
item5 = ['5.) Both camera and projector are in fixed positions and will not need to be adjusted'...
    ' after registration.'];
closing = ['Click OK to continue with the registration'];
message = {intro spc item1 spc item2 spc item3 spc item4 spc item5 spc closing};

% Display registration tips
waitfor(msgbox(message,msg_title));

% Register projector
reg_projector(expmt.camInfo,expmt.pixel_step_size,expmt.step_interval,expmt.reg_spot_r,handles.edit_time_remaining);

% Reset infrared and white lights to prior values
writeInfraredWhitePanel(expmt.teensy_port,1,expmt.IR_intensity);
writeInfraredWhitePanel(expmt.teensy_port,0,expmt.White_intensity);

guidata(hObject,handles);

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);


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
errordlg('Please select an expmteriment first')
else
    switch expmt.expID
        case 2

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
[expmt.teensy_port,ports] = identifyMicrocontrollers;

if ~isempty(ports)
% Update GUI menus with port names
set(handles.microcontroller_popupmenu,'string',expmt.teensy_port);
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

if isfield(expmt,'labels')
    tmp_lbl = label_subgui(expmt.labels);
    if ~isempty(tmp_lbl)
        expmt.labels = tmp_lbl;
    end
else
    tmp_lbl = label_subgui;
    if ~isempty(tmp_lbl)
        expmt.labels = tmp_lbl;
    end
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

expmt.parameters.tracking_thresh = get(handles.track_thresh_slider,'Value');
set(handles.disp_track_thresh,'string',num2str(round(expmt.parameters.tracking_thresh*100)/100));

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


% --- Executes on button press in begin_reg_pushbutton.
function begin_reg_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to begin_reg_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

expmt = getappdata(handles.gui_fig,'expmt');

if isfield(expmt,'reg_params')
    % Turn infrared and white background illumination off during registration
    writeInfraredWhitePanel(expmt.teensy_port,1,0);
    writeInfraredWhitePanel(expmt.teensy_port,0,0);

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
    reg_projector(expmt.camInfo,expmt.reg_params,handles);

    % Reset infrared and white lights to prior values
    writeInfraredWhitePanel(handles.teensy_port,1,handles.IR_intensity);
    writeInfraredWhitePanel(handles.teensy_port,0,handles.White_intensity);
else
    errordlg('Set registration parameters before running projector registration.');
end

guidata(hObject, handles);


% --- Executes on button press in reg_param_pushbutton.
function reg_param_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to reg_param_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

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
set(handles.aux_COM_popupmenu,'string',ports);

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
[lightBoardPort,ports] = identifyMicrocontrollers;

% Assign unidentified ports to LED ymaze menu
if ~isempty(ports)
handles.aux_COM_port = ports(1);
else
ports = 'COM not detected';
handles.aux_COM_port = {ports};
end

% Update GUI menus with port names
set(handles.aux_COM_popupmenu,'string',ports);

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
[corners, centers, orientation, bounds, im] = autoROIs(handles);

expmt.ROI = [];
expmt.ROI.corners = corners;
expmt.ROI.centers = centers;
expmt.ROI.orientation = orientation;
expmt.ROI.bounds = bounds;
expmt.ROI.im = im;

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


% --------------------------------------------------------------------
function reg_params_menu_Callback(hObject, eventdata, handles)
% hObject    handle to reg_params_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function reg_error_menu_Callback(hObject, eventdata, handles)
% hObject    handle to reg_error_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


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

% Hint: get(hObject,'Value') returns toggle state of vid_preview_togglebutton


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



function edit38_Callback(hObject, eventdata, handles)
% hObject    handle to edit38 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit38 as text
%        str2double(get(hObject,'String')) returns contents of edit38 as a double


% --- Executes during object creation, after setting all properties.
function edit38_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit38 (see GCBO)
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

if strcmp(handles.cam_uipanel.Visible,'off')
    handles.cam_uipanel.Visible = 'on';
end

if strcmp(handles.vid_uipanel.Visible,'on')
    handles.vid_uipanel.Visible = 'off';
end


% --------------------------------------------------------------------
function source_video_menu_Callback(hObject, eventdata, handles)
% hObject    handle to source_video_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmp(handles.vid_uipanel.Visible,'off')
    handles.vid_uipanel.Visible = 'on';
    handles.vid_uipanel.Position = handles.cam_uipanel.Position;
end

if strcmp(handles.cam_uipanel.Visible,'on')
    handles.cam_uipanel.Visible = 'off';
end

