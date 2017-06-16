function varargout = arenablock_parameter_gui(varargin)
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

% Last Modified by GUIDE v2.5 15-Jun-2017 14:44:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @arenablock_parameter_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @arenablock_parameter_gui_OutputFcn, ...
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
function arenablock_parameter_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to optomotor_parameter_gui (see VARARGIN)

    expmt = varargin{1};
    parameters = expmt.parameters;
    
    handles.output = expmt;
    
    gray=[0.5 0.5 0.5];
    black=[0 0 0];
    handles.arena_radiobutton.ForegroundColor = gray;
    handles.opto_radiobutton.ForegroundColor = gray;
    handles.slowphoto_radiobutton.ForegroundColor = gray;

    if isfield(expmt,'block') && isfield(expmt.block,'fields')
        
        f = expmt.block.fields;
    
        if any(strcmp(f,'Arena Circling'))
            handles.edit_arena_dur.Enable = 'on';
            handles.arena_radiobutton.ForegroundColor = black;
            handles.arena_radiobutton.Value = true;
            set(handles.edit_arena_dur,'string',expmt.block.arena_duration);     
        end

        if any(strcmp(f,'Optomotor'))
            handles.edit_opto_dur.Enable = 'on';
            handles.opto_radiobutton.ForegroundColor = black;
            handles.opto_radiobutton.Value = true;
            set(handles.edit_opto_dur,'string',expmt.block.opto_duration);     
        end

        if any(strcmp(f,'Slow Phototaxis'))
            handles.edit_slowphoto_dur.Enable = 'on';
            handles.slowphoto_radiobutton.ForegroundColor = black;
            handles.slowphoto_radiobutton.Value = true;
            set(handles.edit_slowphoto_dur,'string',expmt.block.photo_duration);     
        end
        
    end



% Update handles structure
guidata(hObject, handles);

% UIWAIT makes optomotor_parameter_gui wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = arenablock_parameter_gui_OutputFcn(hObject, eventdata, handles) 
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


function edit_slowphoto_dur_Callback(hObject, eventdata, handles)
% hObject    handle to edit_slowphoto_dur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output.block.photo_duration = str2num(get(handles.edit_slowphoto_dur,'string'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_slowphoto_dur_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_slowphoto_dur (see GCBO)
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

function edit_arena_dur_Callback(hObject, eventdata, handles)
% hObject    handle to edit_arena_dur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output.block.arena_duration=str2double(get(handles.edit_arena_dur,'string'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_arena_dur_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_arena_dur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_opto_dur_Callback(hObject, eventdata, handles)
% hObject    handle to edit_opto_dur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output.block.opto_duration=str2num(get(handles.edit_opto_dur,'string'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_opto_dur_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_opto_dur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in arena_radiobutton.
function arena_radiobutton_Callback(hObject, eventdata, handles)
% hObject    handle to arena_radiobutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

fidx = [];
if isfield(handles.output,'block') && isfield(handles.output.block,'fields');
    f = handles.output.block.fields;
    fidx = find(strcmp(f,'Arena Circling'));
end
    

switch hObject.Value
    case false
        
        handles.edit_arena_dur.Enable = 'off';
        handles.output.block = rmfield(handles.output.block,'arena_duration');
        hObject.ForegroundColor = [0.5 0.5 0.5];
        
        if ~isempty(fidx)
            handles.output.block.fields(fidx) = [];
        end
        
    case true
        
        handles.edit_arena_dur.Enable = 'on';
        handles.output.block.arena_duration = str2double(handles.edit_arena_dur.String);
        hObject.ForegroundColor = [0 0 0];
        
        if isempty(fidx)
            if isfield(handles.output.block,'fields');
                handles.output.block.fields = [handles.output.block.fields {'Arena Circling'}];
            else
                handles.output.block.fields = {'Arena Circling'};
            end
        end
end

guidata(hObject,handles);


% --- Executes on button press in opto_radiobutton.
function opto_radiobutton_Callback(hObject, eventdata, handles)
% hObject    handle to opto_radiobutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

fidx = [];
if isfield(handles.output,'block') && isfield(handles.output.block,'fields');
    f = handles.output.block.fields;
    fidx = find(strcmp(f,'Optomotor'));
end
    

switch hObject.Value
    case false
        
        handles.edit_opto_dur.Enable = 'off';
        handles.output.block = rmfield(handles.output.block,'opto_duration');
        hObject.ForegroundColor = [0.5 0.5 0.5];
        
        if ~isempty(fidx)
            handles.output.block.fields(fidx) = [];
        end
        
    case true
        
        handles.edit_opto_dur.Enable = 'on';
        handles.output.block.opto_duration = str2double(handles.edit_opto_dur.String);
        hObject.ForegroundColor = [0 0 0];
        
        if isempty(fidx)
            if isfield(handles.output.block,'fields');
                handles.output.block.fields = [handles.output.block.fields {'Optomotor'}];
            else
                handles.output.block.fields = {'Optomotor'};
            end
        end
end

guidata(hObject,handles);


% --- Executes on button press in slowphoto_radiobutton.
function slowphoto_radiobutton_Callback(hObject, eventdata, handles)
% hObject    handle to slowphoto_radiobutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

fidx = [];
if isfield(handles.output,'block') && isfield(handles.output.block,'fields');
    f = handles.output.block.fields;
    fidx = find(strcmp(f,'Slow Phototaxis'));
end
    

switch hObject.Value
    case false
        
        handles.edit_slowphoto_dur.Enable = 'off';
        handles.output.block = rmfield(handles.output.block,'photo_duration');
        hObject.ForegroundColor = [0.5 0.5 0.5];
        
        if ~isempty(fidx)
            handles.output.block.fields(fidx) = [];
        end
        
    case true
        
        handles.edit_slowphoto_dur.Enable = 'on';
        handles.output.block.photo_duration = str2double(handles.edit_slowphoto_dur.String);
        hObject.ForegroundColor = [0 0 0];
        
        if isempty(fidx)
            if isfield(handles.output.block,'fields');
                handles.output.block.fields = [handles.output.block.fields {'Slow Phototaxis'}];
            else
                handles.output.block.fields = {'Slow Phototaxis'};
            end
        end
end

guidata(hObject,handles);
