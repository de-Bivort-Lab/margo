function varargout = optomotor_parameter_gui(varargin)
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

% Last Modified by GUIDE v2.5 27-Apr-2017 14:26:43

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @optomotor_parameter_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @optomotor_parameter_gui_OutputFcn, ...
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
function optomotor_parameter_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to optomotor_parameter_gui (see VARARGIN)


    expmt = varargin{1};
    
    if isfield(expmt,'opto_parameters')
       parameters = expmt.opto_parameters;
    else
       parameters = expmt.parameters;
    end
     
    % Clear the workspace
    sca;

    % Here we call some default settings for setting up Psychtoolbox
    available_screens = Screen('Screens');
    disp_str = cell(length(available_screens),1);
    for i = 1:length(available_screens)
        [w,h]=Screen('WindowSize',i-1);
        disp_str(i) = {['display ' num2str(i-1) ' (' num2str(w) 'x' num2str(h) ')']};
    end

    handles.scr_popupmenu.String = disp_str;
    handles.scr_popupmenu.Value = 1;
    
    if isfield(expmt.hardware.projector,'reg_params')
        handles.scr_popupmenu.Value = expmt.hardware.projector.reg_params.screen_num+1;
    else
        expmt.hardware.projector.reg_params.screen_num = 0;
    end
    
    handles.output = expmt;
    
    if isfield(parameters,'stim_duration')
        set(handles.edit_stim_duration,'string',parameters.stim_duration);
    end
    
    if isfield(parameters,'stim_int')
        set(handles.edit_stim_int,'string',parameters.stim_int);
    end
    
    if isfield(parameters,'ang_per_frame')
        set(handles.edit_ang_per_frame,'string',parameters.ang_per_frame);
    end
    
    if isfield(parameters,'num_cycles')
        set(handles.edit_num_cycles,'string',parameters.num_cycles);
    end
    
    if isfield(parameters,'mask_r')
        set(handles.edit_mask_r,'string',parameters.mask_r);
    end
     
    if isfield(parameters,'contrast')
        set(handles.edit_contrast,'string',parameters.contrast);
    end
    
    if isfield(parameters,'stim_mode')
        switch parameters.stim_mode
            case 'constant', handles.stim_mode_popupmenu.Value = 1;
            case 'sweep', handles.stim_mode_popupmenu.Value = 2; handles.sweep_uitable.Enable = 'on';
        end
    else
        handles.output.parameters.stim_mode = 'constant';
    end
    
    if isfield(expmt,'sweep')
        f = fieldnames(expmt.sweep);
        d = cell(20,3);
        for i = 1:length(f)
            switch f{i}
                case 'contrasts'
                    d(1:length(expmt.sweep.(f{i})),i) = num2cell(expmt.sweep.(f{i}));
                case 'ang_vel'
                    d(1:length(expmt.sweep.(f{i})),i) = num2cell(expmt.sweep.(f{i}));
                case 'spatial_freq'
                    d(1:length(expmt.sweep.(f{i})),i) = num2cell(expmt.sweep.(f{i}));
            end
        end
        hasData = any(~cellfun(@isempty,d),2);
        d(~hasData,:)=[];
        handles.sweep_uitable.Data = d;
        if isfield(expmt.sweep,'interval')
            handles.edit_block_interval.String = num2str(expmt.sweep.interval);
        else
            handles.output.sweep.interval = str2double(handles.edit_block_interval.String);
        end
    else
        handles.sweep_uitable.Data = cell(8,3);
    end


    handles.output.parameters.stim_duration=str2num(get(handles.edit_stim_duration,'string'));
    handles.output.parameters.stim_int=str2num(get(handles.edit_stim_int,'string'));
    handles.output.parameters.ang_per_frame=str2num(get(handles.edit_ang_per_frame,'string'));
    handles.output.parameters.num_cycles=str2num(get(handles.edit_num_cycles,'string'));
    handles.output.parameters.mask_r=str2num(get(handles.edit_mask_r,'string'));
    handles.output.parameters.contrast=str2num(get(handles.edit_contrast,'string'));
    handles.output.parameters.stim_mode=handles.stim_mode_popupmenu.String{handles.stim_mode_popupmenu.Value};
    
    light_uipanel = findobj('Tag','light_uipanel');
    gui_fig = findobj('Name','autotracker');
    handles.figure1.Position(1) = gui_fig.Position(1) + ...
        sum(light_uipanel.Position([1 3]));
    handles.figure1.Position(2) = gui_fig.Position(2) + ...
        sum(light_uipanel.Position([2 4])) - handles.figure1.Position(4) - 25;
    


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes optomotor_parameter_gui wait for user response (see UIRESUME)
uiwait(handles.figure1);




