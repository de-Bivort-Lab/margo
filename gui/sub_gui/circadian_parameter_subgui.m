function varargout = circadian_parameter_subgui(varargin)
% CIRCADIAN_PARAMETER_SUBGUI MATLAB code for circadian_parameter_subgui.fig
%      CIRCADIAN_PARAMETER_SUBGUI, by itself, creates a new CIRCADIAN_PARAMETER_SUBGUI or raises the existing
%      singleton*.
%
%      H = CIRCADIAN_PARAMETER_SUBGUI returns the handle to a new CIRCADIAN_PARAMETER_SUBGUI or the handle to
%      the existing singleton*.
%
%      CIRCADIAN_PARAMETER_SUBGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CIRCADIAN_PARAMETER_SUBGUI.M with the given input arguments.
%
%      CIRCADIAN_PARAMETER_SUBGUI('Property','Value',...) creates a new CIRCADIAN_PARAMETER_SUBGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before circadian_parameter_subgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to circadian_parameter_subgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help circadian_parameter_subgui

% Last Modified by GUIDE v2.5 31-Mar-2017 16:00:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @circadian_parameter_subgui_OpeningFcn, ...
                   'gui_OutputFcn',  @circadian_parameter_subgui_OutputFcn, ...
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




% --- Executes just before circadian_parameter_subgui is made visible.
function circadian_parameter_subgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to circadian_parameter_subgui (see VARARGIN)

    parameters = varargin{1};
    handles.output=parameters;
    
    if isfield(parameters,'stim_duration')
        set(handles.edit_timeon,'string',parameters.stim_duration);
    end
    
    if isfield(parameters,'stim_int')
        set(handles.edit_timeoff,'string',parameters.stim_int);
    end
    
    if isfield(parameters,'ang_per_frame')
        set(handles.edit_pulsenum,'string',parameters.ang_per_frame);
    end
    
    if isfield(parameters,'num_cycles')
        set(handles.edit_trialnum,'string',parameters.num_cycles);
    end
    
    if isfield(parameters,'mask_r')
        set(handles.edit_pulseamp,'string',parameters.mask_r);
    end


    handles.output.stim_duration=str2num(get(handles.edit_timeon,'string'));
    handles.output.stim_int=str2num(get(handles.edit_timeoff,'string'));
    handles.output.ang_per_frame=str2num(get(handles.edit_pulsenum,'string'));
    handles.output.num_cycles=str2num(get(handles.edit_trialnum,'string'));
    handles.output.mask_r=str2num(get(handles.edit_pulseamp,'string'));
    
    light_uipanel = findobj('Tag','light_uipanel');
    gui_fig = findobj('Name','autotracker');
    handles.circ_fig.Position(1) = gui_fig.Position(1) + ...
        sum(light_uipanel.Position([1 3])) - handles.circ_fig.Position(3);
    handles.circ_fig.Position(2) = gui_fig.Position(2) + ...
        sum(light_uipanel.Position([2 4])) - handles.circ_fig.Position(4) - 25;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes circadian_parameter_subgui wait for user response (see UIRESUME)
uiwait(handles.circ_fig);




% --- Outputs from this function are returned to the command line.
function varargout = circadian_parameter_subgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if isfield(handles,'output')
    varargout{1} = handles.output;
    close(handles.circ_fig);
else
    varargout{1} = [];
    delete(hObject);
end




function edit_pulsenum_Callback(hObject, eventdata, handles)
% hObject    handle to edit_pulsenum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output.ang_per_frame=str2num(get(handles.edit_pulsenum,'string'));
guidata(hObject, handles);




% --- Executes during object creation, after setting all properties.
function edit_pulsenum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_pulsenum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




function edit_pulseamp_Callback(hObject, eventdata, handles)
% hObject    handle to edit_pulseamp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output.mask_r=str2num(get(handles.edit_pulseamp,'string'));
guidata(hObject, handles);




% --- Executes during object creation, after setting all properties.
function edit_pulseamp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_pulseamp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_trialnum_Callback(hObject, eventdata, handles)
% hObject    handle to edit_trialnum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output.num_cycles=str2num(get(handles.edit_trialnum,'string'));
guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function edit_trialnum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_trialnum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in test_pushbutton.
function test_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to test_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% The GUI is still in UIWAIT, us UIRESUME
guidata(hObject, handles);
uiresume(handles.circ_fig);



% --- Executes when user attempts to close circ_fig.
function circ_fig_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to circ_fig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(hObject);



function edit_timeoff_Callback(hObject, eventdata, handles)
% hObject    handle to edit_timeoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output.stim_int=str2num(get(handles.edit_timeoff,'string'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_timeoff_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_timeoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_timeon_Callback(hObject, eventdata, handles)
% hObject    handle to edit_timeon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output.stim_duration=str2num(get(handles.edit_timeon,'string'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_timeon_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_timeon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_ramp_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ramp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_ramp as text
%        str2double(get(hObject,'String')) returns contents of edit_ramp as a double


% --- Executes during object creation, after setting all properties.
function edit_ramp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ramp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
