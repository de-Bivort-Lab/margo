function varargout = analysisoptions_gui(varargin)
% ANALYSISOPTIONS_GUI MATLAB code for analysisoptions_gui.fig
%      ANALYSISOPTIONS_GUI, by itself, creates a new ANALYSISOPTIONS_GUI or raises the existing
%      singleton*.
%
%      H = ANALYSISOPTIONS_GUI returns the handle to a new ANALYSISOPTIONS_GUI or the handle to
%      the existing singleton*.
%
%      ANALYSISOPTIONS_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ANALYSISOPTIONS_GUI.M with the given input arguments.
%
%      ANALYSISOPTIONS_GUI('Property','Value',...) creates a new ANALYSISOPTIONS_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before analysisoptions_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to analysisoptions_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help analysisoptions_gui

% Last Modified by GUIDE v2.5 11-May-2018 12:30:10

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @analysisoptions_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @analysisoptions_gui_OutputFcn, ...
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




% --- Executes just before analysisoptions_gui is made visible.
function analysisoptions_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure


% varargin   command line arguments to analysisoptions_gui (see VARARGIN)


    expmt = varargin{1};
    
    if isfield(expmt.meta,'options')
        opt = expmt.meta.options;
    else
        [~,opt] = defaultAnalysisOptions;
    end
    
    if isfield(expmt.meta,'fields')
        f = expmt.fields;
    else
        [f,~] = defaultAnalysisOptions;
    end

    handles.output = expmt;
    handles.output.meta.options;
    handles.output.fields = f;
    
    light_uipanel = findobj('Tag','light_uipanel');
    gui_fig = findobj('Name','autotracker');
    handles.figure1.Position(1) = gui_fig.Position(1) + ...
        sum(light_uipanel.Position([1 3]));
    handles.figure1.Position(2) = gui_fig.Position(2) + ...
        sum(light_uipanel.Position([2 4])) - handles.figure1.Position(4) - 25;
    
    % initialize processing checkboxes
    fn = fieldnames(opt);
    for i=1:numel(fn)
        clear h
        switch fn{i}
            case 'disable', h = handles.disable_checkbox;
            case 'handedness', h = handles.handedness_checkbox;
            case 'bouts', h = handles.bouts_checkbox;
            case 'bootstrap', h = handles.bootstrap_checkbox;
            case 'regress', h = handles.regress_checkbox;
            case 'slide', h = handles.slide_checkbox;
            case 'areathresh', h = handles.areathresh_checkbox;
            case 'raw',
                for j = 1:numel(opt.(fn{i}))
                    switch opt.(fn{i}){j}
                        case 'Speed', handles.trackProps_speed_checkbox.Value = true;
                        case 'Direction', handles.direction_checkbox.Value = true;
                        case 'Theta', handles.theta_checkbox.Value = true;
                        case 'Radius', handles.radius_checkbox.Value = true;
                    end
                end
        end
        
        if exist('h','var')
            h.Value = logical(opt.(fn{i}));
        end
    end

    % initialize output field checkboxes
    for i=1:numel(f)
        clear h
        switch f{i}
            case 'Orientation', h = handles.orientation_checkbox;
            case 'Area', h = handles.area_checkbox;
            case 'WeightedCentroid', h = handles.weightedcentroid_checkbox;
            case 'MajorAxisLength', h = handles.major_axis_checkbox;
            case 'MinorAxisLength', h = handles.minor_axis_checkbox;
            case 'Speed', h = handles.speed_checkbox;
        end
        
        if exist('h','var')
            h.Value = true;
        end

    end
    
    
    if opt.disable
        hCheck = findobj(handles.figure1,'-depth',3,'Style','checkbox');
        set(hCheck,'Enable','off');
        handles.disable_checkbox.Enable = 'on';
    end
    
   
% Update handles structure
guidata(hObject, handles);







% --- Outputs from this function are returned to the command line.
function varargout = analysisoptions_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure



% Get default command line output from handles structure
while ishghandle(hObject)
    handles = guidata(hObject);
    varargout(1) = {handles.output};
    pause(0.002);
    drawnow
end







% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)

delete(hObject);


% --- Executes on button press in disable_checkbox.
function disable_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to disable_checkbox (see GCBO)

handles.output.meta.options.disable = hObject.Value;
hCheck = findobj(handles.figure1,'-depth',3,'Style','checkbox');
if hObject.Value
    set(hCheck,'Enable','off');
else
    set(hCheck,'Enable','on');
end
hObject.Enable = 'on';
guidata(hObject,handles);


% --- Executes on button press in handedness_checkbox.
function handedness_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to handedness_checkbox (see GCBO)

handles.output.meta.options.handedness = hObject.Value;
guidata(hObject,handles);


% --- Executes on button press in regress_checkbox.
function regress_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to regress_checkbox (see GCBO)

handles.output.meta.options.regress = hObject.Value;
guidata(hObject,handles);


% --- Executes on button press in slide_checkbox.
function slide_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to slide_checkbox (see GCBO)

handles.output.meta.options.slide = hObject.Value;
guidata(hObject,handles);


% --- Executes on button press in bootstrap_checkbox.
function bootstrap_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to bootstrap_checkbox (see GCBO)

handles.output.meta.options.bootstrap = hObject.Value;
guidata(hObject,handles);


% --- Executes on button press in bouts_checkbox.
function bouts_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to bouts_checkbox (see GCBO)

handles.output.meta.options.bouts = hObject.Value;
guidata(hObject,handles);


