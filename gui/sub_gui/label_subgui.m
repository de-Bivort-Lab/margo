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

% Last Modified by GUIDE v2.5 19-Dec-2018 17:50:42

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
expmt = varargin{1};
if ~isempty(expmt.meta.labels)
    label_data = expmt.meta.labels;
    if cellfun('isempty',label_data(1,4))
        label_data(1,4) = {1};
        label_data(1,5) = {size(expmt.meta.roi.centers,1)};
        label_data(1,6) = {1};
        label_data(1,7) = {size(expmt.meta.roi.centers,1)};
    end
    if cellfun('isempty',label_data(1,8))
        label_data(1,8) = {1};
    end
    
    label_data(cellfun(@(d) any(isnan(d)),label_data)) = {''};
    handles.output=label_data;
    set(handles.labels_table, 'Data', label_data);
else
    label_data = defaultLabels(expmt);
    set(handles.labels_table, 'Data', label_data);
    handles.output=hObject.Children(3).Data;
end

if numel(varargin)>1
    status = varargin{2};
    handles.label_fig.Visible = status;
end

gui_fig = findobj('Name','margo');
light_panel = findobj('Tag','cam_uipanel');
handles.label_fig.Position(1) = gui_fig.Position(1) + ...
    light_panel.Position(1);
handles.label_fig.Position(2) = gui_fig.Position(2) + ...
    sum(light_panel.Position([2 4])) - handles.label_fig.Position(4) - 25;

% Update handles structure
setappdata(handles.label_fig,'expmt',expmt);
guidata(hObject, handles);

% UIWAIT makes optomotor_parameter_gui wait for user response (see UIRESUME)
uiwait(handles.label_fig);


% --- Outputs from this function are returned to the command line.
function varargout = label_subgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if isfield(handles,'output')
    varargout{1} = handles.output;
    close(handles.label_fig);
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

% retrieve ExperimentData
expmt = getappdata(handles.label_fig,'expmt');


idx = eventdata.Indices;
new_data = eventdata.NewData;
col_names = handles.labels_table.ColumnName;
numeric_cols = {'ROI Start';'ROI End';'ID Start';'ID End';'Day #';'Box #';'Tray #'};
if any(strcmpi(col_names{idx(2)},numeric_cols)) && ischar(new_data)
    new_data= str2double(new_data);
end
if isnan(new_data)
    hObject.Data{idx(1),idx(2)} = '';
    handles.output{idx(1),idx(2)} = '';
    return;
end

hObject.Data{idx(1), idx(2)} = new_data;
row = hObject.Data(idx(1),:);

% get ROI and ID ranges
roi_start = row{1,strcmpi('ROI Start',col_names)};
roi_end = row{1,strcmpi('ROI End',col_names)};
id_start = row{1,strcmpi('ID Start',col_names)};

% enforce valid ranges
roi_start(roi_start<1) = 1;
roi_start(roi_start>expmt.meta.roi.n) = expmt.meta.roi.n;
roi_end(roi_end<1) = 1;
roi_end(roi_end>expmt.meta.roi.n) = expmt.meta.roi.n;
roi_end(roi_end<roi_start) = roi_start;

% query available roi slots
other_rows = [1:idx(1)-1 idx(1)+1:size(hObject.Data,1)];
[unlabeled_rois, free_roi_start, free_roi_end] = ...
    get_available_rois(hObject.Data(other_rows,:), expmt.meta.roi.n);
if ~any(unlabeled_rois)
    hObject.Data{idx(1), idx(2)} = '';
    errordlg('Cannot assign additional labels. All available ROIs already assigned.');
   return; 
end
if isempty(roi_start) || isempty(roi_end) || any(~unlabeled_rois(roi_start:roi_end))
    roi_start = free_roi_start;
    roi_end = free_roi_end;
end

% shift ID range if necessary
id_end = id_start + roi_end - roi_start;
hObject.Data{idx(1),strcmpi('ROI Start',col_names)} = roi_start;
hObject.Data{idx(1),strcmpi('ROI End',col_names)} = roi_end;
hObject.Data{idx(1),strcmpi('ID End',col_names)} = id_end;

% update output
handles.output{idx(1), idx(2)} = hObject.Data{idx(1),idx(2)};
guidata(hObject, handles);


% --- Executes on button press in accept_label_pushbutton.
function accept_label_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to accept_label_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output=handles.labels_table.Data;
guidata(hObject, handles);
uiresume(handles.label_fig);


% --- Executes on button press in clear_label_pushbutton.
function clear_label_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to clear_label_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data=cell(5,11);
data(:)={''};
handles.output=data;
set(handles.labels_table, 'Data', data);
guidata(hObject, handles);


% --- Executes when user attempts to close label_fig.
function label_fig_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to label_fig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes when selected cell(s) is changed in labels_table.
function labels_table_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to labels_table (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)

% retrieve ExperimentData
expmt = getappdata(handles.label_fig,'expmt');

idx = eventdata.Indices;
if isempty(idx)
    return
end
row = hObject.Data(idx(1),:);
prev_idx = idx(1)-1;
col_names = hObject.ColumnName;

if all(cellfun(@isempty,row)) && prev_idx
    
    % query available roi slots
    [unlabeled_rois, roi_start, roi_end] = ...
        get_available_rois(hObject.Data, expmt.meta.roi.n);
    if ~any(unlabeled_rois)
       return; 
    end

    row = hObject.Data(prev_idx,:);

    % enforce valid ranges
    roi_start(roi_start<1) = 1;
    roi_start(roi_start>expmt.meta.roi.n) = expmt.meta.roi.n;
    roi_end(roi_end<1) = 1;
    roi_end(roi_end>expmt.meta.roi.n) = expmt.meta.roi.n;
    roi_end(roi_end<roi_start) = roi_start;
    
    % ids
    id_ranges = hObject.Data(:,strcmpi('ID end',col_names));
    id_ranges(cellfun(@isempty,id_ranges)) = {[]};
    id_ranges = cat(1,id_ranges{:});
    id_start = max(id_ranges) + 1;
    
    % re-assign to labels table
    row{1,strcmpi('ROI End',col_names)} = roi_end;
    row{1,strcmpi('ROI Start',col_names)} = roi_start;
    row{1,strcmpi('ID Start',col_names)} = id_start;
    
    % initialize ID range
    id_end = id_start + roi_end - roi_start;
    row{1,strcmpi('ID End',col_names)} = id_end;
    
    hObject.Data(idx(1),:) = row;
end

handles.output = hObject.Data;
guidata(hObject,handles);


function [is_unlabeled, roi_start, roi_end] = get_available_rois(data, max_n)

label_ranges = data(:,4:5);
label_ranges(cellfun(@isempty,label_ranges)) = {[]};
labeled_rois = cellfun(@(r) r(1):r(2), ...
    num2cell(cell2mat(label_ranges),2),'UniformOutput',false);
labeled_rois = cat(2,labeled_rois{:});
is_unlabeled = ~ismember(1:max_n,labeled_rois);
unlabeled_rois = [0 diff(is_unlabeled)];

roi_start = find(unlabeled_rois==1,1);
roi_end = find(unlabeled_rois==-1,1)-1;
if isempty(roi_start) || (~isempty(roi_end) && roi_end < roi_start)
    roi_start = 1;
end
if isempty(roi_end)
    roi_end = max_n;
end
