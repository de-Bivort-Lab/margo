function varargout = new_custom_expmt(varargin)
% NEW_CUSTOM_EXPMT MATLAB code for new_custom_expmt.fig
%      NEW_CUSTOM_EXPMT, by itself, creates a new NEW_CUSTOM_EXPMT or raises the existing
%      singleton*.
%
%      H = NEW_CUSTOM_EXPMT returns the handle to a new NEW_CUSTOM_EXPMT or the handle to
%      the existing singleton*.
%
%      NEW_CUSTOM_EXPMT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NEW_CUSTOM_EXPMT.M with the given input arguments.
%
%      NEW_CUSTOM_EXPMT('Property','Value',...) creates a new NEW_CUSTOM_EXPMT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before new_custom_expmt_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to new_custom_expmt_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help new_custom_expmt

% Last Modified by GUIDE v2.5 20-Aug-2018 13:23:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @new_custom_expmt_OpeningFcn, ...
                   'gui_OutputFcn',  @new_custom_expmt_OutputFcn, ...
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


% --- Executes just before new_custom_expmt is made visible.
function new_custom_expmt_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to new_custom_expmt (see VARARGIN)

% Choose default command line output for new_custom_expmt
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
uiwait(handles.new_expmt_fig);


% --- Outputs from this function are returned to the command line.
function varargout = new_custom_expmt_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if ~isempty(handles)
    handles.output = handles.edit_expmt_name.String;
    varargout{1} = handles.output;
    if ishghandle(handles.new_expmt_fig)
        close(handles.new_expmt_fig);
    end
else
    varargout{1} = {};
end



function edit_expmt_name_Callback(hObject, eventdata, handles)
% hObject    handle to edit_expmt_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes during object creation, after setting all properties.
function edit_expmt_name_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_expmt_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in accept_pushbutton.
function accept_pushbutton_Callback(hObject, eventdata, handles)

uiresume(handles.new_expmt_fig);
guidata(hObject, handles);


% --- Executes on button press in cancel_pushbutton.
function cancel_pushbutton_Callback(hObject, eventdata, handles)

handles.edit_expmt_name.String = '';
uiresume(handles.new_expmt_fig);
guidata(hObject, handles);


% --- Executes when user attempts to close new_expmt_fig.
function new_expmt_fig_CloseRequestFcn(hObject, eventdata, handles)

delete(hObject);
