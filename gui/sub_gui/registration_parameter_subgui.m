function varargout = registration_parameter_subgui(varargin)
% REGISTRATION_PARAMETER_SUBGUI MATLAB code for registration_parameter_subgui.fig
%      REGISTRATION_PARAMETER_SUBGUI, by itself, creates a new REGISTRATION_PARAMETER_SUBGUI or raises the existing
%      singleton*.
%
%      H = REGISTRATION_PARAMETER_SUBGUI returns the handle to a new REGISTRATION_PARAMETER_SUBGUI or the handle to
%      the existing singleton*.
%
%      REGISTRATION_PARAMETER_SUBGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in REGISTRATION_PARAMETER_SUBGUI.M with the given input arguments.
%
%      REGISTRATION_PARAMETER_SUBGUI('Property','Value',...) creates a new REGISTRATION_PARAMETER_SUBGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before registration_parameter_subgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to registration_parameter_subgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help registration_parameter_subgui

% Last Modified by GUIDE v2.5 14-Apr-2017 11:04:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @registration_parameter_subgui_OpeningFcn, ...
                   'gui_OutputFcn',  @registration_parameter_subgui_OutputFcn, ...
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




% --- Executes just before registration_parameter_subgui is made visible.
function registration_parameter_subgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to registration_parameter_subgui (see VARARGIN)

% Clear the workspace
sca;

% Here we call some default settings for setting up Psychtoolbox
available_screens = Screen('Screens');
disp_str = cell(length(available_screens),1);
for i = 1:length(available_screens)
    [w,h]=Screen('WindowSize',i-1);
    disp_str(i) = {['display ' num2str(i-1) ' (' num2str(w) 'x' num2str(h) ')']};
end
    
handles.scr_popupmenu.String = disp_str;
handles.scr_popupmenu.Value = 1;

if ~isempty(varargin)
    expmt = varargin{1};
    if isfield(expmt.hardware.projector,'reg_params')
        reg_params = expmt.hardware.projector.reg_params;
    end
end

if exist('reg_params','var')
    
    if isfield(reg_params,'pixel_step_size')
        set(handles.edit_pixel_step_size,'string',reg_params.pixel_step_size);
    else
        reg_params.pixel_step_size = str2double(get(handles.edit_pixel_step_size,'string'));
    end
        
    if isfield(reg_params,'spot_r')
        set(handles.edit_spot_r,'string',reg_params.spot_r);
    else
        reg_params.spot_r=str2double(get(handles.edit_spot_r,'string'));
    end
        
    handles.scr_popupmenu.Value = reg_params.screen_num+1;
    
    handles.output=reg_params;
else
    handles.output = [];
    handles.output.name = 'Registration Parameters';
    handles.output.pixel_step_size = ...
        str2double(get(handles.edit_pixel_step_size,'string'));
    handles.output.spot_r = ...
        str2double(get(handles.edit_spot_r,'string'));
    handles.output.screen_num = 0;
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes registration_parameter_subgui wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = registration_parameter_subgui_OutputFcn(hObject, eventdata, handles) 
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

handles.output.spot_r=str2double(get(handles.edit_spot_r,'string'));
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

handles.output.step_interval=str2double(get(handles.edit_step_interval,'string'));
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_step_interval_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_pixel_step_size_Callback(hObject, eventdata, handles)

handles.output.pixel_step_size=str2double(get(handles.edit_pixel_step_size,'string'));
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_pixel_step_size_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in scr_popupmenu.
function scr_popupmenu_Callback(hObject, eventdata, handles)

handles.output.screen_num = handles.scr_popupmenu.Value-1;
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function scr_popupmenu_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
