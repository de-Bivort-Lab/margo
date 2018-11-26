function varargout = video_recording_subgui(varargin)
% VIDEO_RECORDING_SUBGUI MATLAB code for video_recording_subgui.fig
%      VIDEO_RECORDING_SUBGUI, by itself, creates a new VIDEO_RECORDING_SUBGUI or raises the existing
%      singleton*.
%
%      H = VIDEO_RECORDING_SUBGUI returns the handle to a new VIDEO_RECORDING_SUBGUI or the handle to
%      the existing singleton*.
%
%      VIDEO_RECORDING_SUBGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VIDEO_RECORDING_SUBGUI.M with the given input arguments.
%
%      VIDEO_RECORDING_SUBGUI('Property','Value',...) creates a new VIDEO_RECORDING_SUBGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before video_recording_subgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to video_recording_subgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help video_recording_subgui

% Last Modified by GUIDE v2.5 21-Nov-2018 10:54:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @video_recording_subgui_OpeningFcn, ...
                   'gui_OutputFcn',  @video_recording_subgui_OutputFcn, ...
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




% --- Executes just before video_recording_subgui is made visible.
function video_recording_subgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to video_recording_subgui (see VARARGIN)

% import experiment data and set default output
expmt = varargin{1};
if ischar(expmt)
    delete(hObject);
    return
end
if ~isfield(expmt.meta,'video_out')
    expmt.meta.video_out = default_recording_settings();
end
handles.output = expmt;
vid = expmt.meta.video_out;

% update UI controls
handles.record_vid_checkbox.Value = vid.record;
handles.edit_vid_sample_rate.String = sprintf('%0.2f',vid.rate);
record_vid_checkbox_Callback(handles.record_vid_checkbox, [], handles);
handles.compress_checkbox.Value = vid.compress;
handles.vid_subsample_checkbox.Value = vid.rate >= 0;
handles.image_source_popupmenu.Value = ...
    find(strcmpi(vid.source,handles.image_source_popupmenu.String));
if vid.rate < 0
    handles.edit_vid_sample_rate.Enable = 'off';
    handles.edit_subsample_label.Enable = 'off';
end
if any(strcmpi('video_index',expmt.meta.fields))
    handles.video_index_checkbox.Value = true;
else
    handles.video_index_checkbox.Value = false;
end

% adjust subgui position
light_uipanel = findobj('Tag','light_uipanel');
gui_fig = findobj('Name','margo');
handles.vid_record_fig.Position(1) = gui_fig.Position(1) + ...
    sum(light_uipanel.Position([1 3])) - handles.vid_record_fig.Position(3);
handles.vid_record_fig.Position(2) = gui_fig.Position(2) + ...
    sum(light_uipanel.Position([2 4])) - handles.vid_record_fig.Position(4) - 25;

% Update handles structure
guidata(hObject, handles);





% --- Outputs from this function are returned to the command line.
function varargout = video_recording_subgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

varargout = {};


% --- Executes when user attempts to close vid_record_fig.
function vid_record_fig_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to vid_record_fig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(hObject);


% --- Executes on button press in record_vid_checkbox.
function record_vid_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to record_vid_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output.meta.video_out.record = hObject.Value;
switch hObject.Value
    case true
        set(findall(handles.vid_record_fig, '-property', 'Enable'),'Enable','on');
        handles.vid_subsample_checkbox.Value = handles.output.meta.video_out.rate >= 0;
    case false
        set(findall(handles.vid_record_fig, '-property', 'Enable'),'Enable','off');
        handles.vid_subsample_checkbox.Value = false;
end

vid_subsample_checkbox_Callback(handles.vid_subsample_checkbox, [], handles);
handles.rec_vid_label.Enable = 'on';
hObject.Enable = 'on';
guidata(hObject,handles);


% --- Executes on button press in compress_checkbox.
function compress_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to compress_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output.meta.video_out.compress = hObject.Value;
guidata(hObject,handles);



% --- Executes on button press in vid_subsample_checkbox.
function vid_subsample_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to vid_subsample_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

switch hObject.Value
    case true
        handles.output.meta.video_out.rate = ...
            str2double(handles.edit_vid_sample_rate.String);
        handles.edit_vid_sample_rate.Enable = 'on';
        handles.edit_subsample_label.Enable = 'on';
        handles.video_index_checkbox.Enable = 'on';
        handles.output_vid_index_label.Enable = 'on';
    case false
        handles.output.meta.video_out.rate = -1;
        handles.edit_vid_sample_rate.String = '-1';
        handles.edit_vid_sample_rate.Enable = 'off';
        handles.edit_subsample_label.Enable = 'off';
        handles.video_index_checkbox.Enable = 'off';
        handles.output_vid_index_label.Enable = 'off';
        handles.video_index_checkbox.Value = false;
        video_index_checkbox_Callback(handles.video_index_checkbox,[],handles);
end


function edit_vid_sample_rate_Callback(hObject, eventdata, handles)
% hObject    handle to edit_vid_sample_rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output.meta.video_out.rate = str2double(hObject.String);
guidata(hObject,handles);


% --- Executes on selection change in image_source_popupmenu.
function image_source_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to image_source_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output.meta.video_out.source = hObject.String{hObject.Value};
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_vid_sample_rate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_vid_sample_rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function image_source_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to image_source_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% define default video recording settings
function vid_out = default_recording_settings

vid_out.record = false;
vid_out.compress = false;
vid_out.rate = -1;
vid_out.source = 'raw image';
vid_out.t = 0;



% --- Executes on button press in video_index_checkbox.
function video_index_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to video_index_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

f = handles.output.meta.fields;
if hObject.Value
    % add video index to output list if it doesn't exist
    if ~any(strcmpi('video_index',f))
        f = [f;{'video_index'}];
    end
else
    % remove video index from output list if it exists
    if any(strcmpi('video_index',f))
        f(strcmpi('video_index',f))=[];
    end 
end

% update output fields list
handles.output.meta.fields = f;
guidata(hObject,handles);
