
function varargout = autotrackergui(varargin)
% AUTOTRACKERGUI MATLAB code for autotrackergui.fig
%      AUTOTRACKERGUI, by itself, creates a new AUTOTRACKERGUI or raises the existing
%      singleton*.
%
%      H = AUTOTRACKERGUI returns the handle to a new AUTOTRACKERGUI or the handle to
%      the existing singleton*.
%
%      AUTOTRACKERGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in AUTOTRACKERGUI.M with the given input arguments.
%
%      AUTOTRACKERGUI('Property','Value',...) creates a new AUTOTRACKERGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before autotrackergui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to autotrackergui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help autotrackergui

% Last Modified by GUIDE v2.5 05-Sep-2016 20:44:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @autotrackergui_OpeningFcn, ...
                   'gui_OutputFcn',  @autotrackergui_OutputFcn, ...
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


% --- Executes just before autotrackergui is made visible.
function autotrackergui_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to autotrackergui (see VARARGIN)

%% Query available camera and modes
imaqreset
c=imaqhwinfo;

% Select appropriate adaptor for connected camera
for i=1:length(c.InstalledAdaptors)
    camInfo=imaqhwinfo(c.InstalledAdaptors{i});
    if ~isempty(camInfo.DeviceIDs)
        adaptor=i;
    end
end
camInfo=imaqhwinfo(c.InstalledAdaptors{adaptor});

% Set the device to default format and populate pop-up menu
if ~isempty(camInfo.DeviceInfo.SupportedFormats);
set(handles.Cam_popupmenu,'String',camInfo.DeviceInfo.SupportedFormats);
default_format=camInfo.DeviceInfo.DefaultFormat;

    for i=1:length(camInfo.DeviceInfo.SupportedFormats)
        if strcmp(default_format,camInfo.DeviceInfo.SupportedFormats{i})
            set(handles.Cam_popupmenu,'Value',i);
            camInfo.ActiveMode=camInfo.DeviceInfo.SupportedFormats(i);
        end
    end
    
else
set(handles.Cam_popupmenu,'String','Camera not detected');
end
handles.camInfo=camInfo;

%% Set default experimental values

axes(handles.axes2)
handles.ref_stack_size=str2num(get(handles.edit_ref_stack_size,'String')); %#ok<*ST2NM>
handles.ref_freq=str2num(get(handles.edit_ref_freq,'String'));
handles.exp_duration=str2num(get(handles.edit_exp_duration,'String'));
handles.tracking_thresh=get(handles.threshold_slider,'Value');
handles.camInfo.Gain=str2num(get(handles.edit_gain,'String'));
handles.camInfo.Exposure=str2num(get(handles.edit_exposure,'String'));
handles.camInfo.Shutter=str2num(get(handles.edit_cam_shutter,'String'));
handles.experiment=1;

%% Initialize teensy for motor and light board control

% Close and delete any open serial objects
if ~isempty(instrfindall)
fclose(instrfindall);           % Make sure that the COM port is closed
delete(instrfindall);           % Delete any serial objects in memory
end

% Attempt handshake with light panel teensy
[lightBoardPort,ports]=identifyMicrocontrollers;
handles.lightBoardPort=lightBoardPort;

% Assign unidentified ports to LED ymaze menu
if ~isempty(ports)
handles.LED_ymaze_port=ports(1);
else
ports='COM not detected';
handles.LED_ymaze_port={ports};
end

% Update GUI menus with port names
set(handles.LED_Ymaze_COM_popupmenu,'string',ports);
set(handles.light_COM_popupmenu,'string',lightBoardPort);

% Initialize light panel at default values
IR_intensity=str2num(get(handles.edit11,'string'));
White_intensity=str2num(get(handles.edit12,'string'));

% Convert intensity percentage to uint8 PWM value 0-255
IR_intensity=uint8((IR_intensity/100)*255);
White_intensity=uint8((White_intensity/100)*255);

% Write values to microcontroller
writeInfraredWhitePanel(handles.lightBoardPort,0,IR_intensity);
writeInfraredWhitePanel(handles.lightBoardPort,1,White_intensity);

% Choose default command line output for autotrackergui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes autotrackergui wait for user response (see UIRESUME)
 %uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = autotrackergui_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure

varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function uitable2_CreateFcn(hObject, ~, ~)
% hObject    handle to uitable2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
data=cell(5,8);
data(:)={''};
handles.labels=data;
set(hObject, 'Data', data);
guidata(hObject, handles);

% --- Executes when entered data in editable cell(s) in uitable2.
function uitable2_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitable2 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
handles.labels{eventdata.Indices(1), eventdata.Indices(2)} = {''};
handles.labels{eventdata.Indices(1), eventdata.Indices(2)} = eventdata.NewData;
guidata(hObject, handles);

function edit_exp_duration_Callback(hObject, ~, handles)
% hObject    handle to edit_exp_duration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.expDuration = str2double(get(hObject,'String'));
guidata(hObject, handles)
% Hints: get(hObject,'String') returns contents of edit_exp_duration as text
%        str2double(get(hObject,'String')) returns contents of edit_exp_duration as a double


% --- Executes during object creation, after setting all properties.
function edit_exp_duration_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_exp_duration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_ref_stack_size_Callback(hObject, ~, handles)
% hObject    handle to edit_ref_stack_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.refStack = str2double(get(hObject,'String'));
guidata(hObject, handles)
% Hints: get(hObject,'String') returns contents of edit_ref_stack_size as text
%        str2double(get(hObject,'String')) returns contents of edit_ref_stack_size as a double


% --- Executes during object creation, after setting all properties.
function edit_ref_stack_size_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_ref_stack_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_ref_freq_Callback(hObject, ~, handles)
% hObject    handle to edit_ref_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.refTime = str2double(get(hObject,'String'));
guidata(hObject, handles)
% Hints: get(hObject,'String') returns contents of edit_ref_freq as text
%        str2double(get(hObject,'String')) returns contents of edit_ref_freq as a double


% --- Executes during object creation, after setting all properties.
function edit_ref_freq_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_ref_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function togglebutton7_CreateFcn(~, ~, ~)
% hObject    handle to togglebutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes on button press in Refresh COM.
function togglebutton7_Callback(hObject, ~, handles)

% Refresh items on the COM ports
if get(hObject,'value')==1
   
    % Attempt handshake with light panel teensy
    [lightBoardPort,ports]=identifyMicrocontrollers;    
    handles.lightBoardPort=lightBoardPort;

    if ~isempty(ports)
    handles.LED_ymaze_port=ports(1);
    else
    ports='COM not detected';
    handles.LED_ymaze_port={ports};
    end

    % Update GUI menus with port names
    set(handles.LED_Ymaze_COM_popupmenu,'string',ports);
    set(handles.light_COM_popupmenu,'string',lightBoardPort);
    
    % reset the push button
    set(hObject, 'value', 0);   
end

guidata(hObject,handles);

% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, ~, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[fpath] = uigetdir('C:\Users\OEB131-B\Desktop\AutoTracker Test','Select a save destination');
handles.fpath=fpath;

set(handles.edit_file_path,'String',fpath);

guidata(hObject,handles);

% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, ~, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles, 'fpath') == 0 
    errordlg('Please specify Save Location')
elseif handles.experiment == 1 
    errordlg('Please select an experiment type on the menu bar')
else
    switch handles.experiment
    	case 2
            autoTrackerV2_ymaze120;
        case 3
            autoTrackerV2_ymaze96;
           
        case 4
            autoTrackerV2_arena;
        case 5
            autoTrackerV2_led;
    end
end

% --- Executes during object creation, after setting all properties.
function axes2_CreateFcn(~, ~, ~)
% hObject    handle to axes2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes2


% --- Executes during object deletion, before destroying properties.
function axes2_DeleteFcn(~, ~, ~) %#ok<*DEFNU>
% hObject    handle to axes2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object deletion, before destroying properties.
function uitable2_DeleteFcn(~, ~, ~)
% hObject    handle to uitable2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object deletion, before destroying properties.
function edit_exp_duration_DeleteFcn(~, ~, ~)
% hObject    handle to edit_exp_duration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object deletion, before destroying properties.
function edit_ref_stack_size_DeleteFcn(~, ~, ~)
% hObject    handle to edit_ref_stack_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object deletion, before destroying properties.
function edit_ref_freq_DeleteFcn(~, ~, ~)
% hObject    handle to edit_ref_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object deletion, before destroying properties.
function pushbutton2_DeleteFcn(~, ~, ~)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% 

