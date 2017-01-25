function varargout = registration_parameter_gui(varargin)
% REGISTRATION_PARAMETER_GUI MATLAB code for registration_parameter_gui.fig
%      REGISTRATION_PARAMETER_GUI, by itself, creates a new REGISTRATION_PARAMETER_GUI or raises the existing
%      singleton*.
%
%      H = REGISTRATION_PARAMETER_GUI returns the handle to a new REGISTRATION_PARAMETER_GUI or the handle to
%      the existing singleton*.
%
%      REGISTRATION_PARAMETER_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in REGISTRATION_PARAMETER_GUI.M with the given input arguments.
%
%      REGISTRATION_PARAMETER_GUI('Property','Value',...) creates a new REGISTRATION_PARAMETER_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before registration_parameter_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to registration_parameter_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help registration_parameter_gui

% Last Modified by GUIDE v2.5 25-Jan-2017 16:03:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @registration_parameter_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @registration_parameter_gui_OutputFcn, ...
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




% --- Executes just before registration_parameter_gui is made visible.
function registration_parameter_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to registration_parameter_gui (see VARARGIN)

if ~isempty(varargin)
    param_data = varargin{1};
    handles.output=param_data;
    set(handles.edit_stim_duration,'string',param_data.stim_duration);
    set(handles.edit_stim_int,'string',param_data.stim_int);
    set(handles.edit_ang_per_frame,'string',param_data.ang_per_frame);
    set(handles.edit_num_cycles,'string',param_data.num_cycles);
    set(handles.edit_mask_r,'string',param_data.mask_r);
else
    handles.output = [];
    handles.output.name = 'Optomotor';
    handles.output.stim_duration=str2num(get(handles.edit_stim_duration,'string'));
    handles.output.stim_int=str2num(get(handles.edit_stim_int,'string'));
    handles.output.ang_per_frame=str2num(get(handles.edit_ang_per_frame,'string'));
    handles.output.num_cycles=str2num(get(handles.edit_num_cycles,'string'));
    handles.output.mask_r=str2num(get(handles.edit_mask_r,'string'));
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes registration_parameter_gui wait for user response (see UIRESUME)
uiwait(handles.figure1);




% --- Outputs from this function are returned to the command line.
function varargout = registration_parameter_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if isfield(handles,'output')
    varargout{1} = handles.output;
    close(handles.figure1);
else
    varargout{1} = [];
    delete(hObject);
end



% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(hObject);




function edit_spot_r_Callback(hObject, eventdata, handles)
% hObject    handle to edit_spot_r (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output.spot_r=str2num(get(handles.edit_spot_r,'string'));
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_spot_r_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_spot_r (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in accept_pushbutton.
function accept_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to accept_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

guidata(hObject, handles);
uiresume(handles.figure1);



function edit_step_interval_Callback(hObject, eventdata, handles)
% hObject    handle to edit_step_interval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output.step_interval=str2num(get(handles.edit_step_interval,'string'));
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_step_interval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_step_interval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_pixel_step_size_Callback(hObject, eventdata, handles)
% hObject    handle to edit_pixel_step_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output.pixel_step_size=str2num(get(handles.edit_pixel_step_size,'string'));
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_pixel_step_size_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_pixel_step_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
