function varargout = autotracker(varargin)
% AUTOTRACKER MATLAB code for autotracker.fig
%      AUTOTRACKER, by itself, creates a new AUTOTRACKER or raises the existing
%      singleton*.
%
%      H = AUTOTRACKER returns the handle to a new AUTOTRACKER or the handle to
%      the existing singleton*.
%
%      AUTOTRACKER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in AUTOTRACKER.M with the given input arguments.
%
%      AUTOTRACKER('Property','Value',...) creates a new AUTOTRACKER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before autotracker_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to autotracker_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help autotracker

% Last Modified by GUIDE v2.5 26-Jun-2018 21:56:11

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @autotracker_OpeningFcn, ...
                   'gui_OutputFcn',  @autotracker_OutputFcn, ...
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


% --- Executes just before autotracker is made visible.
function autotracker_OpeningFcn(hObject, ~, handles, varargin)
% hObject    handle to figure
% varargin   command line arguments to autotracker (see VARARGIN)

% configure the figure window, display, and handles
handles = defaultConfigureGUI(handles);

% initialize array indicating expIDs for experiments with an associated
% parameter subgui. NOTE: any custom experiments with an experiment
% parameters subgui must be added to this list.
handles.parameter_subgui = {'Circadian';'Optomotor';'Slow Phototaxis';...
    'Temporal Phototaxis';'Arena Blocks'};


% initialize ExperimentData obj
expmt = ExperimentData;

% cam setup
expmt.meta.source = 'camera';       % set the source mode to camera by default
[expmt.hardware.cam,handles.cam_list] = ...
        refresh_cam_list(handles);  % query available cameras and camera info

cam_dir = [handles.gui_dir '/hardware/camera_calibration/'];
handles.cam_calibrate_menu.UserData = false;

if exist(cam_dir,'dir')==7
    
    cam_files = recursiveSearch(cam_dir);
    var_names = cell(length(cam_files),1);
    for i=1:length(cam_files)
        vn = {who('-file',cam_files{i})};
        var_names(i) = vn;
        load(cam_files{i});
    end
    allvars = whos;
    
    if any(strcmp('cameraParameters',{allvars.class}))
        target_name = allvars(find(strcmp('cameraParameters',{allvars.class}),1,'first')).name;
        target_file = cellfun(@(x) strcmp(target_name,x),var_names,'UniformOutput',false);
        target_file = target_file{find(~cellfun(@isempty,target_file),1,'first')};
        param_obj = load(cam_files{target_file},target_name);
        expmt.hardware.cam.calibration = param_obj.(target_name);
    end
    
end

% query ports and initialize COM objects
[expmt, handles] = refreshCOM(expmt, handles);

% Initialize experiment parameters from text boxes in the GUI
p = expmt.parameters;
handles.edit_ref_depth.Value  = p.ref_depth;
handles.edit_ref_freq.Value = p.ref_freq;
handles.edit_exp_duration.Value = p.duration;
handles.ROI_thresh_slider.Value = ceil(p.roi_thresh);
handles.track_thresh_slider.Value = ceil(p.track_thresh);
handles.disp_ROI_thresh.String = num2str(handles.ROI_thresh_slider.Value);
handles.disp_track_thresh.String = num2str(handles.track_thresh_slider.Value);
handles.edit_target_rate.String = num2str(p.target_rate);
handles.edit_area_maximum.String = num2str(p.area_max);

% set analysis options
[~,expmt.meta.options] = defaultAnalysisOptions;


setappdata(handles.gui_fig,'expmt',expmt);

% Update handles structure
guidata(hObject,handles);

% UIWAIT makes autotracker wait for user response (see UIRESUME)
% uiwait(handles.gui_fig);

% --- Outputs from this function are returned to the command line.
function varargout = autotracker_OutputFcn(hObject, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure

% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = [];






%-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**-*-*-*-*-*-*-* -%
%-*-*-*-*-*-*-*-*-*-*-*-CAMERA FUNCTIONS-*-*-*-*-*-*-*-*-*-*-*-*%
%-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**-*-*-*-*-*-*-*-*%



% --- Executes on selection change in cam_select_popupmenu.
function cam_select_popupmenu_Callback(hObject, ~, handles)
% hObject    handle to cam_select_popupmenu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% import expmteriment variables
expmt = getappdata(handles.gui_fig,'expmt');

if ~isempty(handles.cam_list(get(hObject,'value')).adaptor)
    
    % get camera adaptor
    adaptor = handles.cam_list(get(hObject,'value')).adaptor;
    
    camInfo = imaqhwinfo(adaptor);
    deviceInfo = camInfo.DeviceInfo(handles.cam_list(get(hObject,'value')).index);
    
    set(handles.cam_mode_popupmenu,'String',deviceInfo.SupportedFormats);
    default_format = deviceInfo.DefaultFormat;

    for i = 1:length(deviceInfo.SupportedFormats)
        if strcmp(default_format,camInfo.DeviceInfo(1).SupportedFormats{i})
            set(handles.cam_mode_popupmenu,'Value',i);
            camInfo.ActiveMode = camInfo.DeviceInfo(1).SupportedFormats(i);
        end
    end
    
    expmt.hardware.cam = camInfo;
    expmt.hardware.cam.activeID = handles.cam_list(get(hObject,'value')).index;
    
end

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);
guidata(hObject,handles);