function edit_file_path_Callback(~, ~, ~)
% hObject    handle to edit_file_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_file_path as text
%        str2double(get(hObject,'String')) returns contents of edit_file_path as a double


% --- Executes during object creation, after setting all properties.
function edit_file_path_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_file_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pause_togglebutton.
function pause_togglebutton_Callback(hObject, ~, handles)
% hObject    handle to pause_togglebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value') == 0;
   set(hObject, 'BackgroundColor', [1 0.6 0.6]);
   set(hObject, 'String', 'Pause Experiment');
end
if get(hObject,'Value') == 1;
   set(hObject, 'BackgroundColor', [1 0.5 0]);
   set(hObject, 'String', 'Resume');
end
guidata(hObject,handles);
% Hint: get(hObject,'Value') returns toggle state of pause_togglebutton


% --- Executes during object creation, after setting all properties.
function pause_togglebutton_CreateFcn(~, ~, ~)
% hObject    handle to pause_togglebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object deletion, before destroying properties.
function pause_togglebutton_DeleteFcn(~, ~, ~)
% hObject    handle to pause_togglebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function edit_time_remaining_Callback(hObject, eventdata, handles) %#ok<*INUSD>
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

% --- Executes on button press in accept_thresh_togglebutton.
function accept_thresh_togglebutton_Callback(hObject, eventdata, handles)
% hObject    handle to accept_thresh_togglebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of accept_thresh_togglebutton


% --- Executes on slider movement.
function threshold_slider_Callback(hObject, eventdata, handles)
% hObject    handle to threshold_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function threshold_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshold_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function edit_num_ROIs_Callback(hObject, eventdata, handles)
% hObject    handle to edit_num_ROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_num_ROIs as text
%        str2double(get(hObject,'String')) returns contents of edit_num_ROIs as a double


% --- Executes during object creation, after setting all properties.
function edit_num_ROIs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_num_ROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



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

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes when figure1 is resized.
function figure1_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit_frame_delay_Callback(hObject, eventdata, handles)
% hObject    handle to edit_frame_delay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_frame_delay as text
%        str2double(get(hObject,'String')) returns contents of edit_frame_delay as a double


% --- Executes during object creation, after setting all properties.
function edit_frame_delay_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_frame_delay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function experiment_select_Callback(hObject, eventdata, handles)
% hObject    handle to experiment_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LED_Ymaze_COM_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in LED_Ymaze_COM_popupmenu.
function LED_Ymaze_COM_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to LED_Ymaze_COM_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

strCell=get(handles.LED_Ymaze_COM_popupmenu,'string');
handles.LED_ymaze_port=strCell(get(handles.LED_Ymaze_COM_popupmenu,'Value'));
handles.LED_ymaze_port
guidata(hObject, handles);

% Hints: contents = cellstr(get(hObject,'String')) returns LED_Ymaze_COM_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from LED_Ymaze_COM_popupmenu


% --- Executes during object creation, after setting all properties.
function LED_Ymaze_COM_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LED_Ymaze_COM_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
guidata(hObject, handles);


% --- Executes on selection change in exp_select_popupmenu.
function exp_select_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to exp_select_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.experiment=get(handles.exp_select_popupmenu,'Value');

switch handles.experiment
    case 2
        data = get(handles.uitable2, 'Data');
        data(1,4:5) = {'1' '120'};
        set(handles.uitable2, 'Data', data);
        handles.labels(1,4:5) = {'1' '120'};
    case 3
        data = get(handles.uitable2, 'Data');
        data(1,4:5) = {'1' '96'};
        set(handles.uitable2, 'Data', data);
        handles.labels(1,4:5) = {'1' '96'};
    case 4
        data = get(handles.uitable2, 'Data');
        data(1,4:5) = {'1' '48'};
        set(handles.uitable2, 'Data', data);
        handles.labels(1,4:5) = {'1' '48'};
    case 5
        data = get(handles.uitable2, 'Data');
        data(1,4:5) = {'1' '72'};
        handles.labels(1,4:5) = {'1' '72'};
        set(handles.uitable2, 'Data', data);
end     
guidata(hObject, handles);



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



