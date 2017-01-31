function varargout = slowphototaxis_parameter_gui(varargin)
% OPTOMOTOR_PARAMETER_GUI MATLAB code for optomotor_parameter_gui.fig
%      OPTOMOTOR_PARAMETER_GUI, by itself, creates a new OPTOMOTOR_PARAMETER_GUI or raises the existing
%      singleton*.
%
%      H = OPTOMOTOR_PARAMETER_GUI returns the handle to a new OPTOMOTOR_PARAMETER_GUI or the handle to
%      the existing singleton*.
%
%      OPTOMOTOR_PARAMETER_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in OPTOMOTOR_PARAMETER_GUI.M with the given input arguments.
%
%      OPTOMOTOR_PARAMETER_GUI('Property','Value',...) creates a new OPTOMOTOR_PARAMETER_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before optomotor_parameter_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to optomotor_parameter_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help optomotor_parameter_gui

% Last Modified by GUIDE v2.5 28-Nov-2016 17:42:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @optomotor_parameter_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @optomotor_parameter_gui_OutputFcn, ...
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


% --- Executes just before optomotor_parameter_gui is made visible.
function optomotor_parameter_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to optomotor_parameter_gui (see VARARGIN)


    parameters = varargin{1};
    handles.output=parameters;

    if isfield(parameters,'stim_duration')
        set(handles.edit_stim_duration,'string',parameters.stim_duration);     
    end

    if isfield(parameters,'divider_size')
        set(handles.edit_stim_divider_size,'string',parameters.divider_size);
    end

    if isfield(parameters,'stim_contrast')
        set(handles.edit_stim_contrast,'string',parameters.stim_contrast);
    end
    
    % Choose default command line output for optomotor_parameter_gui
    handles.output.stim_duration=str2num(get(handles.edit_stim_duration,'string'));
    handles.output.divider_size=str2num(get(handles.edit_stim_divider_size,'string'));
    handles.output.stim_contrast=str2num(get(handles.edit_stim_contrast,'string'));



% Update handles structure
guidata(hObject, handles);

% UIWAIT makes optomotor_parameter_gui wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = optomotor_parameter_gui_OutputFcn(hObject, eventdata, handles) 
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


function edit_stim_divider_size_Callback(hObject, eventdata, handles)
% hObject    handle to edit_stim_divider_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output.divider_size=str2num(get(handles.edit_stim_divider_size,'string'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_stim_divider_size_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_stim_divider_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in accept_parameters_pushbutton.
function accept_parameters_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to accept_parameters_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% The GUI is still in UIWAIT, us UIRESUME
uiresume(handles.figure1);

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(hObject);

function edit_stim_duration_Callback(hObject, eventdata, handles)
% hObject    handle to edit_stim_duration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output.stim_duration=str2num(get(handles.edit_stim_duration,'string'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_stim_duration_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_stim_duration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_stim_contrast_Callback(hObject, eventdata, handles)
% hObject    handle to edit_stim_contrast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output.stim_contrast=str2num(get(handles.edit_stim_contrast,'string'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_stim_contrast_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_stim_contrast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
