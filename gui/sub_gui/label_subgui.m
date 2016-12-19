function varargout = label_subgui(varargin)
% LABEL_SUBGUI MATLAB code for label_subgui.fig
%      LABEL_SUBGUI, by itself, creates a new LABEL_SUBGUI or raises the existing
%      singleton*.
%
%      H = LABEL_SUBGUI returns the handle to a new LABEL_SUBGUI or the handle to
%      the existing singleton*.
%
%      LABEL_SUBGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LABEL_SUBGUI.M with the given input arguments.
%
%      LABEL_SUBGUI('Property','Value',...) creates a new LABEL_SUBGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before label_subgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to label_subgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help label_subgui

% Last Modified by GUIDE v2.5 15-Dec-2016 11:19:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @label_subgui_OpeningFcn, ...
                   'gui_OutputFcn',  @label_subgui_OutputFcn, ...
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


% --- Executes just before label_subgui is made visible.
function label_subgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to optomotor_parameter_gui (see VARARGIN)

% Choose default command line output for optomotor_parameter_gui
if ~isempty(varargin)
    label_data = varargin{1};
    handles.output=label_data;
    set(handles.labels_table, 'Data', label_data);
else
    data=cell(10,8);
    data(:)={''};
    handles.output=data;
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes optomotor_parameter_gui wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = label_subgui_OutputFcn(hObject, eventdata, handles) 
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

% --- Executes during object creation, after setting all properties.
function labels_table_CreateFcn(hObject, ~, ~)
% hObject    handle to uitable2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
data=cell(10,8);
data(:)={''};
handles.output=data;
set(hObject, 'Data', data);
guidata(hObject, handles);

% --- Executes when entered data in editable cell(s) in uitable2.
function labels_table_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitable2 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
handles.output{eventdata.Indices(1), eventdata.Indices(2)} = {''};
handles.output{eventdata.Indices(1), eventdata.Indices(2)} = eventdata.NewData;
guidata(hObject, handles);


% --- Executes on button press in accept_label_pushbutton.
function accept_label_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to accept_label_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output=handles.labels_table.Data;
guidata(hObject, handles);
uiresume(handles.figure1);


% --- Executes on button press in clear_label_pushbutton.
function clear_label_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to clear_label_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data=cell(10,8);
data(:)={''};
handles.output=data;
set(handles.labels_table, 'Data', data);
guidata(hObject, handles);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);