function edit11_Callback(hObject, eventdata, handles)
% hObject    handle to edit11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

IR_intensity=str2num(get(handles.edit11,'string'));
% Convert intensity percentage to uint8 PWM value 0-255
if IR_intensity>100
    IR_intensity=100;
    set(handles.edit11,'string','100');
end
IR_intensity=uint8((IR_intensity/100)*255);
writeInfraredWhitePanel(handles.lightBoardPort,0,IR_intensity);


% Hints: get(hObject,'String') returns contents of edit11 as text
%        str2double(get(hObject,'String')) returns contents of edit11 as a double


% --- Executes during object creation, after setting all properties.
function edit11_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit12_Callback(hObject, eventdata, handles)
% hObject    handle to edit12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Convert intensity percentage to uint8 PWM value 0-255
White_intensity=str2num(get(handles.edit12,'string'));
if White_intensity>100
    White_intensity=100;
    set(handles.edit12,'string','100');
end
White_intensity=uint8((White_intensity/100)*255);
writeInfraredWhitePanel(handles.lightBoardPort,1,White_intensity);

% Hints: get(hObject,'String') returns contents of edit12 as text
%        str2double(get(hObject,'String')) returns contents of edit12 as a double


% --- Executes during object creation, after setting all properties.
function edit12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in LED_Ymaze_COM_popupmenu.
function light_COM_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to LED_Ymaze_COM_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
strCell=get(handles.light_COM_popupmenu,'string');
handles.lightBoardPort=strCell(get(handles.light_COM_popupmenu,'Value'));
guidata(hObject, handles);

% Hints: contents = cellstr(get(hObject,'String')) returns LED_Ymaze_COM_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from LED_Ymaze_COM_popupmenu


% --- Executes during object creation, after setting all properties.
function light_COM_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LED_Ymaze_COM_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in Cam_popupmenu.
function Cam_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to Cam_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
strCell=get(handles.Cam_popupmenu,'string');
handles.camInfo.ActiveMode=strCell(get(handles.Cam_popupmenu,'Value'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function Cam_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Cam_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_exposure_Callback(hObject, eventdata, handles)
% hObject    handle to edit_exposure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.camInfo.Exposure=str2num(get(handles.edit_exposure,'String'));

% If video is in preview mode, update the camera immediately
if isfield(handles,'src')
    handles.src.Exposure=handles.camInfo.Exposure;
end

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_exposure_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_exposure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_gain_Callback(hObject, eventdata, handles)
% hObject    handle to edit_gain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.camInfo.Gain=str2num(get(handles.edit_gain,'String'));

% If video is in preview mode, update the camera immediately
if isfield(handles,'src')
    handles.src.Gain=handles.camInfo.Gain;
end

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_gain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_gain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in Cam_confirm_pushbutton.
function Cam_confirm_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Cam_confirm_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
imaqreset;
pause(0.02);
handles.vid=initializeCamera(handles.camInfo);
handles.src=getselectedsource(handles.vid);
start(handles.vid);
pause(0.1);
im=peekdata(handles.vid,1);
handles.hImage=image(im);
set(gca,'Xtick',[],'Ytick',[]);
stop(handles.vid);
guidata(hObject, handles);


% --- Executes on button press in Cam_preview_pushbutton.
function Cam_preview_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Cam_preview_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 'vid') == 0
    errordlg('Please confirm camera settings')
else
    preview(handles.vid,handles.hImage);       
end


% --- Executes on button press in Cam_stopPreview_pushbutton.
function Cam_stopPreview_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Cam_stopPreview_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.Cam_preview_pushbutton,'Value',0);
set(handles.Cam_stopPreview_pushbutton,'Value',0);
stoppreview(handles.vid);
rmfield(handles,'src');
guidata(hObject, handles);


function edit_cam_shutter_Callback(hObject, eventdata, handles)
% hObject    handle to edit_cam_shutter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_cam_shutter as text
%        str2double(get(hObject,'String')) returns contents of edit_cam_shutter as a double
handles.camInfo.Shutter=str2num(get(handles.edit_cam_shutter,'String'));

% If video is in preview mode, update the camera immediately
if isfield(handles,'src')
    handles.src.Shutter=handles.camInfo.Shutter;
end

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_cam_shutter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_cam_shutter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