% --- Executes on button press in areathresh_checkbox.
function areathresh_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to areathresh_checkbox (see GCBO)

handles.output.meta.options.areathresh = hObject.Value;
guidata(hObject,handles);


% --- Executes on button press in speed_checkbox.
function speed_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to speed_checkbox (see GCBO)

f = handles.output.fields;
if hObject.Value
     if ~any(strcmp('Speed',f))
         f = [f;{'Speed'}];
     end
else
     if any(strcmp('Speed',f))
         idx = strcmp('Speed',f);
         f(idx) = [];
     end
end
handles.output.fields = f;
guidata(hObject,handles);



% --- Executes on button press in area_checkbox.
function area_checkbox_Callback(hObject, eventdata, handles) %#ok<*INUSD>
% hObject    handle to area_checkbox (see GCBO)

f = handles.output.fields;
if hObject.Value
     if ~any(strcmp('Area',f))
         f = [f;{'Area'}];
     end
else
     if any(strcmp('Area',f))
         idx = strcmp('Area',f);
         f(idx) = [];
     end
end
handles.output.fields = f;
guidata(hObject,handles);



% --- Executes on button press in orientation_checkbox.
function orientation_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to orientation_checkbox (see GCBO)

f = handles.output.fields;
if hObject.Value
     if ~any(strcmp('Orientation',f))
         f = [f;{'Orientation'}];
     end
else
     if any(strcmp('Orientation',f))
         idx = strcmp('Orientation',f);
         f(idx) = [];
     end
end
handles.output.fields = f;
guidata(hObject,handles);




% --- Executes on button press in weightedcentroid_checkbox.
function weightedcentroid_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to weightedcentroid_checkbox (see GCBO)

f = handles.output.fields;
if hObject.Value
     if ~any(strcmp('WeightedCentroid',f))
         f = [f;{'WeightedCentroid'}];
     end
else
     if any(strcmp('WeightedCentroid',f))
         idx = strcmp('WeightedCentroid',f);
         f(idx) = [];
     end
end
handles.output.fields = f;
guidata(hObject,handles);




% --- Executes on button press in major_axis_checkbox.
function major_axis_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to major_axis_checkbox (see GCBO)

f = handles.output.fields;
if hObject.Value
     if ~any(strcmp('MajorAxisLength',f))
         f = [f;{'MajorAxisLength'}];
     end
else
     if any(strcmp('MajorAxisLength',f))
         idx = strcmp('MajorAxisLength',f);
         f(idx) = [];
     end
end
handles.output.fields = f;
guidata(hObject,handles);


% --- Executes on button press in minor_axis_checkbox.
function minor_axis_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to minor_axis_checkbox (see GCBO)

f = handles.output.fields;
if hObject.Value
     if ~any(strcmp('MinorAxisLength',f))
         f = [f;{'MinorAxisLength'}];
     end
else
     if any(strcmp('MinorAxisLength',f))
         idx = strcmp('MinorAxisLength',f);
         f(idx) = [];
     end
end
handles.output.fields = f;
guidata(hObject,handles);




% --- Executes on button press in trackProps_speed_checkbox.
function trackProps_speed_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to trackProps_speed_checkbox (see GCBO)

if isfield(handles.output.meta.options,'raw')
    r = handles.output.meta.options.raw;
else
    r={};
end


if hObject.Value
     if ~any(strcmp('Speed',r))
         r = [r;{'Speed'}];
     end
else
     if any(strcmp('Speed',r))
         idx = strcmp('Speed',r);
         r(idx) = [];
     end
end

handles.output.meta.options.raw = r;
if isempty(r)
    handles.output.meta.options = rmfield(handles.output.meta.options,'raw');
end

guidata(hObject,handles);





% --- Executes on button press in direction_checkbox.
function direction_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to direction_checkbox (see GCBO)

if isfield(handles.output.meta.options,'raw')
    r = handles.output.meta.options.raw;
else
    r={};
end


if hObject.Value
     if ~any(strcmp('Direction',r))
         r = [r;{'Direction'}];
     end
else
     if any(strcmp('Direction',r))
         idx = strcmp('Direction',r);
         r(idx) = [];
     end
end

handles.output.meta.options.raw = r;
if isempty(r)
    handles.output.meta.options = rmfield(handles.output.meta.options,'raw');
end

guidata(hObject,handles);




% --- Executes on button press in radius_checkbox.
function radius_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to radius_checkbox (see GCBO)

if isfield(handles.output.meta.options,'raw')
    r = handles.output.meta.options.raw;
else
    r={};
end


if hObject.Value
     if ~any(strcmp('Radius',r))
         r = [r;{'Radius'}];
     end
else
     if any(strcmp('Radius',r))
         idx = strcmp('Radius',r);
         r(idx) = [];
     end
end

handles.output.meta.options.raw = r;
if isempty(r)
    handles.output.meta.options = rmfield(handles.output.meta.options,'raw');
end

guidata(hObject,handles);


% --- Executes on button press in theta_checkbox.
function theta_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to theta_checkbox (see GCBO)


if isfield(handles.output.meta.options,'raw')
    r = handles.output.meta.options.raw;
else
    r={};
end


if hObject.Value
     if ~any(strcmp('Theta',r))
         r = [r;{'Theta'}];
     end
else
     if any(strcmp('Theta',r))
         idx = strcmp('Theta',r);
         r(idx) = [];
     end
end

handles.output.meta.options.raw = r;
if isempty(r)
    handles.output.meta.options = rmfield(handles.output.meta.options,'raw');
end

guidata(hObject,handles);