% --- Executes during object creation, after setting all properties.
function cam_select_popupmenu_CreateFcn(hObject,~,~)
% hObject    handle to cam_select_popupmenu (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    
    set(hObject,'BackgroundColor','white');
end



% --- Executes on selection change in cam_mode_popupmenu.
function cam_mode_popupmenu_Callback(hObject, ~, handles)
% hObject    handle to cam_mode_popupmenu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

expmt = getappdata(handles.gui_fig,'expmt');

strCell = get(handles.cam_mode_popupmenu,'string');
expmt.hardware.cam.ActiveMode = strCell(get(handles.cam_mode_popupmenu,'Value'));

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function cam_mode_popupmenu_CreateFcn(hObject,~,~)
% hObject    handle to cam_mode_popupmenu (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Cam_confirm_pushbutton.
function Cam_confirm_pushbutton_Callback(hObject, ~, handles)
% hObject    handle to Cam_confirm_pushbutton (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

if ~isempty(expmt.hardware.cam)
    if ~isempty(expmt.hardware.cam.DeviceInfo)
        
        % query the Enable states of objects in the gui
        clean_gui(handles.axes_handle);
        on_objs = findobj('Enable','on');
        off_objs = findobj('Enable','off');
        
        % disable all gui features during camera initialization
        set(findall(handles.gui_fig, '-property', 'Enable'), 'Enable', 'off');
        handles.disp_note.Enable='on';
        
        handles.Cam_preview_togglebutton.Enable = 'off';
        
        gui_notify('initializing camera',handles.disp_note);
        gui_notify('may take a few moments...',handles.disp_note);
        imaqreset;
        pause(0.01);
        expmt.hardware.cam = initializeCamera(expmt.hardware.cam);
        start(expmt.hardware.cam.vid);
        gui_notify('camera started, measuring frame rate...',handles.disp_note);
        drawnow
        
        % Store expmteriment data struct
        setappdata(handles.gui_fig,'expmt',expmt);
        pause(0.09);
        
        % measure frame rate
        [frame_rate, expmt.hardware.cam] = estimateFrameRate(expmt.hardware.cam);
        expmt.hardware.cam.frame_rate = frame_rate;
        
        if expmt.parameters.target_rate == 60
            expmt.parameters.target_rate = frame_rate;
        end
        
        % adjust aspect ratio of plot to match camera
        colormap('gray');
        im = peekdata(expmt.hardware.cam.vid,1);
        switch class(im)
            case 'uint8'
                expmt.hardware.cam.bitDepth = 8;
            case 'int8'
                expmt.hardware.cam.bitDepth = 8;
            case 'uint16'
                expmt.hardware.cam.bitDepth = 16;
            case 'int16'
                expmt.hardware.cam.bitDepth = 16;
            case 'uint32'
                expmt.hardware.cam.bitDepth = 32;
            case 'int32'
                expmt.hardware.cam.bitDepth = 32;
        end
        
        clean_gui(handles.axes_handle);
        handles.hImage = imagesc(im);
        set(handles.axes_handle,'Xtick',[],'Ytick',[],'XLabel',[],'YLabel',[]);
        res = expmt.hardware.cam.vid.VideoResolution;
        handles.axes_handle.Position(3) = ...
            handles.gui_fig.Position(3) - 5 - handles.axes_handle.Position(1);
        handles.gui_fig.Position(3) = handles.gui_fig.Position(3)+1;
        handles.gui_fig.Position(3) = handles.gui_fig.Position(3)-1;

        
        % set the colormap and axes ticks
        colormap('gray');
        set(gca,'Xtick',[],'Ytick',[],'XLabel',[],'YLabel',[]);
        
        % reset the Enable states of objects in the gui
        set(on_objs,'Enable','on');
        set(off_objs,'Enable','off');
        
        % set downstream UI panel Enable status
        handles.tracking_uipanel.ForegroundColor = [0 0 0];
        set(findall(handles.tracking_uipanel, '-property', 'Enable'), 'Enable', 'on');
        handles.distance_scale_menu.Enable = 'on';
        handles.vignette_correction_menu.Enable = 'on';
        
        if ~isfield(expmt.meta.roi,'n') || ~expmt.meta.roi.n
            handles.track_thresh_slider.Enable = 'off';
            handles.accept_track_thresh_pushbutton.Enable = 'off';
            handles.reference_pushbutton.Enable = 'off';
            handles.track_thresh_label.Enable = 'off';
            handles.disp_track_thresh.Enable = 'off';
        end
        
        if ~isfield(expmt.meta.ref,'im')
            handles.sample_noise_pushbutton.Enable = 'off';
        end
        
        % re-initialize ExperimentData obj
        if isfield(expmt.meta.roi,'n') && expmt.meta.roi.n
            expmt = reInitialize(expmt);
            msgbox(['Cam settings changed: any ROIs, references or ' ...
                'noise statistics have been discarded.']);
            note = 'ROIs, references, and noise statistics reset';
            gui_notify(note,handles.disp_note);
        end
        
        gui_notify('cam settings confirmed',handles.disp_note);
        note = ['frame rate measured at ' ...
            num2str(round(frame_rate*100)/100) 'fps'];
        gui_notify(note, handles.disp_note);
        note = ['resolution: ' num2str(res(1)) ' x ' num2str(res(2))];
        gui_notify(note, handles.disp_note);
        
        handles.Cam_preview_togglebutton.Enable = 'on';
        
        if expmt.hardware.cam.bitDepth ~= 8
            errordlg([num2str(expmt.hardware.cam.bitDepth) ...
                '-bit image mode detected. Only 8-bit image modes are supported'],...
                'Unsupported Camera Mode');
        end
        
    else
        errordlg('Settings not confirmed, no camera detected');
    end
else
    errordlg('No cameras adaptors installed');
end

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);





% --- Executes on button press in Cam_preview_togglebutton.
function Cam_preview_togglebutton_Callback(hObject, ~, handles)
% hObject    handle to Cam_preview_togglebutton (see GCBO)
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');
clean_gui(handles.axes_handle);

handles.hImage = findobj(handles.axes_handle,'-depth',3,'Type','image');

switch get(hObject,'value')
    case 1
        if ~isempty(expmt.hardware.cam) && ~isfield(expmt.hardware.cam, 'vid')
            errordlg('Please confirm camera settings')
            hObject.Value = 0;
            
        elseif isfield(expmt.hardware.cam, 'vid') && ...
                ~isvalid(expmt.hardware.cam.vid)
            
            set(hObject,...
                'string','Stop preview','BackgroundColor',[0.8 0.45 0.45]);
            
            % Clear old video objects
            imaqreset
            pause(0.1);

            % Create camera object with input parameters
            expmt.hardware.cam = initializeCamera(expmt.hardware.cam);
            start(expmt.hardware.cam.vid);
            pause(0.1);
            set(handles.display_menu.Children,'Enable','on');
            hPreview = preview(expmt.hardware.cam.vid,handles.hImage);
            setappdata(hPreview,'UpdatePreviewWindowFcn',@autoPreviewUpdate);
            setappdata(hPreview,'gui_handles',handles);
            setappdata(hPreview,'expmt',expmt);
            
            
        elseif isfield(expmt.hardware.cam, 'vid') && ...
                strcmp(expmt.hardware.cam.vid.Running,'off')
            
            set(hObject,...
                'string','Stop preview','BackgroundColor',[0.8 0.45 0.45]);
            
            set(handles.display_menu.Children,'Enable','on');
            hPreview = preview(expmt.hardware.cam.vid,handles.hImage);
            setappdata(hPreview,'UpdatePreviewWindowFcn',@autoPreviewUpdate);
            setappdata(hPreview,'gui_handles',handles);
            setappdata(hPreview,'expmt',expmt);
            
        elseif isfield(expmt.hardware.cam, 'vid') && ...
                strcmp(expmt.hardware.cam.vid.Running,'on')
            
            set(hObject,'string','Stop preview','BackgroundColor',[0.8 0.45 0.45]);
            stoppreview(expmt.hardware.cam.vid);
            if isempty(handles.hImage)
                
                % Take single frame
                if strcmp(expmt.meta.source,'camera')
                    trackDat.im = peekdata(expmt.hardware.cam.vid,1);
                else
                    [trackDat.im, expmt.meta.video] = ...
                        nextFrame(expmt.meta.video,handles);
                end

                % extract green channel if format is RGB
                if size(trackDat.im,3)>1
                    trackDat.im = trackDat.im(:,:,2);
                end
                
                delete(findobj(handles.axes_handle,'-depth',3,'Type','image'));
                handles.hImage = ...
                    imagesc('Parent',handles.axes_handle,'CData',trackDat.im);
                colormap(handles.axes_handle,'gray');
                
            end
            
            set(handles.display_menu.Children,'Enable','on');
            hPreview = preview(expmt.hardware.cam.vid,handles.hImage);
            setappdata(hPreview,'UpdatePreviewWindowFcn',@autoPreviewUpdate);
            setappdata(hPreview,'gui_handles',handles);
            setappdata(hPreview,'expmt',expmt);
            
        end
    case 0
        if ~isempty(expmt.hardware.cam) && isfield(expmt.hardware.cam,'vid')
            stoppreview(expmt.hardware.cam.vid);           
            
            if size(handles.hImage.CData,3) > 1
                CData = handles.hImage.CData(:,:,2);
            else 
                CData = handles.hImage.CData;
            end          
            delete(handles.hImage);
            handles.hImage = ...
                imagesc('Parent',handles.axes_handle,'CData',CData);
            set(hObject,...
                'string','Start preview','BackgroundColor',[1 1 1]);
            set(handles.axes_handle,...
                'Xtick',[],'Ytick',[],'XtickLabel',[],'YtickLabel',[]);
        end
end




% --- Executes on selection change in microcontroller_popupmenu.
function microcontroller_popupmenu_Callback(hObject,~,handles)

% initialize new light COM
expmt = getappdata(handles.gui_fig,'expmt');
expmt.hardware.COM.light = serial(hObject.String{hObject.Value});
setappdata(handles.gui_fig,'expmt',expmt);
guidata(hObject,handles);





% --- Executes during object creation, after setting all properties.
function microcontroller_popupmenu_CreateFcn(hObject,~,~)
% hObject    handle to microcontroller_popupmenu (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_IR_intensity_Callback(hObject, ~, handles)
% hObject    handle to edit_IR_intensity (see GCBO)

% handles    structure with handles and user data (see GUIDATA)
% Initialize light panel at default values

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

expmt.hardware.light.infrared = str2double(get(handles.edit_IR_intensity,'string'));

% Convert intensity percentage to uint8 PWM value 0-255
expmt.hardware.light.infrared = uint8((expmt.hardware.light.infrared/100)*255);

writeInfraredWhitePanel(expmt.hardware.COM.light,1,...
    expmt.hardware.light.infrared);

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);


% --- Executes during object creation, after setting all properties.
function edit_IR_intensity_CreateFcn(hObject,~,~)
% hObject    handle to edit_IR_intensity (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_White_intensity_Callback(hObject, ~, handles)
% hObject    handle to edit_White_intensity (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

White_intensity = str2double(get(handles.edit_White_intensity,'string'));

% Convert intensity percentage to uint8 PWM value 0-255
expmt.hardware.light.white = uint8((White_intensity/100)*255);
writeInfraredWhitePanel(expmt.hardware.COM.light,0,...
    expmt.hardware.light.white);

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_White_intensity_CreateFcn(hObject,~,~)
% hObject    handle to edit_White_intensity (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in save_path_button1.
function save_path_button1_Callback(hObject, ~, handles)
% hObject    handle to save_path_button1 (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');
mat_dir = handles.gui_dir(1:strfind(handles.gui_dir,'MATLAB')+6);
default_path = [mat_dir 'autotracker_data/'];
if exist(default_path,'dir') ~= 7
    mkdir(default_path);
    msg_title = 'New Data Path';
    message = ['Autotracker has automatically generated a new default directory'...
        ' for data in ' default_path];
    
    % Display info
    waitfor(msgbox(message,msg_title));
end    

[fpath]  =  uigetdir(default_path,'Select a save destination');
expmt.meta.path.full = fpath;
set(handles.save_path,'string',fpath);

% if experiment parameters are set, Enable experiment run panel
if expmt.meta.exp_id > 1 && ~isempty(handles.save_path.String)
    set(findall(handles.run_uipanel, '-property', 'Enable'),'Enable','on');
    eb = findall(handles.run_uipanel, 'Style', 'edit');
    set(eb,'Enable','inactive','BackgroundColor',[.87 .87 .87]);
end


% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);



function save_path_Callback(~,~,~)
% hObject    handle to save_path (see GCBO)

% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function save_path_CreateFcn(hObject,~,~)
% hObject    handle to save_path (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function labels_uitable_CreateFcn(hObject, ~, handles)
% hObject    handle to labels_uitable (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

data=cell(10,11);
data(:) = {''};
set(hObject, 'Data', data);
expmt.meta.labels = data;

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);

% --- Executes when entered data in editable cell(s) in labels_uitable.
function labels_uitable_CellEditCallback(hObject, ~, handles)
% hObject    handle to labels_uitable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

expmt.meta.labels{eventdata.Indices(1), eventdata.Indices(2)} = {''};
expmt.meta.labels{eventdata.Indices(1), eventdata.Indices(2)} = eventdata.NewData;

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);


function edit_ref_depth_Callback(hObject, ~, handles)
% hObject    handle to edit_ref_depth (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

handles.edit_ref_depth.Value = str2double(get(handles.edit_ref_depth,'String'));
expmt.parameters.ref_depth = handles.edit_ref_depth.Value;

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_ref_depth_CreateFcn(hObject,~,~)
% hObject    handle to edit_ref_depth (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_ref_freq_Callback(hObject, ~, handles)
% hObject    handle to edit_ref_freq (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

handles.edit_ref_freq.Value = str2double(get(handles.edit_ref_freq,'String'));
expmt.parameters.ref_freq = handles.edit_ref_freq.Value;

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_ref_freq_CreateFcn(hObject,~,~)
% hObject    handle to edit_ref_freq (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_exp_duration_Callback(hObject, ~, handles)
% hObject    handle to edit_exp_duration (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

hObject.Value = str2double(get(handles.edit_exp_duration,'String'));
expmt.parameters.duration = hObject.Value;

if expmt.meta.initialize
    t_remain = str2double(hObject.String)*3600;
    updateTimeString(t_remain, handles.edit_time_remaining);
end


% --- Executes during object creation, after setting all properties.
function edit_exp_duration_CreateFcn(hObject,~,~)
% hObject    handle to edit_exp_duration (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in run_pushbutton.
function run_pushbutton_Callback(hObject, ~, handles)
% hObject    handle to run_pushbutton (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');
expmt.meta.initialize = true;

% query the Enable states of objects in the gui
handles.on_objs = findobj('Enable','on');
handles.off_objs = findobj('Enable','off');
keep_gui_state = false;

% check labels
hasLabelData = ~isempty(expmt.meta.labels);

% check setup before initializing tracking
if ~isfield(expmt.meta.path,'full')
    errordlg('Please specify Save Location')
    return
elseif ~hasLabelData
    errordlg('Please set labels before running experiment')
    return
elseif ~isfield(expmt.meta.roi,'n') && expmt.meta.roi.n
    errordlg('Please run ROI detection before starting tracking');
    return
elseif ~isfield(expmt.meta.ref,'im')
    errordlg('Please acquire a reference image before beginning tracking');
    return
elseif ~isfield(expmt.meta.noise,'dist')
    errordlg('Please run noise sampling before starting tracking');
    return
elseif any(strcmp(expmt.meta.name,handles.parameter_subgui)) &&...
        (~isfield(expmt.parameters,'initialized') ||...
        ~expmt.parameters.initialized)
    errordlg(['Parameters for the selected experiment'...
        'must be set before tracking']);
    return
end

    
try
    % disable controls that are not to be accessed while expmt is running
    toggleSubguis(handles,'off');
    toggleMenus(handles,'off');
    handles.run_pushbutton.Enable = 'off';

    % Execute the appropriate script for the selected experiment
    switch expmt.meta.name              
        case 'Optomotor'
            expmt = run_optomotor(expmt,handles);

        case 'Slow Phototaxis'
            expmt = run_slowphototaxis(expmt,handles);

        case 'LED Y-maze'
            expmt = run_ledymaze(expmt,handles);

        case 'Arena Circling'
            expmt = run_arenacircling(expmt,handles);

        case 'Y-maze'
            expmt = run_ymaze(expmt,handles);

        case 'Basic Tracking'
            expmt = run_basictracking(expmt,handles);     % Run expmt

        case 'Circadian'
            expmt = run_circadian(expmt,handles);

        case 'Temporal Phototaxis'
            expmt = run_tempphototaxis(expmt,handles);
    end
    
    % run post-processing
    if ~expmt.meta.finish
        keep_gui_state = true;
    elseif ~expmt.meta.options.disable
        expmt = autoAnalyze(expmt,'Handles',handles);
    end

    if isfield(expmt.data,'centroid') && isattached(expmt.data.centroid)
        ttl = 'Tracking Complete';
        msg = {'ROIs, references, and noise statistics reset';...
            'Would you like to plot raw tracking data?'};
        buttons = {'OK';'no thanks'};
        plot_traces = warningbox_subgui('title',ttl,'string',msg,...
            'buttons',buttons,'icon',false);
        if strcmp(plot_traces,'OK')
            plotTraces(expmt);
        end
    end

% re-establish gui state prior to tracking error is encountered
catch ME
    if isfield(handles,'deviceID')
        try
        [~,status]=urlread(['http://lab.debivort.org/mu.php?id=' handles.deviceID '&st=3']);
        catch
            status = false;
        end
        if ~status
            gui_notify(['unable to connect to'...
                ' http://lab.debivort.org'],handles.disp_note);
        end
    end
    
    switch expmt.meta.name
        case 'Slow Phototaxis', sca;
        case 'Optomotor', sca;
        case 'Temporal Phototaxis', sca;
    end
    gui_notify('error encountered - tracking stopped',handles.disp_note);
    keep_gui_state = true;
    title = 'Error encountered - tracking stopped';
    getReport(ME);
    msg=getReport(ME,'extended','hyperlinks','off');
    errordlg(msg,title);
end
    
if isfield(handles,'deviceID')
    try
    [~,status]=urlread(['http://lab.debivort.org/mu.php?id=' handles.deviceID '&st=2']);
    catch
        status = false;
    end
    if ~status
        gui_notify('unable to connect to http://lab.debivort.org',handles.disp_note);
    end
end
    
% re-Enable control set to off during experiment
toggleSubguis(handles,'on');
toggleMenus(handles,'on');
      
% remove saved rois, images, and noise statistics from prev experiment
if isfield(expmt.meta.roi,'n') && expmt.meta.roi.n && ~keep_gui_state

    % remove tracked fields from master expmt for next run
    expmt.meta.fields = {'centroid','time'};
    expmt = reInitialize(expmt);
    [~,expmt.meta.options] = defaultAnalysisOptions;
    note = 'ROIs, references, and noise statistics reset';
    gui_notify(note,handles.disp_note);

    % set downstream UI panel Enable status
    handles.tracking_uipanel.ForegroundColor = [0 0 0];
    set(findall(handles.tracking_uipanel, '-property', 'Enable'), 'Enable', 'off');
    set(findall(handles.exp_uipanel, '-property', 'Enable'), 'Enable', 'off');
    set(findall(handles.run_uipanel, '-property', 'Enable'), 'Enable', 'off');

    if isfield(expmt.hardware.cam,'vid') && isvalid(expmt.hardware.cam.vid)
        handles.auto_detect_ROIs_pushbutton.Enable = 'on';
        handles.accept_ROI_thresh_pushbutton.Enable = 'on';
        handles.ROI_thresh_slider.Enable = 'on';
        handles.ROI_thresh_label.Enable = 'on';
        handles.disp_ROI_thresh.Enable = 'on';
    end

elseif keep_gui_state

    % restore gui to prior state
    set(handles.on_objs(isvalid(handles.on_objs)),'Enable','on');
    set(handles.off_objs(isvalid(handles.off_objs)),'Enable','off');   
end
    
% reset initialization
expmt.meta.initialize = true;
expmt.meta.finish = true;

% ensure all open files are closed
fIDs = fopen('all');
for i=1:length(fIDs)
    fclose(fIDs(i));
end
        
% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);


% --- Executes on slider movement.
function ROI_thresh_slider_Callback(hObject, ~, handles)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

expmt.parameters.ROI_thresh = get(handles.ROI_thresh_slider,'Value');
set(handles.disp_ROI_thresh,'string',num2str(round(expmt.parameters.ROI_thresh)));

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function ROI_thresh_slider_CreateFcn(hObject,~,~)
% hObject    handle to ROI_thresh_slider (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in accept_ROI_thresh_pushbutton.
function accept_ROI_thresh_pushbutton_Callback(hObject, ~, handles) %#ok<*DEFNU>
% hObject    handle to accept_ROI_thresh_pushbutton (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

set(handles.accept_ROI_thresh_pushbutton,'value',1);

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);
guidata(hObject,handles);



function edit_frame_rate_Callback(~, ~, ~)
% hObject    handle to edit_frame_rate (see GCBO)

% handles    structure with handles and user data (see GUIDATA)



% --- Executes during object creation, after setting all properties.
function edit_frame_rate_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_frame_rate (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in exp_select_popupmenu.
function exp_select_popupmenu_Callback(hObject, ~, handles)
% hObject    handle to exp_select_popupmenu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

if expmt.meta.exp_id ~= handles.exp_select_popupmenu.Value
    expmt.meta.exp_id = get(handles.exp_select_popupmenu,'Value');        % index of the experiment in exp list
    names = get(handles.exp_select_popupmenu,'string');             % name of the experiment
    expmt.meta.name = names{expmt.meta.exp_id};                                % store name in master struct
    expmt.parameters = trimParameters(expmt.parameters, handles);   % remove all experiment specific parameters
end

% Enable Experiment Parameters pushbutton if expID has an associated subgui
if any(strcmp(expmt.meta.name,handles.parameter_subgui))
    handles.exp_parameter_pushbutton.Enable = 'on';
else
    handles.exp_parameter_pushbutton.Enable = 'off';
end

% if experiment parameters are set, Enable experiment run panel
% if experiment parameters are set, Enable experiment run panel
if expmt.meta.exp_id > 1 && ~isempty(handles.save_path.String)
    set(findall(handles.run_uipanel, '-property', 'Enable'),'Enable','on');
    eb = findall(handles.run_uipanel, 'Style', 'edit');
    set(eb,'Enable','inactive','BackgroundColor',[.87 .87 .87]);
end

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);
guidata(hObject,handles);

% Hints: contents = cellstr(get(hObject,'String')) returns exp_select_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from exp_select_popupmenu


% --- Executes during object creation, after setting all properties.
function exp_select_popupmenu_CreateFcn(hObject, ~, ~)
% hObject    handle to exp_select_popupmenu (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_time_remaining_Callback(~, ~, ~)
% hObject    handle to edit_time_remaining (see GCBO)

% handles    structure with handles and user data (see GUIDATA)




% --- Executes during object creation, after setting all properties.
function edit_time_remaining_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_time_remaining (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in exp_parameter_pushbutton.
function exp_parameter_pushbutton_Callback(hObject, ~, handles)
% hObject    handle to exp_parameter_pushbutton (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

if expmt.meta.exp_id<2
    errordlg('Please select an experiment first')
else
    switch expmt.meta.name

        case 'Optomotor'
            
                tmp_param = optomotor_parameter_gui(expmt);
                if ~isempty(tmp_param)
                    expmt = tmp_param;
                    expmt.parameters.initialized = true;
                end

             
        case 'Slow Phototaxis'                     

                tmp_param = slowphototaxis_parameter_gui(expmt);
                if ~isempty(tmp_param)
                    expmt = tmp_param;
                    expmt.parameters.initialized = true;
                end
                
        case 'Circadian'
            
                tmp_param = circadian_parameter_subgui(expmt,handles);
                if ~isempty(tmp_param)
                    expmt.parameters = tmp_param;
                    expmt.parameters.initialized = true;
                end
                
        case 'Arena Blocks'
            
                % arena block expmt parameters
                tmp_param = arenablock_parameter_gui(expmt);
                if ~isempty(tmp_param)
                    expmt = tmp_param;
                    expmt.parameters.initialized = true;
                 
                
                    % also query optomotor and slowphototaxis parameters
                    % if those experiments are selected as well

                    if isfield(expmt,'block') && any(strcmp(expmt.block.fields,'Optomotor'))
                        tmp_param = optomotor_parameter_gui(expmt);
                        if ~isempty(tmp_param)
                            expmt.opto_parameters = tmp_param.parameters;
                            expmt.parameters.initialized = true;
                        end  
                    end

                    if isfield(expmt,'block') && any(strcmp(expmt.block.fields,'Slow Phototaxis'))
                        tmp_param = slowphototaxis_parameter_gui(expmt);
                        if ~isempty(tmp_param)
                            expmt.photo_parameters = tmp_param.parameters;
                            expmt.parameters.initialized = true;
                        end
                    end
                
                end

            case 'Temporal Phototaxis'                  

            tmp_param = slowphototaxis_parameter_gui(expmt);
            if ~isempty(tmp_param)
                expmt = tmp_param;
                expmt.parameters.initialized = true;
            end
    end
    
    
end



% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);



% --- Executes on button press in refresh_COM_pushbutton.
function refresh_COM_pushbutton_Callback(hObject, ~, handles)
% hObject    handle to refresh_COM_pushbutton (see GCBO)

% handles    structure with handles and user data (see GUIDATA)
% Refresh items on the COM ports

refresh_COM_menu_Callback(handles.refresh_COM_menu,[],handles);



% --- Executes on button press in enter_labels_pushbutton.
function enter_labels_pushbutton_Callback(hObject, ~, handles)
% hObject    handle to enter_labels_pushbutton (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');


tmp_lbl = label_subgui(expmt);
if ~isempty(tmp_lbl)
    iString = cellfun('isclass',tmp_lbl,'char');
    numeric = false(size(iString));
    hasData = any(~cellfun('isempty',tmp_lbl),2);
    numeric(hasData,4:8) = true;
    convert = numeric & iString;
    for i = 1:size(convert,1)
        for j = 1:size(convert,2)
            if convert(i,j)
                tmp_lbl(i,j) = {str2double(tmp_lbl{i,j})};
            end
        end
    end
    expmt.meta.labels = tmp_lbl;
end



% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);



% --- Executes on slider movement.
function track_thresh_slider_Callback(hObject, ~, handles)
% hObject    handle to track_thresh_slider (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

expmt.parameters.track_thresh = get(handles.track_thresh_slider,'Value');
set(handles.disp_track_thresh,'string',num2str(round(expmt.parameters.track_thresh)));

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);


guidata(hObject,handles);




% --- Executes during object creation, after setting all properties.
function track_thresh_slider_CreateFcn(hObject, ~, ~)
% hObject    handle to track_thresh_slider (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in accept_track_thresh_pushbutton.
function accept_track_thresh_pushbutton_Callback(hObject, ~, handles)
% hObject    handle to accept_track_thresh_pushbutton (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

set(handles.accept_track_thresh_pushbutton,'value',1);

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);



function edit_numObj_Callback(~, ~, ~)
% hObject    handle to edit_numObj (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_numObj as text
%        str2double(get(hObject,'String')) returns contents of edit_numObj as a double


% --- Executes during object creation, after setting all properties.
function edit_numObj_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_numObj (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_object_num_Callback(~, ~, ~)
% hObject    handle to edit_object_num (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_object_num as text
%        str2double(get(hObject,'String')) returns contents of edit_object_num as a double


% --- Executes during object creation, after setting all properties.
function edit_object_num_CreateFcn(hObject, ~, ~)
% hObject    handle to edit_object_num (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in reg_test_pushbutton.
function reg_test_pushbutton_Callback(~, ~, ~)
% hObject    handle to reg_test_pushbutton (see GCBO)

% handles    structure with handles and user data (see GUIDATA)



% --- Executes on selection change in param_prof_popupmenu.
function param_prof_popupmenu_Callback(hObject, ~, handles)
% hObject    handle to param_prof_popupmenu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

if get(handles.param_prof_popupmenu,'value') ~= 1
    profiles = get(handles.param_prof_popupmenu,'string');
    profile = profiles(get(handles.param_prof_popupmenu,'value'));
    expmt = loadSavedParameters(handles,profile{:});
end

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);
guidata(hObject,handles);






% --- Executes during object creation, after setting all properties.
function param_prof_popupmenu_CreateFcn(hObject,~,~)
% hObject    handle to param_prof_popupmenu (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% Get existing profile list
gui_dir = which('autotrackergui');
gui_dir = gui_dir(1:strfind(gui_dir,'/gui/'));
load_path =[gui_dir 'profiles/'];
tmp_profiles = ls(load_path);
profiles = cell(size(tmp_profiles,1)+1,1);
profiles(1) = {'Select saved settings'};
remove = [];

for i = 1:size(profiles,1)-1;
    k = strfind(tmp_profiles(i,:),'.mat');
    if isempty(k)
        remove = [remove i+1];
    else
        profiles(i+1) = {tmp_profiles(i,1:k-1)};
    end
end

profiles(remove)=[];
if size(profiles,1) > 1
    set(hObject,'string',profiles);
else
    set(hObject,'string',{'No profiles detected'});
end


% --- Executes on button press in save_params_pushbutton.
function save_params_pushbutton_Callback(hObject, ~, handles)
% hObject    handle to save_params_pushbutton (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');  %#ok<NASGU>

% set profile save path
save_path = [handles.gui_dir 'profiles/'];

[FileName,PathName] = uiputfile('*.mat','Enter name for new profile',save_path);

if any(FileName)
    replace = exist(strcat(PathName,FileName),'file')==2;
    save(strcat(PathName,FileName),'expmt');

    if replace
        profile_name = FileName(1:strfind(FileName,'.mat')-1);
        profiles = get(handles.param_prof_popupmenu,'string');
        
        for i = 1:length(profiles)
            if strcmp(profile_name,profiles{i});
                ri = i;
            end
        end
        
        profiles(ri) = {profile_name};
        set(handles.param_prof_popupmenu,'string',profiles);
        set(handles.param_prof_popupmenu,'value',ri);
        
    else
        profile_name = FileName(1:strfind(FileName,'.mat')-1);
        profiles = get(handles.param_prof_popupmenu,'string');
        profiles(1) = {'Select saved settings'};
        profiles(size(profiles,1)+1) = {profile_name};
        set(handles.param_prof_popupmenu,'string',profiles);
        set(handles.param_prof_popupmenu,'value',size(profiles,1));
    end
end


% --- Executes during object deletion, before destroying properties.
function ROI_thresh_slider_DeleteFcn(~,~,~)
% hObject    handle to ROI_thresh_slider (see GCBO)

% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in reference_pushbutton.
function reference_pushbutton_Callback(hObject, ~, handles)
% hObject    handle to reference_pushbutton (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% import expmteriment variables
expmt = getappdata(handles.gui_fig,'expmt');

if isfield(expmt.meta.roi,'n') && expmt.meta.roi.n
    try
        toggleMenus(handles, 'off');
        expmt.meta.initialize = false;
        expmt = initializeRef(handles,expmt);
        handles.sample_noise_pushbutton.Enable = 'on';
    catch
        toggleMenus(handles, 'on');
    end
    expmt.meta.initialize = true;
else
    errordlg('Either ROI detection has not been run or no ROIs were detected.')
end

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);
guidata(hObject,handles);




% --- Executes on button press in sample_noise_pushbutton.
function sample_noise_pushbutton_Callback(hObject, ~, handles)
% hObject    handle to sample_noise_pushbutton (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% import expmteriment variables
expmt = getappdata(handles.gui_fig,'expmt');
if ~isfield(expmt.meta.ref,'im')
    errordlg('Reference image required to sample tracking noise')
    return
end

try   
    expmt.meta.initialize = false;
    toggleMenus(handles, 'off');
    expmt = sampleNoise(handles,expmt);

    % Enable downstream controls
    handles.exp_uipanel.ForegroundColor = [0 0 0];
    state = handles.exp_parameter_pushbutton.Enable;
    ctls = findall(handles.exp_uipanel, '-property', 'Enable'); 
    set(ctls, 'Enable', 'on');
    handles.exp_parameter_pushbutton.Enable = state;

    % if experiment parameters are set, Enable experiment run panel
    if expmt.meta.exp_id > 1
        if ~isempty(handles.save_path.String)

            set(findall(handles.run_uipanel, ...
                '-property', 'Enable'),'Enable','on');
        end
        if any(strcmp(expmt.meta.name,handles.parameter_subgui))
            handles.exp_parameter_pushbutton.Enable = 'on';
        end
    end

catch
    toggleMenus(handles, 'on');
end
expmt.meta.initialize = true;


% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);
guidata(hObject,handles);


% --- Executes on button press in auto_detect_ROIs_pushbutton.
function auto_detect_ROIs_pushbutton_Callback(hObject, ~, handles)
% hObject    handle to auto_detect_ROIs_pushbutton (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% import expmteriment variables
expmt = getappdata(handles.gui_fig,'expmt');

% check for valid source
switch expmt.meta.source
    case 'camera'
        if ~isfield(expmt.hardware.cam,'vid')
            errordlg(['Confirm camera and camera settings'...
                'before running ROI detection']);
            return
        end
    case 'video'
        if ~isfield(expmt.meta,'video') || ...
                ~isfield(expmt.meta.video,'vid')
            
                errordlg(['Select valid video path before'...
                    'running ROI detection']);
            return
        end
end


% run ROI detection
try 
    
    expmt.meta.initialize = false;
    toggleMenus(handles, 'off');
    
    switch expmt.parameters.roi_mode

        case 'auto'   
        % run automatic ROI detections
        expmt.meta.roi.mode = 'auto';
        expmt = autoROIs(handles,expmt);
    
        case 'grid'    
        expmt.meta.roi.mode = 'grid';
        expmt = gridROIs(handles,expmt);     
            
    end
    
    % Enable downstream ui controls
    handles.track_thresh_slider.Enable = 'on';
    handles.accept_track_thresh_pushbutton.Enable = 'on';
    handles.reference_pushbutton.Enable = 'on';
    handles.track_thresh_label.Enable = 'on';
    handles.disp_track_thresh.Enable = 'on';
    handles.man_edit_roi_menu.Enable = 'on';
    
    % query the Enable states of objects in the gui
    on_objs = findobj('Enable','on');

    % disable all gui controls
    set(findall(handles.gui_fig, '-property', 'Enable'), 'Enable', 'off');
    handles.disp_note.Enable='on';
    gui_notify('initializing ROI masks, may take a few moments',handles.disp_note);
    drawnow
   
    % get an pixel mask for all areas of the image with an ROI
    if isfield(expmt.meta.roi,'centers')
        expmt.meta.roi.n = size(expmt.meta.roi.centers,1);
        expmt = setROImask(expmt);
    end
    
    % re-enable controls
    set(on_objs, 'Enable', 'on');
    
catch ME
    toggleMenus(handles, 'on');
    hObject.Enable = 'on';
    msg=getReport(ME,'extended');
    errordlg(msg);
end

% Store expmteriment data struct
expmt.meta.intialize = true;
setappdata(handles.gui_fig,'expmt',expmt);
guidata(hObject,handles);




% ***************** Menu Items ******************** %




% --------------------------------------------------------------------
function hardware_props_menu_Callback(~,~,~)
% hObject    handle to hardware_props_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function display_menu_Callback(~,~,~)
% hObject    handle to display_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function cam_settings_menu_Callback(hObject, ~, handles)
% hObject    handle to cam_settings_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% import expmteriment variables
expmt = getappdata(handles.gui_fig,'expmt');

% run camera settings gui
expmt = cam_settings_subgui(handles,expmt);

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);
guidata(hObject,handles);




% --------------------------------------------------------------------
function proj_settings_menu_Callback(~,~,~)
% hObject    handle to proj_settings_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function file_menu_Callback(~,~,~)
% hObject    handle to file_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)




% --------------------------------------------------------------------
function display_difference_menu_Callback(hObject, ~, handles)
% hObject    handle to display_difference_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

chk = get(hObject,'checked');

if strcmp(chk,'off')
    handles.display_menu.UserData = 2;
    set(handles.display_difference_menu,'checked','on');
    set(handles.display_raw_menu,'checked','off');
    set(handles.display_threshold_menu,'checked','off');
    set(handles.display_reference_menu,'checked','off');
    set(handles.display_none_menu,'checked','off');
end

guidata(hObject,handles);


% --------------------------------------------------------------------
function display_raw_menu_Callback(hObject, ~, handles)
% hObject    handle to display_raw_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

chk = get(hObject,'checked');

if strcmp(chk,'off')
    handles.display_menu.UserData = 1;
    set(handles.display_difference_menu,'checked','off');
    set(handles.display_raw_menu,'checked','on');
    set(handles.display_threshold_menu,'checked','off');
    set(handles.display_reference_menu,'checked','off');
    set(handles.display_none_menu,'checked','off');
end

guidata(hObject,handles);


% --------------------------------------------------------------------
function display_threshold_menu_Callback(hObject, ~, handles)
% hObject    handle to display_threshold_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

chk = get(hObject,'checked');

if strcmp(chk,'off')
    handles.display_menu.UserData = 3;
    set(handles.display_difference_menu,'checked','off');
    set(handles.display_raw_menu,'checked','off');
    set(handles.display_threshold_menu,'checked','on');
    set(handles.display_reference_menu,'checked','off');
    set(handles.display_none_menu,'checked','off');
end

guidata(hObject,handles);

% --------------------------------------------------------------------
function display_reference_menu_Callback(hObject, ~, handles)
% hObject    handle to display_reference_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

chk = get(hObject,'checked');

if strcmp(chk,'off')
    handles.display_menu.UserData = 4;
    set(handles.display_difference_menu,'checked','off');
    set(handles.display_raw_menu,'checked','off');
    set(handles.display_threshold_menu,'checked','off');
    set(handles.display_reference_menu,'checked','on');
    set(handles.display_none_menu,'checked','off');
end

guidata(hObject,handles);


% --------------------------------------------------------------------
function display_none_menu_Callback(hObject, ~, handles)
% hObject    handle to display_none_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

chk = get(hObject,'checked');

if strcmp(chk,'off')
    handles.display_menu.UserData = 5;
    set(handles.display_difference_menu,'checked','off');
    set(handles.display_raw_menu,'checked','off');
    set(handles.display_threshold_menu,'checked','off');
    set(handles.display_reference_menu,'checked','off');
    set(handles.display_none_menu,'checked','on');
end

guidata(hObject,handles);


% --------------------------------------------------------------------
function reg_proj_menu_Callback(hObject, ~, handles)
% hObject    handle to reg_proj_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

expmt = getappdata(handles.gui_fig,'expmt');

if ~isfield(expmt,'reg_params')
    tmp = registration_parameter_subgui(expmt);
    if ~isempty(tmp)
        expmt.reg_params = tmp;
    end
end

if isfield(expmt,'reg_params')
    % Turn infrared and white background illumination off during registration
    writeInfraredWhitePanel(expmt.hardware.COM.light,1,0);
    writeInfraredWhitePanel(expmt.hardware.COM.light,0,0);

    msg_title = ['Projector Registration Tips'];
    spc = [' '];
    intro = ['Please check the following before continuing'...
        'to ensure successful registration:'];
    item1 = ['1.) Both the infrared and white lights for'...
        'imaging illumination are set to OFF. '...
        'Make sure the projector is the only light source'...
        'visible to the camera'];
    item2 = ['2.) Camera is not imaging through infrared filter. '...
        'Projector display should be visible through the camera.'];
    item3 = ['3.) Projector is connected to the computer, turned'...
        'on and set to desired resolution.'];
    item4 = ['4.) Camera shutter speed is adjusted to match the'...
        'refresh rate of the projector.'...
        ' This will appear as moving streaks in the camera if'...
        'not properly adjusted.'];
    item5 = ['5.) Both camera and projector are in fixed positions and'...
        'will not need to be adjusted after registration.'];
    item6 = ['6.) The projector is set as the most external display'...
        '(ie. the highest number display). Hint: this is the most'...
        'likely problem if the projector is connected but psych'...
        'Toolbox is drawing to the primary display. MATLAB must be'...
        'restarted before this change will take effect.'];
    closing = ['Click OK to continue with the registration'];
    message = {intro spc item1 spc item2 spc ...
        item3 spc item4 spc item5 spc item6 spc closing};

    % Display registration tips
    waitfor(msgbox(message,msg_title));

    % Register projector
    reg_projector(expmt,handles);

    % Reset infrared and white lights to prior values
    writeInfraredWhitePanel(expmt.hardware.COM.light,1,...
        expmt.hardware.light.infrared);
    writeInfraredWhitePanel(expmt.hardware.COM.light,0,...
        expmt.hardware.light.white);

else
    errordlg('Please set registration parameters before running registration');
end


guidata(hObject, handles);


% --------------------------------------------------------------------
function reg_params_menu_Callback(hObject, ~, handles)


% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

if isfield(expmt,'reg_params')
    tmp = registration_parameter_subgui(expmt);
    if ~isempty(tmp)
        expmt.reg_params = tmp;
    end
else
        tmp = registration_parameter_subgui();
    if ~isempty(tmp)
        expmt.reg_params = tmp;
    end
end

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);


% --------------------------------------------------------------------
function reg_error_menu_Callback(hObject, ~, handles)
% hObject    handle to reg_error_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

expmt = getappdata(handles.gui_fig,'expmt');

if exist([handles.gui_dir 'hardware/projector_fit/']) == 7 && isfield(expmt,'reg_params')
    
    % Turn infrared and white background illumination off during registration
    expmt.hardware.COM.light = writeInfraredWhitePanel(expmt.hardware.COM.light,1,0);
    expmt.hardware.COM.light = writeInfraredWhitePanel(expmt.hardware.COM.light,0,0);

    msg_title = ['Registration Error Measurment']; %#ok<*NBRAK>
    spc = [' '];
    intro = ['Please check the following before continuing to ensure successful registration:'];
    item1 = ['1.) Both the infrared and white lights for imaging illumination are set to OFF. '...
        'Make sure the projector is the only light source visible to the camera'];
    item2 = ['2.) Camera is not imaging through infrared filter. '...
        'Projector display should be visible through the camera.'];
    item3 = ['3.) Projector is connected to the computer, turned on and set to desired resolution.'];
    item4 = ['4.) Camera shutter speed is adjusted to match the refresh rate of the projector.'...
        ' This will appear as moving streaks in the camera if not properly adjusted.'];
    item5 = ['5.) Both camera and projector are in fixed positions and will not need to be adjusted'...
        ' after registration.'];
    item6 = ['6.) The projector is set as the most external display (ie. the highest number display). Hint: '...
        'this is the most likely problem if the projector is connected but psych Toolbox is drawing to '...
        'the primary display. MATLAB must be restarted before this change will take effect.'];
    closing = ['Click OK to continue with the registration'];
    message = {intro spc item1 spc item2 spc item3 spc item4 spc item5 spc item6 spc closing};

    % Display registration tips
    waitfor(msgbox(message,msg_title));

    % Register projector
    projector_testFit(expmt,handles);

    % Reset infrared and white lights to prior values
    expmt.hardware.COM.light = writeInfraredWhitePanel(expmt.hardware.COM.light,1,expmt.hardware.light.infrared);
    expmt.hardware.COM.light = writeInfraredWhitePanel(expmt.hardware.COM.light,0,expmt.hardware.light.white);
else
    errordlg('Set registration parameters and run projector registration before measuring registration error.');
end

guidata(hObject, handles);



% --------------------------------------------------------------------
function tracking_menu_Callback(~,~,~)
% hObject    handle to tracking_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function advanced_tracking_menu_Callback(hObject, ~, handles)
% hObject    handle to advanced_tracking_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

advancedTrackingParam_subgui(expmt,handles);

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);




% --------------------------------------------------------------------
function distance_scale_menu_Callback(hObject, ~, handles)
% hObject    handle to distance_scale_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

% grab a frame if a camera or video object exists
if (isfield(expmt.hardware.cam,'vid') && strcmp(expmt.hardware.cam.vid.Running,'on')) ||...
    isfield(expmt.meta.video,'vid')

    % query next frame and optionally correct lens distortion
    trackDat = [];
    [trackDat,expmt] = autoFrame(trackDat,expmt,handles);
    
elseif (isfield(expmt.hardware.cam,'vid') && strcmp(expmt.hardware.cam.vid.Running,'off'))

    % restart camera
    start(expmt.hardware.cam.vid);
    
    % query next frame and optionally correct lens distortion
    trackDat = [];
    [trackDat,expmt] = autoFrame(trackDat,expmt,handles); 
    
end

tmp=setDistanceScale_subgui(handles,expmt.parameters);
delete(findobj('Tag','imline'));
if ~isempty(tmp)
    expmt.parameters.distance_scale = tmp;
    
    % update speed, distance, and area thresholds
    expmt.parameters.speed_thresh =...
        expmt.parameters.speed_thresh .* tmp.mm_per_pixel ./ expmt.parameters.mm_per_pix;
    expmt.parameters.distance_thresh =...
        expmt.parameters.distance_thresh .* tmp.mm_per_pixel ./ expmt.parameters.mm_per_pix;
    expmt.parameters.area_min =...
        expmt.parameters.area_min .* ((tmp.mm_per_pixel./expmt.parameters.mm_per_pix)^2);
    expmt.parameters.area_max =...
        expmt.parameters.area_max .* ((tmp.mm_per_pixel./expmt.parameters.mm_per_pix)^2);
    
    % set new parameter
    expmt.parameters.mm_per_pix = tmp.mm_per_pixel;
    
    if expmt.parameters.mm_per_pix ~= 1
        expmt.parameters.units = 'millimeters';
    end
end

% Store expmteriment data struct
setappdata(handles.gui_fig,'expmt',expmt);


% --------------------------------------------------------------------
function Untitled_4_Callback(~,~,~)
% hObject    handle to Untitled_4 (see GCBO)

% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function speed_thresh_menu_Callback(~,~,~)
% hObject    handle to speed_thresh_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function ROI_distance_thresh_menu_Callback(~,~,~)
% hObject    handle to ROI_distance_thresh_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Untitled_7_Callback(~,~,~)
% hObject    handle to Untitled_7 (see GCBO)

% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Untitled_8_Callback(~,~,~)
% hObject    handle to Untitled_8 (see GCBO)

% handles    structure with handles and user data (see GUIDATA)


% --- Executes when gui_fig is resized.
function gui_fig_SizeChangedFcn(hObject, ~, handles)
% hObject    handle to gui_fig (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% calculate delta width and height
if isfield(handles,'fig_size')
    
    dh = handles.fig_size(4) - hObject.Position(4);

    % adjust panel position to be constant
    panels = findobj(handles.gui_fig.Children,'Type','uipanel');
    for i = 1:length(panels)
        panels(i).Position(2) = panels(i).UserData(2) - dh;
    end

    handles.bottom_uipanel.Position(2) = handles.bottom_uipanel.UserData(2);
    handles.disp_note.Position(2) = handles.disp_note.UserData(2);
    if handles.bottom_uipanel.UserData(4) - dh > 0
        handles.bottom_uipanel.Position(4) = handles.bottom_uipanel.UserData(4) - dh;
    else
        handles.bottom_uipanel.Position(4) = 0;
    end
    if handles.disp_note.UserData(4) - dh > 0
            handles.disp_note.Position(4) = handles.disp_note.UserData(4) - dh;
    end
    
    handles.hImage = findobj(handles.axes_handle,'-depth',3,'Type','Image');
    if ~isempty(handles.hImage)

        handles.axes_handle.Position(3) = handles.gui_fig.Position(3) - handles.axes_handle.Position(1) - 10;
        handles.axes_handle.Position(2) = handles.bottom_uipanel.Position(2);
        handles.axes_handle.Position(4) = handles.gui_fig.Position(4) - handles.axes_handle.Position(2) - 5;

        res = size(handles.hImage.CData);
        if length(res)>2
            res(3) = [];
        end
        res = fliplr(res);
        aspectR = res(2)/res(1);
        plot_aspect = pbaspect(handles.axes_handle);
        pbr = plot_aspect(2)/plot_aspect(1);
        fscale = aspectR/pbr;
        
        axes_height_old = handles.axes_handle.Position(4);
        axes_height_new = axes_height_old*fscale;
        


        if axes_height_new + 10 > handles.gui_fig.Position(4)
     
            aspectR = res(1)/res(2);
            plot_aspect = pbaspect(handles.axes_handle);
            plot_aspect = plot_aspect./plot_aspect(2);
            fscale = aspectR/plot_aspect(1);
            axes_width_old = handles.axes_handle.Position(3);
            axes_width_new = axes_width_old*fscale;
            handles.axes_handle.Position(3) = axes_width_new;
            %pbaspect([aspectR,1,1]);
            
        else
            
            handles.axes_handle.Position(4) = axes_height_new;
            handles.axes_handle.Position(2) = handles.axes_handle.Position(2) + axes_height_old - axes_height_new;   
            
        end
        
        handles.axes_handle.XTick = [];
        handles.axes_handle.YTick = [];     
    end

end

guidata(hObject,handles);


% --------------------------------------------------------------------
function load_video_menu_Callback(~,~,~)
% hObject    handle to load_video_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function saved_presets_menu_Callback(~,~,~)
% hObject    handle to saved_presets_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in vid_preview_togglebutton.
function vid_preview_togglebutton_Callback(hObject, ~, handles)
% hObject    handle to vid_preview_togglebutton (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% update button appearance
if hObject.Value
    hObject.String = 'Stop Preview';
    hObject.BackgroundColor = [0.85 0.65 0.65];
else
    hObject.String = 'Start Preview';
    hObject.BackgroundColor = [0.94 0.94 0.94];
end

% get expmt data struct
expmt = getappdata(handles.gui_fig,'expmt');

if isfield(expmt.meta.video,'vid')
    
    % initialize axes and image settings
    if hObject.Value
        
        % adjust aspect ratio of plot to match camera
        colormap('gray');
        if isfield(expmt.meta.video,'fID')
            vh = expmt.meta.video.res(1);
            vw = expmt.meta.video.res(2);
        else
            vh = expmt.meta.video.vid.Height;
            vw = expmt.meta.video.vid.Width;
        end
        im = uint8(zeros(vh,vw));
        handles.hImage = image(im,'Parent',handles.axes_handle);
        gui_fig_SizeChangedFcn(handles.gui_fig,[],handles);
        handles.hImage.CDataMapping = 'scaled';
        drawnow
        
    end
        
    % stream frames to the axes until the preview button is unticked
    ct=0;
    while hObject.Value
        
        tic
        ct = ct+1;
        
        % get next frame and update image
        [im, expmt.meta.video] = nextFrame(expmt.meta.video,handles);
        if size(im,3)>1
            im=im(:,:,2);
        end
        handles.hImage.CData = im; 
        
        % clear image and draw to screen
        clearvars im
        drawnow
        
        % update frame rate and frames remaining
        handles.edit_frame_rate.String = num2str(round(1/toc*10)/10);
        handles.edit_time_remaining.String = num2str(expmt.meta.video.nFrames - ct);
 
    end
    

    
else
    errordlg('No video file path specified')
    hObject.String = 'Start Preview';
    hObject.BackgroundColor = [0.94 0.94 0.94];
    hObject.Value = 0;
end


% --- Executes on button press in pushbutton23.
function pushbutton23_Callback(~,~,~)
% hObject    handle to pushbutton23 (see GCBO)

% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in vid_select_popupmenu.
function vid_select_popupmenu_Callback(hObject, ~, handles)
% hObject    handle to vid_select_popupmenu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% get expmt data struct
expmt = getappdata(handles.gui_fig,'expmt');

% update current video object
expmt.meta.video.vid = ...
    VideoReader([expmt.meta.video.fdir expmt.meta.video.fnames{hObject.Value}]);

% set expmt data struct
setappdata(handles.gui_fig,'expmt',expmt);



% Hints: contents = cellstr(get(hObject,'String')) returns vid_select_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from vid_select_popupmenu


% --- Executes during object creation, after setting all properties.
function vid_select_popupmenu_CreateFcn(hObject,~,~)
% hObject    handle to vid_select_popupmenu (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_video_dir_Callback(~,~,~)
% hObject    handle to edit_video_dir (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_video_dir as text
%        str2double(get(hObject,'String')) returns contents of edit_video_dir as a double


% --- Executes during object creation, after setting all properties.
function edit_video_dir_CreateFcn(hObject,~,~)
% hObject    handle to edit_video_dir (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in video_files_pushbutton.
function video_files_pushbutton_Callback(hObject, ~, handles)
% hObject    handle to video_files_pushbutton (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% get expmt data struct
expmt = getappdata(handles.gui_fig,'expmt');

% get video files from file browser
tmp_video = uigetvids(expmt);

% update gui with video info
if ~isempty(tmp_video)
    
    % update video panel UI and image handles
    expmt.meta.video = tmp_video;
    expmt = guiInitializeVideo(expmt, handles);
    gui_fig_SizeChangedFcn(handles.gui_fig, [], handles);
    
end

% set expmt data struct
setappdata(handles.gui_fig,'expmt',expmt);


% --------------------------------------------------------------------
function select_source_menu_Callback(~,~,~)
% hObject    handle to select_source_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function source_camera_menu_Callback(hObject, ~, handles)
% hObject    handle to source_camera_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% get expmt data struct
expmt = getappdata(handles.gui_fig,'expmt');

% update gui controls
if strcmp(expmt.meta.source,'video')
    % disable all panels except cam/video and lighting
    handles.exp_uipanel.ForegroundColor = [.5   .5  .5];
    set(findall(handles.exp_uipanel, '-property', 'Enable'), 'Enable', 'off');
    handles.tracking_uipanel.ForegroundColor = [.5   .5  .5];
    set(findall(handles.tracking_uipanel, '-property', 'Enable'), 'Enable', 'off');
    handles.run_uipanel.ForegroundColor = [.5   .5  .5];
    set(findall(handles.run_uipanel, '-property', 'Enable'), 'Enable', 'off');
    handles.time_remaining_text.String = 'time remaining';
    handles.edit_time_remaining.String = '00:00:00';
    handles.vignette_correction_menu.Enable = 'off';
    handles.distance_scale_menu.Enable = 'off';
end

if strcmp(handles.cam_uipanel.Visible,'off')
    handles.cam_uipanel.Visible = 'on';
end

if strcmp(handles.vid_uipanel.Visible,'on')
    handles.vid_uipanel.Visible = 'off';
    handles.edit_video_dir.String = '';
    handles.vid_select_popupmenu.String = 'No video files loaded';
end

% remove video object
if isfield(expmt.meta.video,'vid')
    expmt = rmfield(expmt.meta,'video');
    gui_notify('source switched to camera',handles.disp_note);
end

% set source
expmt.meta.source = 'camera';

% set expmt data struct
setappdata(handles.gui_fig,'expmt',expmt);




% --------------------------------------------------------------------
function source_video_menu_Callback(hObject, ~, handles)
% hObject    handle to source_video_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% get expmt data struct
expmt = getappdata(handles.gui_fig,'expmt');

if strcmp(expmt.meta.source,'camera')
    % disable all panels except cam/video and lighting
    handles.exp_uipanel.ForegroundColor = [.5   .5  .5];
    set(findall(handles.exp_uipanel, '-property', 'Enable'), 'Enable', 'off');
    handles.tracking_uipanel.ForegroundColor = [.5   .5  .5];
    set(findall(handles.tracking_uipanel, '-property', 'Enable'), 'Enable', 'off');
    handles.run_uipanel.ForegroundColor = [.5   .5  .5];
    set(findall(handles.run_uipanel, '-property', 'Enable'), 'Enable', 'off');
    handles.time_remaining_text.String = 'frames remaining';
    handles.edit_time_remaining.String = '-';
    handles.vignette_correction_menu.Enable = 'off';
    handles.distance_scale_menu.Enable = 'off';
    handles.vid_select_popupmenu.Enable = 'off';
    handles.vid_preview_togglebutton.Enable = 'off';
    handles.select_video_label.Enable = 'off';
    
    if isfield(expmt.meta,'video') && isfield(expmt.meta.video,'vid')
        handles.ROI_thresh_slider.Enable = 'on';
        handles.accept_ROI_thresh_pushbutton.Enable = 'on';
        handles.disp_ROI_thresh.Enable = 'on';
        handles.auto_detect_ROIs_pushbutton.Enable = 'on';
        handles.text_object_num.Enable = 'on';
        handles.edit_object_num.Enable = 'on';
    end      
end

if strcmp(handles.vid_uipanel.Visible,'off')
    handles.vid_uipanel.Visible = 'on';
    handles.vid_uipanel.Position = handles.cam_uipanel.Position;
end

if strcmp(handles.cam_uipanel.Visible,'on')
    handles.cam_uipanel.Visible = 'off';
end

% remove camera object
if isfield(expmt.hardware.cam,'vid') || isfield(expmt.hardware.cam,'src')
    expmt.hardware.cam = rmfield(expmt.hardware.cam,'vid');
    expmt.hardware.cam = rmfield(expmt.hardware.cam,'src');
    gui_notify('source switched to video - deactivating camera',...
        handles.disp_note);
end

% set source
expmt.meta.source = 'video';

% set expmt data struct
setappdata(handles.gui_fig,'expmt',expmt);



% --------------------------------------------------------------------
function vignette_correction_menu_Callback(hObject, ~, handles)

expmt = getappdata(handles.gui_fig,'expmt');        % get expmt data struct
clean_gui(handles.axes_handle);                     % clear drawn objects
vid = true;

% Setup the camera and/or video object
if strcmp(expmt.meta.source,'camera') && strcmp(expmt.hardware.cam.vid.Running,'off')
    
    % Clear old video objects
    imaqreset
    pause(0.2);

    % Create camera object with input parameters
    expmt.hardware.cam = initializeCamera(expmt.hardware.cam);
    start(expmt.hardware.cam.vid);
    pause(0.1);
    
elseif strcmp(expmt.meta.source,'video') 
    
    % open video object from file
    expmt.meta.video.vid = ...
        VideoReader([expmt.meta.video.fdir ...
            expmt.meta.video.fnames{handles.vid_select_popupmenu.Value}]);
    
    expmt.meta.video.ct = handles.vid_select_popupmenu.Value;    % get file number in list

elseif ~strcmp(expmt.hardware.cam.vid.Running,'on')
    errordlg('Must confirm a camera or video source before correcting vignetting');
    vid = false;
end


if vid
    
    % Take single frame
    if strcmp(expmt.meta.source,'camera')
        im = peekdata(expmt.hardware.cam.vid,1);
    else
        [im, expmt.meta.video] = nextFrame(expmt.meta.video,handles);
    end
    
    % extract green channel if format is RGB
    if size(im,3)>1
        im = im(:,:,2);
    end
    
    % if an image already exists, display a preview of the vignette correction
    imh = findobj(handles.axes_handle,'-depth',3,'Type','image');
    imh.CData = im;
    
    % display instructions
    msg = ['Click and drag to draw a rectangle to select a dimly lit ROI or '...
        'region within an ROI. For best results, make sure the selection is '...
        'representative of the dimmest regions of the dimmest ROIs and '...
        'do not include additional ROIs in the selection.'];
    waitfor(msgbox(msg));

    % get ROI from the image
    roi = getrect(handles.axes_handle);
    roi(3) = roi(1) + roi(3);
    roi(4) = roi(2) + roi(4);
    roi = round(roi);
    
    % get adaptive threshold value using otsu's method
    thresh = graythresh(im(roi(2):roi(4),roi(1):roi(3)));
    tmpim = double(im);
    tmpim(tmpim<thresh*255) = NaN;
    expmt.meta.vignette.im =filterVignetting(expmt,roi,tmpim);
    expmt.meta.vignette.im = uint8(expmt.meta.vignette.im);
    expmt.meta.vignette.mode = 'manual';
    
    imh.CData = im - expmt.meta.vignette.im;
    imh.CDataMapping = 'scaled';
    handles.axes_handle.CLim = [0 255];
    gui_notify('previewing vignette correction image',handles.disp_note);
    text(handles.axes_handle.XLim(2)*0.01,handles.axes_handle.YLim(2)*0.01,...
        'Vignette Correction Preview','Color',[1 0 0]);
    drawnow limitrate
        
end

% set expmt data struct
setappdata(handles.gui_fig,'expmt',expmt);

guidata(hObject,handles);

function saved_preset_Callback(hObject, ~)


gui_fig = hObject.Parent.Parent.Parent;     % get gui handles
expmt_new = getappdata(gui_fig,'expmt');        % get expmt data struct
warning('off');
load(hObject.UserData.path);
warning('on');

% load new settings in from file
expmt = load_settings(expmt,expmt_new,hObject.UserData.gui_handles); %#ok<NODEF>

% save loaded settings to master struct
setappdata(gui_fig,'expmt',expmt);  

guidata(gui_fig,hObject.UserData.gui_handles);


% --------------------------------------------------------------------
function save_new_preset_menu_Callback(hObject, ~, handles)
% hObject    handle to save_new_preset_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

% import expmteriment data struct
expmt = getappdata(handles.gui_fig,'expmt');

if isfield(expmt.hardware.cam,'vid')
    cam_copy = expmt.hardware.cam;
    expmt.hardware.cam = rmfield(expmt.hardware.cam,'vid');
end

if isfield(expmt.hardware.cam,'src')
    expmt.hardware.cam = rmfield(expmt.hardware.cam,'src');
end

if isfield(expmt.meta,'video') && isfield(expmt.meta.video,'vid')
    vid_copy = expmt.meta.video;
    expmt.meta.video = rmfield(expmt.meta.video,'vid');
end

% set profile save path
save_path = [handles.gui_dir 'profiles/'];

[FileName,PathName] = uiputfile('*.mat','Enter name for new profile',save_path);

if any(FileName)
    
    replace = exist(strcat(PathName,FileName),'file')==2;
    save(strcat(PathName,FileName),'expmt');

    if ~replace
        
        profile_name = FileName(1:strfind(FileName,'.mat')-1);
        hMenu = findobj('Tag','saved_presets_menu');
        new_menu_item = uimenu(hMenu,'Label',profile_name,...
            'Callback',@saved_preset_Callback);
        new_menu_item.UserData.index = length(hMenu.Children)+1;
        new_menu_item.UserData.path = strcat(PathName,FileName);
        new_menu_item.UserData.gui_handles = handles;
        
    end
end

switch expmt.meta.source
    case 'camera'
        expmt.hardware.cam = cam_copy;
    case 'video'
        expmt.meta.video = vid_copy;
end


% --------------------------------------------------------------------
function aux_com_menu_Callback(~,~,~)
% hObject    handle to aux_com_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function refresh_COM_menu_Callback(hObject, ~, handles)

% load master data struct
expmt = getappdata(handles.gui_fig,'expmt');                    

% generate menu items for AUX COMs and config their callbacks
hParent = findobj('Tag','aux_com_menu');

% remove controls for existing list
del=[];
for i = 1:length(hParent.Children)
    if ~strcmp(hParent.Children(i).Label,'refresh list')
        del = [del i]; %#ok<*AGROW>
    end
end
delete(hParent.Children(del));

% re-initialize COM ports
[expmt, handles] = refreshCOM(expmt, handles);

% save loaded settings to master struct
setappdata(handles.gui_fig,'expmt',expmt);  
guidata(hObject,handles);


% --------------------------------------------------------------------
function refresh_cam_menu_Callback(hObject, ~, handles)

% display warning and ask user whether or not to reset cam
expmt = getappdata(handles.gui_fig,'expmt');
refresh = warningbox_subgui('title', 'Camera Reset');     
if strcmp(refresh,'OK')
    expmt.hardware.cam = refresh_cam_list(handles);          % reset cameras and refresh gui lists
end

% save loaded settings to master struct
setappdata(handles.gui_fig,'expmt',expmt);  


% --- Executes on button press in pause_togglebutton.
function pause_togglebutton_Callback(hObject,~,~)
% hObject    handle to pause_togglebutton (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

switch hObject.Value
    case 1
        hObject.BackgroundColor = [0.85 0.65 0.65];
    case 0
        hObject.BackgroundColor = [0.502 0.7529 0.8392];
end

% --------------------------------------------------------------------
function record_video_menu_Callback(hObject,~,handles)
% hObject    handle to record_video_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

switch hObject.Checked
    case 'off'
        hObject.Checked = 'on';
        handles.vid_compress_menu.Enable = 'on';
    case 'on'
        hObject.Checked = 'off';
        handles.vid_compress_menu.Enable = 'off';
end


function edit_area_maximum_Callback(hObject, ~, handles)
% hObject    handle to edit_area_maximum (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

expmt = getappdata(handles.gui_fig,'expmt');
expmt.parameters.area_max = str2double(hObject.String);
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_area_maximum_CreateFcn(hObject,~,~)
% hObject    handle to edit_area_maximum (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function view_menu_Callback(~,~,~)
% hObject    handle to view_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)



% --------------------------------------------------------------------
function view_roi_bounds_menu_Callback(hObject, ~, handles)
% hObject    handle to view_roi_bounds_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

expmt = getappdata(handles.gui_fig,'expmt');

switch hObject.Checked
    
    case 'off'

        if isfield(expmt.meta.roi,'n') && expmt.meta.roi.n &&...
                strcmp(expmt.parameters.roi_mode,'auto')
            
            hObject.Checked = 'on';
            hold on
            for i =1:length(expmt.meta.roi.centers)
                handles.view_menu.UserData.hBounds(i) = ...
                    rectangle(handles.axes_handle,'Position',...
                        expmt.meta.roi.bounds(i,:),'EdgeColor','r');
            end
            hold off
            
        elseif isfield(expmt.meta.roi,'n') && expmt.meta.roi.n &&...
                strcmp(expmt.parameters.roi_mode,'grid')
            
            hObject.Checked = 'on';
            g = handles.add_ROI_pushbutton.UserData.grid;
            xdat=[];
            ydat=[];
            for i=1:length(g)                
                xdat = [xdat g(i).XData];
                ydat = [ydat g(i).YData];
            end
            handles.view_menu.UserData.hBounds = patch('Faces',1:size(xdat,2),...
                'XData',xdat,'YData',ydat,'FaceColor','none','EdgeColor','r',...
                'Parent',handles.axes_handle);
        else
            gui_notify('ROIs are not set and cannot be displayed',handles.disp_note);
        end
        
    case 'on'
        
        hObject.Checked = 'off';
        
        if isfield(handles.view_menu.UserData,'hBounds')
            set(handles.view_menu.UserData.hBounds,'Visible','off');
        end
end


% --------------------------------------------------------------------
function view_roi_num_menu_Callback(hObject, ~, handles)
% hObject    handle to view_roi_num_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

expmt = getappdata(handles.gui_fig,'expmt');

switch hObject.Checked
    
    case 'off'
        
        if isfield(expmt.meta.roi,'n') && expmt.meta.roi.n
            hObject.Checked = 'on';
            hold on
            for i =1:length(expmt.meta.roi.centers)
                handles.view_menu.UserData.hNum(i) =...
                    text(handles.axes_handle,expmt.meta.roi.centers(i,1),...
                    expmt.meta.roi.centers(i,2),num2str(i),'Color',[0 0 1],...
                    'HorizontalAlignment','center','VerticalAlignment','middle');
            end
            hold off
        else
            gui_notify('ROIs are not set and cannot be displayed',handles.disp_note);
        end
        
    case 'on'
        
        hObject.Checked = 'off';
        
        if isfield(handles.view_menu.UserData,'hNum')
            set(handles.view_menu.UserData.hNum,'Visible','off');
        end
end


% --------------------------------------------------------------------
function view_roi_ori_menu_Callback(hObject, ~, handles)
% hObject    handle to view_roi_ori_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)


expmt = getappdata(handles.gui_fig,'expmt');

switch hObject.Checked
    
    case 'off'

        if isfield(expmt.meta.roi,'n') && expmt.meta.roi.n
            hObject.Checked = 'on';
            hold on
            for i =1:length(expmt.meta.roi.centers)
                handles.view_menu.UserData.hOri(i) =...
                    text(handles.axes_handle,expmt.meta.roi.centers(i,1),...
                        expmt.meta.roi.centers(i,2),...
                        num2str(expmt.meta.roi.orientation(i)),...
                        'HorizontalAlignment','center');
                if expmt.meta.roi.orientation(i)
                    handles.view_menu.UserData.hOri(i).Color = [1 0 1];
                else
                    handles.view_menu.UserData.hOri(i).Color = [0 0 1];
                end
            end
            hold off
        else
            gui_notify('ROIs are not set and cannot be displayed',handles.disp_note);
        end
        
    case 'on'
        
        hObject.Checked = 'off';
        
        if isfield(handles.view_menu.UserData,'hOri')
            set(handles.view_menu.UserData.hOri,'Visible','off');
        end
end

% --------------------------------------------------------------------
function view_ref_cen_menu_Callback(hObject, eventdata, handles)
% hObject    handle to view_ref_cen_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

expmt = getappdata(handles.gui_fig,'expmt');

switch hObject.Checked
    
    case 'off'
        hObject.Checked = 'on';
        if isfield(handles.view_menu.UserData,'hRefCen') &&...
                any(ishghandle(handles.view_menu.UserData.hRefCen))
            delete(handles.view_menu.UserData.hRefCen);
        end
        ah = handles.axes_handle;
        if isfield(expmt.meta.ref,'im') && isfield(expmt.meta.ref,'cen')
            x = squeeze(expmt.meta.ref.cen(:,1,:));
            y = squeeze(expmt.meta.ref.cen(:,2,:));
            x(isnan(x))=[];
            y(isnan(y))=[];
            hold on
            handles.view_menu.UserData.hRefCen = plot(ah,x,y,'mo','Linewidth',1.5);
            hold off
        end
        
    case 'on'
        hObject.Checked = 'off';
        if isfield(handles.view_menu.UserData,'hRefCen') &&...
                ishghandle(handles.view_menu.UserData.hRefCen)
            delete(handles.view_menu.UserData.hRefCen);
        end
end

% --------------------------------------------------------------------
function man_edit_roi_menu_Callback(hObject, ~, handles)
% hObject    handle to man_edit_roi_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

expmt = getappdata(handles.gui_fig,'expmt');

clean_gui(handles.axes_handle);
handles.hImage = findobj(handles.axes_handle,'-depth',3,'Type','Image');

has_Enable = findall(handles.gui_fig, '-property', 'Enable');
Enable_states = get(has_Enable,'Enable');
set(has_Enable,'Enable','off');

axh = handles.axes_handle;
instructions = {'Right-click in an existing ROI to delete it'...
    ['Left-click to switch tool to draw tool, '...
    'then left-click and drag to define new ROI'] ...
    'Press any key to accept changes and exit'};
text(axh,axh.XLim(2)*0.5,axh.YLim(2)*0.05,instructions,...
    'color','m','HorizontalAlignment','center');


set(handles.axes_handle,'ButtonDownFcn',@mouse_click_Callback);
handles.hImage.HitTest = 'off';
handles.gui_fig.UserData.edit_rois = true;
guidata(hObject,handles);

if isfield(expmt.meta.roi,'n') && expmt.meta.roi.n
    
        % Take single frame
    if strcmp(expmt.meta.source,'camera')
        trackDat.im = peekdata(expmt.hardware.cam.vid,1);
    else
        [trackDat.im, expmt.meta.video] = nextFrame(expmt.meta.video,handles);
    end

    % extract green channel if format is RGB
    if size(trackDat.im,3)>1
        trackDat.im = trackDat.im(:,:,2);
    end
    
    % set display to ROI image and label ROIs
    handles.hImage.CData = trackDat.im;
    
    hold on
    for i =1:length(expmt.meta.roi.centers)
        hBounds(i) = rectangle(handles.axes_handle,...
            'Position',expmt.meta.roi.bounds(i,:),'EdgeColor','r');
        hNum(i) = text(handles.axes_handle,expmt.meta.roi.centers(i,1),...
            expmt.meta.roi.centers(i,2),num2str(i),'Color',[0 0 1],...
            'HorizontalAlignment','center','VerticalAlignment','middle',...
            'HitTest','off');
    end
    hold off

    while handles.gui_fig.UserData.edit_rois
        
        pause(0.001);
        
        % listen for mouse clicks
        if isfield(handles.gui_fig.UserData,'click')
            
            % get click info
            b = handles.gui_fig.UserData.click.button;
            c = handles.gui_fig.UserData.click.coords;
            
            switch b
                
                % case for left-click
                case 1
                    roi = getrect(handles.axes_handle);
                    if roi(3) > 0.1*median(expmt.meta.roi.bounds(3)) &&...
                            roi(4) > 0.1*median(expmt.meta.roi.bounds(4))
                        
                        expmt.meta.roi.bounds = [expmt.meta.roi.bounds; roi];
                        roi(3) = roi(1) + roi(3);
                        roi(4) = roi(2) + roi(4);
                        expmt.meta.roi.corners = [expmt.meta.roi.corners; roi];
                        
                    end
                    
                % case for right-click
                case 3
                    
                    % check to see if click occured in ROI
                    x_bounded = c(1) > expmt.meta.roi.bounds(:,1) &...
                        c(1) < sum(expmt.meta.roi.bounds(:,[1 3]),2);
                    y_bounded = c(2) > expmt.meta.roi.bounds(:,2) &...
                        c(2) < sum(expmt.meta.roi.bounds(:,[2 4]),2);
                    
                    % delete targeted ROI
                    idx = find(x_bounded & y_bounded);
                    delete(hBounds(x_bounded & y_bounded));
                    expmt.meta.roi.bounds(idx,:) = [];
                    expmt.meta.roi.centers(idx,:) = [];
                    expmt.meta.roi.orientation(idx,:) = [];
                    expmt.meta.roi.corners(idx,:) = [];
                    
            end
            
            % remove click data
            handles.gui_fig.UserData = rmfield(handles.gui_fig.UserData,'click');
            
            % re-sort and label ROIs
            [x,y] = ROIcenters(expmt.meta.roi.im,expmt.meta.roi.corners);
            expmt.meta.roi.centers = [x,y];
            [expmt.meta.roi.centers,expmt.meta.roi.corners,expmt.meta.roi.bounds] = ...
                sortROIs(handles.gui_fig.UserData.ROI_tol,expmt.meta.roi.centers,expmt.meta.roi.corners,expmt.meta.roi.bounds);
            expmt.meta.roi.orientation = getMazeOrientation(expmt.meta.roi.im,expmt.meta.roi.corners);
            
            % re-draw ROIs
            delete(hBounds);
            delete(hNum);
            hold on
            for i =1:length(expmt.meta.roi.centers)
                hBounds(i) = rectangle(handles.axes_handle,'Position',expmt.meta.roi.bounds(i,:),'EdgeColor','r');
                hNum(i) = text(handles.axes_handle,expmt.meta.roi.centers(i,1),...
                    expmt.meta.roi.centers(i,2),num2str(i),'Color',[0 0 1],...
                    'HorizontalAlignment','center','VerticalAlignment','middle',...
                    'HitTest','off');
            end
            hold off

        end
    end

end

% re-Enable objects that were Enabled before selecting manual edit
for i = 1:length(has_Enable)
    has_Enable(i).Enable = Enable_states{i};
end

% clear drawn objects from the axes
clean_gui(handles.axes_handle);

% save changes to master struct and gui data
setappdata(handles.gui_fig,'expmt',expmt);
guidata(hObject,handles);

function mouse_click_Callback(hObject,eventdata)

hObject.Parent.UserData.click.button = eventdata.Button;
hObject.Parent.UserData.click.coords = eventdata.IntersectionPoint;


% --- Executes on key press with focus on gui_fig and none of its controls.
function gui_fig_KeyPressFcn(hObject, ~, handles)
% hObject    handle to gui_fig (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

if handles.gui_fig.UserData.edit_rois
    handles.gui_fig.UserData.edit_rois = false;
end

guidata(hObject,handles);


% --- Executes on key press with focus on gui_fig or any of its controls.
function gui_fig_WindowKeyPressFcn(~,~,~)
% hObject    handle to gui_fig (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)



% --- Executes during object creation, after setting all properties.
function pause_togglebutton_CreateFcn(hObject, ~, handles)
% hObject    handle to pause_togglebutton (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

hObject.Units = 'Pixels';
w = hObject.Position(3);
h = hObject.Position(4);
c = hObject.BackgroundColor;
ps = zeros(h,w,3);
for i = 1:length(c)
    ps(:,:,i) = c(i);
end

hs = 0.28;
ws = 0.08;
wo = 0.39;
hb = round(h*hs:h*(1-hs));
wb = round([wo*w wo*w+w*ws w*(1-ws)-wo*w w*(1-wo)]);
ps(hb,wb(1):wb(2),:) = 0;
ps(hb,wb(3):wb(4),:) = 0;
hObject.UserData.ps = ps;

hObject.CData = ps;
hObject.Units = 'Points';
guidata(hObject,handles);





% --- Executes on button press in stop_pushbutton.
function stop_pushbutton_Callback(hObject, ~, handles)
% hObject    handle to stop_pushbutton (see GCBO)

% handles    structure with handles and user data (see GUIDATA)


if hObject.Value
        hObject.UserData.Value = 1;
end

guidata(hObject,handles);




% --- Executes during object creation, after setting all properties.
function run_pushbutton_CreateFcn(hObject, ~, handles)
% hObject    handle to run_pushbutton (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

hObject.Units = 'Pixels';
w = hObject.Position(3);
h = hObject.Position(4);
c = hObject.BackgroundColor;
ps = zeros(h,w,3);
for i = 1:length(c)
    ps(:,:,i) = c(i);
end

hs = 0.28;
ws = 0.08;
wo = 0.39;
hb = round([h*hs h*(1-hs)]);
wb = round([wo*w:w*(1-wo)]);

for i = 1:length(wb)   
    ps(hb(1)+floor(i/1.5):hb(2)-floor(i/1.5),wb(i),:) = 0;
end

hObject.UserData.ps = ps;

hObject.CData = ps;
hObject.Units = 'Points';
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function stop_pushbutton_CreateFcn(hObject, ~, handles)
% hObject    handle to stop_pushbutton (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

hObject.Units = 'Pixels';
w = hObject.Position(3);
h = hObject.Position(4);
c = hObject.BackgroundColor;
ps = zeros(h,w,3);
for i = 1:length(c)
    ps(:,:,i) = c(i);
end

hs = 0.28;
ws = 0.08;
wo = 0.37;
hb = round([h*hs:h*(1-hs)]);
wb = round([wo*w:w*(1-wo)]);

ps(hb,wb,:)=0;

hObject.UserData.ps = ps;

hObject.CData = ps;
hObject.Units = 'Points';

hObject.UserData.Value = 0;
guidata(hObject,handles);


% --------------------------------------------------------------------
function unlock_controls_menu_Callback(hObject, ~, handles)
% hObject    handle to unlock_controls_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

set(findall(handles.gui_fig,'-property','Enable'),'Enable','on');
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function gui_fig_CreateFcn(~, ~, ~)
% hObject    handle to gui_fig (see GCBO)

% handles    empty - handles not created until after all CreateFcns called




% --- Executes when user attempts to close gui_fig.
function gui_fig_CloseRequestFcn(hObject, ~, handles)
% hObject    handle to gui_fig (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'deviceID')
    try
    [~,status]=urlread(['http://lab.debivort.org/mu.php?id=' handles.deviceID '&st=0']);
    catch
        status = false;
    end
    if ~status
        gui_notify('unable to connect to http://lab.debivort.org',handles.disp_note);
    end
end

% Hint: delete(hObject) closes the figure
delete(hObject);


% --------------------------------------------------------------------
function cam_menu_Callback(hObject, eventdata, handles) %#ok<*INUSD>
% hObject    handle to cam_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function cam_calibrate_menu_Callback(hObject, eventdata, handles)
% hObject    handle to cam_calibrate_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

expmt = getappdata(handles.gui_fig,'expmt');

switch hObject.Checked
    case 'on'
        hObject.Checked = 'off';
        hObject.UserData = false;
        expmt.hardware.cam.calibrate = false;
    case 'off'
        hObject.Checked = 'on';
        hObject.UserData = true;
        expmt.hardware.cam.calibrate = true;
end

setappdata(handles.gui_fig,'expmt',expmt);
guidata(hObject,handles);


% --- Executes on button press in add_ROI_pushbutton.
function add_ROI_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to add_ROI_pushbutton (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

if hObject.UserData.nGrids < 10
    
    hObject.UserData.nGrids = hObject.UserData.nGrids + 1;
    handles = update_grid_UI(handles,'add');
    
end

guidata(hObject,handles);


% --- Executes on button press in remove_ROI_pushbutton.
function remove_ROI_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to remove_ROI_pushbutton (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

if handles.add_ROI_pushbutton.UserData.nGrids > 1
    
    handles = update_grid_UI(handles,'subtract');
    
end

guidata(hObject,handles);


% --- Executes on selection change in ROI_shape_popupmenu1.
function ROI_shape_popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to ROI_shape_popupmenu1 (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

n = hObject.UserData;
handles.add_ROI_pushbutton.UserData.grid(n).shape = hObject.String{hObject.Value};
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function ROI_shape_popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ROI_shape_popupmenu1 (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

hObject.UserData = 1;
guidata(hObject,handles);



function row_num_edit1_Callback(hObject, eventdata, handles)
% hObject    handle to row_num_edit1 (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

n = hObject.Value;
handles.add_ROI_pushbutton.UserData.grid(n).nRows = str2double(hObject.String);
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function row_num_edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to row_num_edit1 (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

hObject.Value = 1;
guidata(hObject,handles);



function col_num_edit1_Callback(hObject, eventdata, handles)
% hObject    handle to row_num_edit1 (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

n = hObject.Value;
handles.add_ROI_pushbutton.UserData.grid(n).nCols = str2double(hObject.String);
guidata(hObject,handles);



% --- Executes during object creation, after setting all properties.
function col_num_edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to row_num_edit1 (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

hObject.Value = 1;
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function add_ROI_pushbutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to add_ROI_pushbutton (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

hObject.UserData.nGrids = 1;
hObject.UserData.grid = struct('shape','Quadrilateral','nRows',8,'nCols',12,...
    'hs',[],'hr',[],'hc',[],'hp',[],'centers',[],'bounds',[],...
    'XData',[],'YData',[],'polypos',[],'tform',[]);
hObject.Value = false;
guidata(hObject,handles);



% --- Executes during object creation, after setting all properties.
function grid_ROI_uipanel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to grid_ROI_uipanel (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

hObject.Visible = 'off';
guidata(hObject,handles);




% --------------------------------------------------------------------
function view_cen_num_Callback(hObject, eventdata, handles)
% hObject    handle to view_cen_num (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

switch hObject.Checked
    case 'off'
        hObject.Checked = 'on';
    case 'on'
        hObject.Checked = 'off';
end

if isfield(handles.gui_fig.UserData,'cenText') && ishghandle(handles.gui_fig.UserData.cenText(1))
    
    switch handles.view_cen_num.Checked
        case 'on'
            set(handles.gui_fig.UserData.cenText,'Visible','on');
        case 'off'
            set(handles.gui_fig.UserData.cenText,'Visible','off');
    end
    
else

    expmt = getappdata(handles.gui_fig,'expmt');
    lblstr = arrayfun(@num2str,1:length(expmt.meta.roi.centers(:,1)),'UniformOutput',false);
    handles.gui_fig.UserData.cenText = text(expmt.meta.roi.centers(:,1),expmt.meta.roi.centers(:,2),lblstr,...
        'Color','m','FontSmoothing','off','HorizontalAlignment','center','Visible','off');
    
    switch handles.view_cen_num.Checked
        case 'on'
            set(handles.gui_fig.UserData.cenText,'Visible','on');
        case 'off'
            set(handles.gui_fig.UserData.cenText,'Visible','off');
    end
    
end

guidata(hObject,handles);





% --------------------------------------------------------------------
function video_menu_Callback(hObject, eventdata, handles)
% hObject    handle to video_menu (see GCBO)

% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function vid_compress_menu_Callback(hObject, eventdata, handles)
% hObject    handle to vid_compress_menu (see GCBO)


switch hObject.Checked
    case 'off'
        hObject.Checked = 'on';
    case 'on'
        hObject.Checked = 'off';
end


% --------------------------------------------------------------------
function analysis_menu_Callback(hObject, eventdata, handles)

expmt = getappdata(handles.gui_fig,'expmt');
analysisoptions_gui(expmt);





function edit_area_minimum_Callback(hObject, eventdata, handles)
% hObject    handle to edit_area_minimum (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

expmt = getappdata(handles.gui_fig,'expmt');
expmt.parameters.area_min = str2double(hObject.String);
guidata(hObject,handles);



% --- Executes during object creation, after setting all properties.
function edit_area_minimum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_area_minimum (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_target_rate_Callback(hObject, eventdata, handles)
% hObject    handle to edit_target_rate (see GCBO)

% handles    structure with handles and user data (see GUIDATA)

expmt = getappdata(handles.gui_fig,'expmt');
expmt.parameters.target_rate = str2double(hObject.String);


% --- Executes during object creation, after setting all properties.
function edit_target_rate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_target_rate (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
