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

% Last Modified by GUIDE v2.5 19-Dec-2016 19:16:07

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
handles.output=[];


if isfield(handles.input,'target_size') && isfield(handles.input,'mm_per_pixel')
    
    % Set GUI strings with input parameters
    set(handles.edit_target_size,'string',input.target_size);
    set(handles.edit_mm_per_pixel,'string',input.mm_per_pixel);

    % Assign current values as default output
    handles.output.target_size=str2num(get(handles.edit_target_size,'string'));
    handles.output.mm_per_pixel=str2num(get(handles.edit_mm_per_pixel,'string'));
    
end


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes setDistanceScale_subgui wait for user response (see UIRESUME)
uiwait(handles.figure1);



% --- Outputs from this function are returned to the command line.
function varargout = setDistanceScale_subgui_OutputFcn(hObject, eventdata, handles) 
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






%*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*%
%*-*-*-*-*-*-*-*-*-*-*-*-* GUI CALLBACKS *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*%
%*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*%




% --- Executes on button press in draw_button.
function draw_button_Callback(hObject, eventdata, handles)
% hObject    handle to draw_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'line_handle')
    disp('here')
    delete(handles.line_handle);
end

% Create new image line object
handles.line_handle = imline(handles.input.axes_handle);

if isfield(handles.ouput,'target_size')
    pos = handles.line_handle.getPosition();
    d = sqrt((pos(1)+pos(3))^2+(pos(2)+pos(4))^2);
    handles.output.mm_per_pixel = handles.output.target_size/d;
    set(handles.edit_mm_per_pixel,'string',num2str(round(handles.output.mm_per_pixel*100)/100));
end

guidata(hObject,handles);




function edit_target_size_Callback(hObject, eventdata, handles)
% hObject    handle to edit_target_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_target_size as text
%        str2double(get(hObject,'String')) returns contents of edit_target_size as a double
handles.output.target_size = str2num(get(handles.edit_target_size,'string'));
guidata(hObject,handles);




function edit_mm_per_pixel_Callback(hObject, eventdata, handles)
% hObject    handle to edit_mm_per_pixel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_mm_per_pixel as text
%        str2double(get(hObject,'String')) returns contents of edit_mm_per_pixel as a double

set(handles.edit_mm_per_pixel,'string',num2str(round(handles.output.mm_per_pixel*100)/100));
guidata(hObject,handles);





% --- Executes on button press in help_button.
function help_button_Callback(hObject, eventdata, handles)
% hObject    handle to help_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

msg_title=['Parameter Info'];
spc=[' '];
item1=['\bfSpeed Threshold\rm - sets the upper bound for maximum allowable frame ' ...
    'to frame speed for centroid tracking and sorting. Centroids that move '...
    'faster than the speed threshold are considered either a frame to '...
    'frame mismatch or false positive due to noise and are dropped for '...
    'the current frame. \it(tip: raise speed '...
    'thresh if tracking appears to lag behind the tracked object).\rm'];

item2=['\bfDistance Threshold\rm - sets the upper bound for maximum allowable frame ' ...
    'to frame distance between an object and the center of its ROI. '...
    'If distance thresh is exceeded between a centroid and its matched ROI, '...
    'the centroid is dropped for the current frame. \it(tip: Lower distance '...
    'thresh if IDs switch between neighboring ROIs).\rm'];

item3=['\bfTarget Acquisition Rate\rm - sets the upper bound for the acquisition ' ...
    'frame rate. This parameter can be used to improve consistency of '...
    'interframe interval (ifi) or lower the acquisition rate to reduce the amount '...
    'of data saved. Setting this parameter to -1 disable this parameter and '...
    'at the maximum possible speed (this will result in less consistent ifi). '...
    '\it(tip: acquisition rates of 5-10Hz are often sufficient and result in '...
    'smaller file sizes).\rm'];

item4=['\bfVignette Gaussian Sigma\rm - defines the standard deviation of a gaussian'...
    ' used to correct for vignetting in illumination. This gaussian is subtracted '...
    'off of the image to achieve more evenly lit ROIs. This strategy is used '...
    'only in the initial detection of ROIs and is not applied to object tracking. '...
    ' Sigma is expressed as a fraction of the image height in pixels \it(tip: '...
    'adjust this parameter if thresholded ROIs are occluded in a circular shape).\rm'];

item5=['\bfVignette Gaussian Weight\rm - sets the weight of the above gaussian ' ...
    'before subtracting it off of the ROI image. Weight is expressed as '...
    'a fraction of the maximum intensity.'];

closing=['See Manual for additional tips and details.'];
message={spc item1 spc item2 spc item3 spc item4 spc item5 spc closing};

% Display info
Opt.Interpreter='tex';
Opt.WindowStyle='normal';
waitfor(msgbox(message,msg_title,'none',Opt));




% --- Executes on button press in accept_button.
function accept_button_Callback(hObject, eventdata, handles)
% hObject    handle to accept_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'line_handle')
    disp('here')
    delete(handles.line_handle);
end

guidata(hObject, handles);
uiresume(handles.figure1);








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

