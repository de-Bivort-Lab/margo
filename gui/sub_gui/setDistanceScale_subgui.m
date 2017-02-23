function varargout = setDistanceScale_subgui(varargin)
% SETDISTANCESCALE_SUBGUI MATLAB code for setDistanceScale_subgui.fig
%      SETDISTANCESCALE_SUBGUI, by itself, creates a new SETDISTANCESCALE_SUBGUI or raises the existing
%      singleton*.
%
%      H = SETDISTANCESCALE_SUBGUI returns the handle to a new SETDISTANCESCALE_SUBGUI or the handle to
%      the existing singleton*.
%
%      SETDISTANCESCALE_SUBGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SETDISTANCESCALE_SUBGUI.M with the given input arguments.
%
%      SETDISTANCESCALE_SUBGUI('Property','Value',...) creates a new SETDISTANCESCALE_SUBGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before setDistanceScale_subgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to setDistanceScale_subgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help setDistanceScale_subgui

% Last Modified by GUIDE v2.5 19-Dec-2016 20:22:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @setDistanceScale_subgui_OpeningFcn, ...
                   'gui_OutputFcn',  @setDistanceScale_subgui_OutputFcn, ...
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




% --- Executes just before setDistanceScale_subgui is made visible.
function setDistanceScale_subgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to setDistanceScale_subgui (see VARARGIN)

handles.input = varargin{1};
param_data = varargin{2};
handles.output=[];


if isfield(param_data,'distance_scale')
    
    % Set GUI strings with input parameters
    set(handles.edit_target_size,'string',param_data.distance_scale.target_size);
    set(handles.edit_mm_per_pixel,'string',round(param_data.distance_scale.mm_per_pixel*100)/100);
    handles.line_handle = imline(handles.input.axes_handle,param_data.distance_scale.Pos);

    % Assign current values as default output
    handles.figure1.UserData.target_size=str2num(get(handles.edit_target_size,'string'));
    handles.figure1.UserData.mm_per_pixel=str2num(get(handles.edit_mm_per_pixel,'string'));
    handles.figure1.UserData.Pos = param_data.distance_scale.Pos;
    
end


% Update handles structure
guidata(hObject, handles);



% --- Outputs from this function are returned to the command line.
function varargout = setDistanceScale_subgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

while ishghandle(hObject)
    pause(0.001);
    if isprop(handles.figure1,'UserData')
    	varargout{1} = handles.figure1.UserData;
    end
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

delete(hObject);






%*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*%
%*-*-*-*-*-*-*-*-*-*-*-*-* GUI CALLBACKS *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*%
%*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*%




% --- Executes on button press in draw_button.
function draw_button_Callback(hObject, eventdata, handles)
% hObject    handle to draw_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'line_handle')
    delete(handles.line_handle);
end

% Create new image line object
handles.line_handle = imline(handles.input.axes_handle);

if isfield(handles.figure1.UserData,'target_size')
    pos = handles.line_handle.getPosition();
    handles.figure1.UserData.Pos = pos;
    d = sqrt((pos(1,1)-pos(2,1))^2+(pos(2,2)-pos(1,2))^2);
    handles.figure1.UserData.mm_per_pixel = handles.figure1.UserData.target_size/d;
    set(handles.edit_mm_per_pixel,'string',num2str(round(handles.figure1.UserData.mm_per_pixel*1000)/1000));
end

figure(handles.figure1);

guidata(hObject,handles);



% --- Executes on button press in update_button.
function update_button_Callback(hObject, eventdata, handles)
% hObject    handle to update_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'line_handle')

    if isfield(handles.figure1.UserData,'target_size')
        pos = handles.line_handle.getPosition();
        handles.figure1.UserData.Pos = pos;
        d = sqrt((pos(1,1)-pos(2,1))^2+(pos(2,2)-pos(1,2))^2);
        handles.figure1.UserData.mm_per_pixel = handles.figure1.UserData.target_size/d;
        set(handles.edit_mm_per_pixel,'string',num2str(round(handles.figure1.UserData.mm_per_pixel*1000)/1000));
    end
    
end

guidata(hObject,handles);




function edit_target_size_Callback(hObject, eventdata, handles)
% hObject    handle to edit_target_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_target_size as text
%        str2double(get(hObject,'String')) returns contents of edit_target_size as a double
handles.figure1.UserData.target_size = str2num(get(handles.edit_target_size,'string'));
guidata(hObject,handles);




function edit_mm_per_pixel_Callback(hObject, eventdata, handles)
% hObject    handle to edit_mm_per_pixel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_mm_per_pixel as text
%        str2double(get(hObject,'String')) returns contents of edit_mm_per_pixel as a double

set(handles.edit_mm_per_pixel,'string',num2str(round(handles.figure1.UserData.mm_per_pixel*100)/100));
guidata(hObject,handles);





% --- Executes on button press in help_button.
function help_button_Callback(hObject, eventdata, handles)
% hObject    handle to help_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

msg_title=['Set Distance Scale'];
spc=[' '];
item1=['\bfDescription\rm - This function estimates the pixel to millimeter ' ...
    'ratio by comparing the length of a line drawn in the main camera window.  '...
    'For this to work, a target object (eg. an ROI or the length of tracking '...
    'platform) of known size must be within the field of view of the camera '...
    '(\ittip: Confirm Camera Settings to take a still image and display it '...
    'in the camera window\rm).'];
    
item2 = ['\bfTarget object size\rm - enter size of the target object in mm '...
    'before calculating the conversion factor.'];
    
item3 = ['\bfDraw new line\rm - draw a line along a previously measured'...
    'dimension of the target. After pressing the button, click and drag '...
    'in the camera window to initiate drawing. The mm/pixel conversion '...
    'factor will automatically be calculated and displayed.'];

item4 = ['\bfUpdate\rm - the calculation if the line is repositioned after initial placement.'];

item5=['\bfAccept\rm - save the conversion factor and close the '...
    'window.'];

closing = ['\itSee manual for additional tips and details on estimating absolute' ...
    ' distance from pixel distance.'];

message={spc item1 spc item2 spc item3 spc item4 spc item5 spc closing};

% Display info
Opt.Interpreter='tex';
Opt.WindowStyle='normal';
waitfor(msgbox(message,msg_title,'none',Opt));






%*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*%
%*-*-*-*-*-*-*-*-*-*-* GUI OBJECT CREATION *-*-*-*-*-*-*-*-*-*-*-*-*-*-*%
%*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*%







% --- Executes during object creation, after setting all properties.
function edit_mm_per_pixel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_mm_per_pixel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edit_target_size_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_target_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on mouse press over figure background.
function figure1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


