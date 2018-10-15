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

    expmt = varargin{1};
    p = expmt.parameters;
    handles.circ_fig.UserData = p;
    
    if isfield(p,'lights_ON')
        if isstr(p.lights_ON)
            set(handles.edit_timeon,'string',p.lights_ON);
        else
            hr = num2str(p.lights_ON(1));
            if p.lights_ON(2)<10
                min = ['0' num2str(p.lights_ON(2))];
            else
                min = num2str(p.lights_ON(2));
            end
            handles.edit_timeon.String = [hr ':' min];
        end
    end
    
    if isfield(p,'lights_OFF') 
        if isstr(p.lights_ON)
            set(handles.edit_timeoff,'string',p.lights_OFF);
        else
            hr = num2str(p.lights_OFF(1));
            if p.lights_ON(2)<10
                min = ['0' num2str(p.lights_OFF(2))];
            else
                min = num2str(p.lights_OFF(2));
            end
            handles.edit_timeoff.String = [hr ':' min];
        end
    end
    
    if isfield(p,'light_ramp_time')
        set(handles.edit_pulseamp,'string',num2str(p.light_ramp_time));
    end
    
    if isfield(p,'pulse_num')
        set(handles.edit_pulsenum,'string',num2str(p.pulse_num));
    end
    
    if isfield(p,'pulse_per_hour')
        set(handles.edit_trialnum,'string',num2str(p.pulse_per_hour));
    end
    
    if isfield(p,'pulse_amp')
        set(handles.edit_pulseamp,'string',num2str(p.pulse_amp));
    end
    
    rt = str2num(handles.edit_ramp.String);
    pmin = 0;
    pmax = 10;
    n = 1000;
    r = repmat(1:255,n,1);
    ptry = repmat(linspace(pmin,pmax,n)',1,size(r,2));
    cumt = NaN(length(ptry),1);

    while true
        cumt = sum(ptry.^r,2);
        [v,idx]=sort(abs(cumt-rt));
        if v(1) < 0.0001
            break
        end
        pmin = ptry(idx(1)-1);
        pmax = ptry(idx(1)+1);
        ptry = repmat(linspace(pmin,pmax,n)',1,size(r,2));
    end
    
    handles.circ_fig.UserData.ramp_param = ptry(idx(1));
    handles.circ_fig.UserData.ramp_time = rt;
    

    tString=handles.edit_timeon.String;
    divider=find(tString==':');
    hr=str2num(tString(1:divider-1));
    min=str2num(tString(divider+1))*10+str2num(tString(divider+2));
    handles.circ_fig.UserData.lights_ON = [hr min];
    
    tString=handles.edit_timeoff.String;
    divider=find(tString==':');
    hr=str2num(tString(1:divider-1));
    min=str2num(tString(divider+1))*10+str2num(tString(divider+2));
    handles.circ_fig.UserData.lights_OFF = [hr min];

    handles.circ_fig.UserData.pulse_num = str2num(get(handles.edit_pulsenum,'string'));
    handles.circ_fig.UserData.pulse_per_hour = str2num(handles.edit_trialnum.String);
    handles.circ_fig.UserData.pulse_amp = str2num(handles.edit_pulseamp.String);
    
    light_uipanel = findobj('Tag','light_uipanel');
    gui_fig = findobj('Name','margo');
    handles.circ_fig.Position(1) = gui_fig.Position(1) + ...
        sum(light_uipanel.Position([1 3])) - handles.circ_fig.Position(3);
    handles.circ_fig.Position(2) = gui_fig.Position(2) + ...
        sum(light_uipanel.Position([2 4])) - handles.circ_fig.Position(4) - 25;

% Update handles structure
guidata(hObject, handles);





% --- Outputs from this function are returned to the command line.
function varargout = circadian_parameter_subgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
while ishghandle(hObject)
    pause(0.001);
    if isprop(handles.circ_fig,'UserData')
    	varargout{1} = handles.circ_fig.UserData;
    end
end




function edit_pulsenum_Callback(hObject, eventdata, handles)
% hObject    handle to edit_pulsenum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.circ_fig.UserData.pulse_num = str2num(get(handles.edit_pulsenum,'string'));
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
handles.circ_fig.UserData.pulse_amp = str2num(handles.edit_pulseamp.String);
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
handles.circ_fig.UserData.pulse_per_hour = str2num(handles.edit_trialnum.String);
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

gui_fig = findobj('Tag','gui_fig');
expmt = getappdata(gui_fig,'expmt');

n = handles.circ_fig.UserData.pulse_num;
amp = handles.circ_fig.UserData.pulse_amp;
writeVibrationalMotors(expmt.hardware.COM.light,6,1,1,n,amp);

guidata(hObject, handles);



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

tString=hObject.String;
divider=find(tString==':');
hr=str2num(tString(1:divider-1));
min=str2num(tString(divider+1))*10+str2num(tString(divider+2));
handles.circ_fig.UserData.lights_OFF = [hr min];
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

tString=hObject.String;
divider=find(tString==':');
hr=str2num(tString(1:divider-1));
min=str2num(tString(divider+1))*10+str2num(tString(divider+2));
handles.circ_fig.UserData.lights_ON = [hr min];

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

handles.circ_fig.UserData.ramp_time = str2num(hObject.String);
rt = handles.circ_fig.UserData.ramp_time;

pmin = 0;
pmax = 10;
n = 1000;
r = repmat(1:255,n,1);
ptry = repmat(linspace(pmin,pmax,n)',1,size(r,2));
cumt = NaN(length(ptry),1);

while true
    cumt = sum(ptry.^r,2);
    [v,idx]=sort(abs(cumt-rt));
    if v(1) < 0.0001
        break
    end
    pmin = ptry(idx(1)-1);
    pmax = ptry(idx(1)+1);
    ptry = repmat(linspace(pmin,pmax,n)',1,size(r,2));
end
    
handles.circ_fig.UserData.ramp_param = ptry(idx(1));
guidata(hObject,handles);


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