% --- Outputs from this function are returned to the command line.
function varargout = optomotor_parameter_gui_OutputFcn(hObject, eventdata, handles) 
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




function edit_ang_per_frame_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ang_per_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output.parameters.ang_per_frame=str2num(get(handles.edit_ang_per_frame,'string'));
guidata(hObject, handles);




% --- Executes during object creation, after setting all properties.
function edit_ang_per_frame_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ang_per_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




function edit_mask_r_Callback(hObject, eventdata, handles)
% hObject    handle to edit_mask_r (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output.parameters.mask_r=str2num(get(handles.edit_mask_r,'string'));
guidata(hObject, handles);




% --- Executes during object creation, after setting all properties.
function edit_mask_r_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_mask_r (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_num_cycles_Callback(hObject, eventdata, handles)
% hObject    handle to edit_num_cycles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output.parameters.num_cycles=str2num(get(handles.edit_num_cycles,'string'));
guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function edit_num_cycles_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_num_cycles (see GCBO)
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
guidata(hObject, handles);
uiresume(handles.figure1);



% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(hObject);



function edit_stim_int_Callback(hObject, eventdata, handles)
% hObject    handle to edit_stim_int (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output.parameters.stim_int=str2num(get(handles.edit_stim_int,'string'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_stim_int_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_stim_int (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_stim_duration_Callback(hObject, eventdata, handles)
% hObject    handle to edit_stim_duration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output.parameters.stim_duration=str2num(get(handles.edit_stim_duration,'string'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_stim_duration_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_stim_duration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_contrast_Callback(hObject, eventdata, handles)
% hObject    handle to edit_contrast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output.parameters.contrast = str2num(get(handles.edit_contrast,'string'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_contrast_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_contrast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in scr_popupmenu.
function scr_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to scr_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output.reg_params.screen_num = handles.scr_popupmenu.Value-1;
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function scr_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scr_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in stim_mode_popupmenu.
function stim_mode_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to stim_mode_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

switch hObject.Value
    case 1 
        handles.sweep_uitable.Enable = 'off';
        handles.output.parameters.stim_mode = 'constant';
    case 2
        handles.sweep_uitable.Enable = 'on'; 
        handles.output.parameters.stim_mode = 'sweep';
        handles.output.sweep.interval = str2double(handles.edit_block_interval.String);
end
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function stim_mode_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stim_mode_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when entered data in editable cell(s) in sweep_uitable.
function sweep_uitable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to sweep_uitable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)

interval = str2double(handles.edit_block_interval.String);


data = hObject.Data;
hasData = ~cellfun(@isempty,data);

for i = 1:size(data,2)
    switch i
        case 1, sweep.contrasts = [data{hasData(:,i),i}];
        case 2, sweep.ang_vel = [data{hasData(:,i),i}];
        case 3, sweep.spatial_freq = [data{hasData(:,i),i}];
    end
end

sweep.interval = interval;

handles.output.sweep = sweep;
guidata(hObject,handles);
        
        
        
        


% --- Executes on button press in addrow_pushbutton.
function addrow_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to addrow_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

d=handles.sweep_uitable.Data;
[r,c] = size(d);
nd = cell(r+1,c);
nd(1:r,1:c) = d;
handles.sweep_uitable.Data = nd;
guidata(hObject,handles);


% --- Executes on button press in subrow_pushbutton.
function subrow_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to subrow_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

d=handles.sweep_uitable.Data;
[r,c] = size(d);
nd = cell(r-1,c);
nd(:,1:c) = d(1:r-1,:);
handles.sweep_uitable.Data = nd;
guidata(hObject,handles);



function edit_block_interval_Callback(hObject, eventdata, handles)
% hObject    handle to edit_block_interval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.output.sweep.interval = str2double(hObject.String);
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_block_interval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_block_interval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
