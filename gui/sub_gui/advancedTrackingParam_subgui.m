function varargout = advancedTrackingParam_subgui(varargin)
% ADVANCEDTRACKINGPARAM_SUBGUI MATLAB code for advancedTrackingParam_subgui.fig
%      ADVANCEDTRACKINGPARAM_SUBGUI, by itself, creates a new ADVANCEDTRACKINGPARAM_SUBGUI or raises the existing
%      singleton*.
%
%      H = ADVANCEDTRACKINGPARAM_SUBGUI returns the handle to a new ADVANCEDTRACKINGPARAM_SUBGUI or the handle to
%      the existing singleton*.
%
%      ADVANCEDTRACKINGPARAM_SUBGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ADVANCEDTRACKINGPARAM_SUBGUI.M with the given input arguments.
%
%      ADVANCEDTRACKINGPARAM_SUBGUI('Property','Value',...) creates a new ADVANCEDTRACKINGPARAM_SUBGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before advancedTrackingParam_subgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to advancedTrackingParam_subgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help advancedTrackingParam_subgui

% Last Modified by GUIDE v2.5 31-Mar-2017 18:13:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @advancedTrackingParam_subgui_OpeningFcn, ...
                   'gui_OutputFcn',  @advancedTrackingParam_subgui_OutputFcn, ...
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




% --- Executes just before advancedTrackingParam_subgui is made visible.
function advancedTrackingParam_subgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to advancedTrackingParam_subgui (see VARARGIN)

expmt = varargin{1};
param_data = expmt.parameters;

in_handles = varargin{2};
handles.track_fig.UserData.gui_handles = in_handles;
handles.track_fig.UserData.expmt = expmt;
gui_fig = in_handles.gui_fig;



% Set GUI strings with input parameters
set(handles.edit_speed_thresh,'string',round(10*gui_fig.UserData.speed_thresh)/10);
set(handles.edit_dist_thresh,'string',round(10*gui_fig.UserData.distance_thresh)/10);
set(handles.edit_target_rate,'string',round(10*gui_fig.UserData.target_rate)/10);
set(handles.edit_vignette_sigma,'string',round(10*gui_fig.UserData.vignette_sigma)/10);
set(handles.edit_vignette_weight,'string',round(10*gui_fig.UserData.vignette_weight)/10);
set(handles.edit_area_min,'string',round(10*gui_fig.UserData.area_min)/10);
set(handles.edit_area_max,'string',round(10*gui_fig.UserData.area_max)/10);
set(handles.edit_ROI_cluster_tolerance,'string',round(100*gui_fig.UserData.ROI_tol)/100);

% find idx of active mode in menu and set it in gui
activemode = find(strcmp(gui_fig.UserData.sort_mode,handles.sort_mode_popupmenu.String));
handles.sort_mode_popupmenu.Value = activemode;

% find idx of active mode in menu and set it in gui
activemode = find(strcmp(gui_fig.UserData.ROI_mode,handles.roi_mode_popupmenu.String));
if strcmp(gui_fig.UserData.ROI_mode,'grid')
    handles.sort_mode_popupmenu.Enable = 'off';
end
handles.roi_mode_popupmenu.Value = activemode;

% set subgui position to top left corner of the axes
handles.track_fig.Position(1) = gui_fig.Position(1) + ...
    sum(in_handles.light_uipanel.Position([1 3])) - handles.track_fig.Position(3);
handles.track_fig.Position(2) = gui_fig.Position(2) + ...
    sum(in_handles.light_uipanel.Position([2 4])) - handles.track_fig.Position(4) - 25;

% Update handles structure
guidata(hObject, handles);




% --- Outputs from this function are returned to the command line.
function varargout = advancedTrackingParam_subgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% handles    structure with handles and user data (see GUIDATA)

% initialize tracking vars
trackDat.ct = 0;



% get handles to main gui
expmt = handles.track_fig.UserData.expmt;
gui_handles = handles.track_fig.UserData.gui_handles;
gui_fig = gui_handles.gui_fig;
display_menu = findobj('Tag','display_menu');
display_menu.UserData = 1;
thresh_slider = findobj('Tag','track_thresh_slider');


% enable display controls
for i = 1:length(display_menu.Children)
    display_menu.Children(i).Enable = 'on';
    display_menu.Children(i).Checked = 'off';
end
raw_menu = findobj(display_menu,'-depth',2,'Label','raw image'); 
raw_menu.Checked = 'on';
display_menu.UserData = 1;
display = false;

% clear any objects drawn to gui window
centroid_markers = findobj(gui_handles.axes_handle,'-depth',3,'Type','line');
delete(centroid_markers);
rect_handles = findobj(gui_handles.axes_handle,'-depth',3,'Type','rectangle');
delete(rect_handles);
text_handles = findobj(gui_handles.axes_handle,'-depth',3,'Type','text');
delete(text_handles);

%% Initialize camera and video object

expmt = getVideoInput(expmt,gui_handles);

switch expmt.source
    case 'camera'
        if isfield(expmt.camInfo,'vid')
            display = true;
        end
    case 'video'
        if isfield(expmt.video,'vid')
            display = true;
        end
end

imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','image');

if display && isempty(imh)
    
    % Take single frame
    if strcmp(expmt.source,'camera')
        trackDat.im = peekdata(expmt.camInfo.vid,1);
    else
        [trackDat.im, expmt.video] = nextFrame(expmt.video,gui_handles);
    end

    % extract green channel if format is RGB
    if size(trackDat.im,3)>1
        trackDat.im = trackDat.im(:,:,2);
    end     
    
    imh = image(gui_handles.axes_handle,trackDat.im);
    colormap(gui_handles.axes_handle,'gray');
    
end

%% Tracking setup

% initialize tracking variables if any parameter display is ticked
trackDat.fields={'Centroid';'Area';'Speed'};     % Define fields autoTrack output

if isfield(expmt,'ROI') && isfield(expmt.ROI,'centers')
    trackDat.Centroid = expmt.ROI.centers;     % placeholder for most recent non-NaN centroids
else
    midpoint(1) = sum(gui_handles.axes_handle.XLim)/2;
    midpoint(2) = sum(gui_handles.axes_handle.YLim)/2;
    trackDat.Centroid = [midpoint(1) midpoint(2)];
end

% initialize coords
d_bounds = centerRect(trackDat.Centroid,gui_fig.UserData.distance_thresh);
mi_bounds = centerRect(trackDat.Centroid,sqrt(gui_fig.UserData.area_min/pi));
ma_bounds = centerRect(trackDat.Centroid,sqrt(gui_fig.UserData.area_max/pi));

% initialize handles with position set to bounds
for i = 1:size(trackDat.Centroid,1)

    spdText(i) = text(gui_handles.axes_handle,'Position',trackDat.Centroid(i,:),...
        'String','0','Visible','off','Color',[1 0 1]);
    minCirc(i) = rectangle(gui_handles.axes_handle,'Position',mi_bounds(i,:),...
        'EdgeColor',[1 0 0],'Curvature',[1 1],'Visible','off');
    maxCirc(i) = rectangle(gui_handles.axes_handle,'Position',ma_bounds(i,:),...
        'EdgeColor',[1 0 0],'Curvature',[1 1],'Visible','off');
    areaText(i) = text(gui_handles.axes_handle,'Position',trackDat.Centroid(i,:),...
        'String','0','Visible','off','Color',[1 0 0]);
    dstCirc(i) = rectangle(gui_handles.axes_handle,'Position',d_bounds(i,:),...
        'EdgeColor',[0 0 1],'Curvature',[1 1],'Visible','off');
    
end

% initialize rolling averages of speed and area
roll_speed = NaN(size(trackDat.Centroid,1),500);
roll_area = NaN(size(trackDat.Centroid,1),500);

% initialize timer
tic
trackDat.t=0;
tPrev = toc;
trackDat.tStamp = zeros(size(trackDat.Centroid,1),1);


%% Tracking loop


while ishghandle(hObject) && display

    pause(0.002);
    
    % update timer
    if isfield(trackDat,'t')
        tCurrent = toc;
        trackDat.t = tCurrent - tPrev + trackDat.t;
        tPrev = tCurrent;
    end
    
    % grab a frame if a camera or video object exists
    if (isfield(expmt.camInfo,'vid') && strcmp(expmt.camInfo.vid.Running,'on')) ||...
            isfield(expmt,'video')

        % query next frame and optionally correct lens distortion
        [trackDat,expmt] = autoFrame(trackDat,expmt,gui_handles);         
    end
    
    % check if parameter visualization aids are toggled
    if ishandle(handles.speed_thresh_radiobutton)
        disp_speed = get(handles.speed_thresh_radiobutton,'value');
        disp_dist = get(handles.distance_thresh_radiobutton,'value');
        disp_area = get(handles.area_radiobutton,'value');
    end
    
        
    % if speed display button ticked
    if disp_speed

        % re-enable display if necessary
        if strcmp(spdText(1).Visible,'off') 
            for i = 1:length(spdText)
                spdText(i).Visible = 'on';
            end
        end

        % display parameter preview on objects and ROIs if they exist
        if isfield(expmt,'ref') && isfield(expmt.vignette,'im')

            % track objects and sort outputs specified in trackDat.fields
            trackDat = autoTrack(trackDat,expmt,gui_handles);

            % update rolling speed
            roll_speed(:,mod(trackDat.ct,size(roll_speed,2))+1) = trackDat.Speed;

        end

        % convert real distance to pixel for proper display
        px_r = gui_fig.UserData.speed_thresh/expmt.parameters.mm_per_pix;
        spd = num2cell(roll_speed,2);
        cen = num2cell(trackDat.Centroid,2);
        arrayfun(@updateSpeed,spdText',cen,spd);
        
        
        
    % disable display if necessary
    else
        if strcmp(spdText(1).Visible,'on')
            for i = 1:length(spdText)
                spdText(i).Visible = 'off';
            end
        end
    end
        
        
    % distance thresh display ticked
    if disp_dist

        % re-enable display if necessary
        if strcmp(dstCirc(1).Visible,'off')
            for i = 1:length(dstCirc)
                dstCirc(i).Visible = 'on';
            end
        end

        % use trackiog from disp_speed if toggled, else initiate
        % tracking
        if ~disp_speed

            if isfield(expmt,'ref') && isfield(expmt.vignette,'im')

            % track objects and sort outputs specified in trackDat.fields
            trackDat = autoTrack(trackDat,expmt,gui_handles);

            end

        end

        % convert real distance to pixel for proper display
        px_r = gui_fig.UserData.distance_thresh/expmt.parameters.mm_per_pix;
        if isfield(expmt,'ROI') && isfield(expmt.ROI,'centers')
            d_bounds = centerRect(expmt.ROI.centers,px_r);
        else
            mid(1) = sum(gui_handles.axes_handle.XLim)/2;
            mid(2) = sum(gui_handles.axes_handle.YLim)/2;
            d_bounds = centerRect([mid(1) mid(2)],px_r);
        end

        db = num2cell(d_bounds,2);
        arrayfun(@updateDistance,dstCirc',db);
        

    % disable display if necessary
    else
        if strcmp(dstCirc(1).Visible,'on')      
            set(dstCirc,'Visible','off');
        end
    end
        
    % Area display ticked
    if disp_area

        % re-enable display if necessary
        if strcmp(minCirc(1).Visible,'off') || strcmp(maxCirc(1).Visible,'off')
            set(minCirc,'Visible','on');
            set(maxCirc,'Visible','on');
            set(areaText,'Visible','on');
        end

        % use tracking from disp_speed if toggled, else initiate
        % tracking
        if ~disp_speed && ~disp_dist

            if isfield(expmt,'ref') && isfield(expmt.vignette,'im')

                % track objects and sort outputs specified in trackDat.fields
                trackDat = autoTrack(trackDat,expmt,gui_handles);

            end

        end

        % calculate rolling average of centroid area
        if isfield(trackDat,'Area')
            roll_area(:,mod(trackDat.ct,size(roll_area,2))+1) = trackDat.Area;
        end

        % else display preview in center of axes
        px_r = gui_fig.UserData.area_min/expmt.parameters.mm_per_pix;
        mi_bounds = centerRect(trackDat.Centroid,sqrt(px_r/pi));
        px_r = gui_fig.UserData.area_max/expmt.parameters.mm_per_pix;
        ma_bounds = centerRect(trackDat.Centroid,sqrt(px_r/pi));
        
        mib = num2cell(mi_bounds,2);
        mab = num2cell(ma_bounds,2);
        rar = num2cell(roll_area,2);
        cen = num2cell(trackDat.Centroid,2);
        arrayfun(@updateArea,minCirc',maxCirc',areaText',cen,mib,mab,rar);

    % else make objects invisible
    else
        if strcmp(minCirc(1).Visible,'on') || strcmp(maxCirc(1).Visible,'on')
            set(minCirc,'Visible','off');
            set(maxCirc,'Visible','off');
            set(areaText,'Visible','off');
        end
    end


    % update the display
    updateDisplay(trackDat, expmt, imh, gui_handles);
    drawnow
            
end

% assign values to expmt struct
expmt.parameters.speed_thresh = gui_handles.gui_fig.UserData.speed_thresh;
expmt.parameters.distance_thresh = gui_handles.gui_fig.UserData.distance_thresh;
expmt.parameters.vignette_sigma = gui_handles.gui_fig.UserData.vignette_sigma;
expmt.parameters.vignette_weight = gui_handles.gui_fig.UserData.vignette_weight;
expmt.parameters.area_min = gui_handles.gui_fig.UserData.area_min;
expmt.parameters.area_max = gui_handles.gui_fig.UserData.area_max;
expmt.parameters.ROI_mode = gui_handles.gui_fig.UserData.ROI_mode;
expmt.parameters.sort_mode = gui_handles.gui_fig.UserData.sort_mode;
expmt.parameters.ROI_tol = gui_handles.gui_fig.UserData.ROI_tol;
expmt.parameters.target_rate = gui_handles.gui_fig.UserData.target_rate;

setappdata(gui_handles.gui_fig,'expmt',expmt);

varargout(1) = {expmt};

% clear objects from display
rect_handles = findobj(gui_handles.axes_handle,'-depth',3,'Type','rectangle');
delete(rect_handles);
text_handles = findobj(gui_handles.axes_handle,'-depth',3,'Type','text');
delete(text_handles);

% disable and reset display controls
for i = 1:length(display_menu.Children)
    display_menu.Children(i).Enable = 'off';
    display_menu.Children(i).Checked = 'off';
end

raw_menu = findobj(display_menu,'-depth',2,'Label','raw image'); 
raw_menu.Checked = 'on';
display_menu.UserData = 1;

%update speed text display
function updateSpeed(h,pos,spd)

    % update display
    h.Position = [pos{:}(1) pos{:}(2)+5];
    if isnan(round(nanmean(spd{:})*10)/10)
        h.String = '';
    else
        u = num2str(round(nanmean(spd{:})*10)/100);
        st_dev = num2str(round(nanstd(spd{:})*10)/10);
        h.String = [u ' ' char(177) ' ' st_dev];
    end

    
% update distance circle display bounds
function updateDistance(h,bounds)

h.Position = bounds{:};


% update area circle display bounds and text
function updateArea(hmi,hma,ht,pos,minb,maxb,area)

    hmi.Position = minb{:};
    hma.Position = maxb{:};
    ht.Position = [pos{:}(1) pos{:}(2)+20];
    if isnan(round(nanmean(area{:})*10)/10)
        ht.String = '';
    else
        u = num2str(round(nanmean(area{:})*10)/10);
        st_dev = num2str(round(nanstd(area{:})*10)/10);
        ht.String = [u ' ' char(177) ' ' st_dev];
    end




% --- Executes when user attempts to close track_fig.
function track_fig_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to track_fig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

delete(handles.track_fig);






%*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*%
%*-*-*-*-*-*-*-*-*-*-*-*-* GUI CALLBACKS *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*%
%*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*%




function edit_vignette_weight_Callback(hObject, eventdata, handles)
% hObject    handle to edit_vignette_weight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_vignette_weight as text
%        str2double(get(hObject,'String')) returns contents of edit_vignette_weight as a double

gui_fig = handles.track_fig.UserData.gui_handles.gui_fig;

gui_fig.UserData.vignette_weight=str2num(get(handles.edit_vignette_weight,'string'));
guidata(hObject,handles);


function edit_vignette_sigma_Callback(hObject, eventdata, handles)
% hObject    handle to edit_vignette_sigma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_vignette_sigma as text
%        str2double(get(hObject,'String')) returns contents of edit_vignette_sigma as a double

gui_fig = handles.track_fig.UserData.gui_handles.gui_fig;

gui_fig.UserData.vignette_sigma=str2num(get(handles.edit_vignette_sigma,'string'));
guidata(hObject,handles);


function edit_target_rate_Callback(hObject, eventdata, handles)
% hObject    handle to edit29 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit29 as text
%        str2double(get(hObject,'String')) returns contents of edit29 as a double

gui_fig = handles.track_fig.UserData.gui_handles.gui_fig;

gui_fig.UserData.target_rate=str2num(handles.edit_target_rate.String);
guidata(hObject,handles);



function edit_dist_thresh_Callback(hObject, eventdata, handles)
% hObject    handle to edit_dist_thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_dist_thresh as text
%        str2double(get(hObject,'String')) returns contents of edit_dist_thresh as a double

gui_fig = handles.track_fig.UserData.gui_handles.gui_fig;
handles.track_fig.UserData.gui_handles.edit_dist_thresh.String =...
    get(handles.edit_dist_thresh,'string');

gui_fig.UserData.distance_thresh=str2num(get(handles.edit_dist_thresh,'string'));
guidata(hObject,handles);



function edit_speed_thresh_Callback(hObject, eventdata, handles)
% hObject    handle to edit_speed_thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_speed_thresh as text
%        str2double(get(hObject,'String')) returns contents of edit_speed_thresh as a double

gui_fig = handles.track_fig.UserData.gui_handles.gui_fig;
handles.track_fig.UserData.gui_handles.edit_speed_thresh.String =...
    get(handles.edit_speed_thresh,'string');

gui_fig.UserData.speed_thresh=str2num(get(handles.edit_speed_thresh,'string'));
guidata(hObject,handles);



function edit_area_max_Callback(hObject, eventdata, handles)
% hObject    handle to edit_area_max (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

gui_fig = handles.track_fig.UserData.gui_handles.gui_fig;

gui_fig.UserData.area_max = str2num(get(hObject,'string'));
guidata(hObject,handles);



function edit_area_min_Callback(hObject, eventdata, handles)
% hObject    handle to edit_area_min (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

gui_fig = handles.track_fig.UserData.gui_handles.gui_fig;

gui_fig.UserData.area_min = str2num(get(hObject,'string'));
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

item5=['\bfROI Vertical Clustering Tolerance\rm - maximum number of standard ' ...
    'deviations allowed in the vertical distance between the y-coordinate of an ROI'...
    'and the nearest y-coordinates of other ROIs in the same cluster. This is important '...
    'because ROIs are first clustered into distinct rows based vertical position '...
    'and are then sorted from left to right within the same row (tip: increase '...
    'this value to cluster ROIs that are more vertically separated into the same row. '...
    'Decrease this value to make vertical clustering more stringent).'];

closing=['See Manual for additional tips and details.'];
message={spc item1 spc item2 spc item3 spc item4 spc item5 spc closing};

% Display info
Opt.Interpreter='tex';
Opt.WindowStyle='normal';
waitfor(msgbox(message,msg_title,'none',Opt));






%*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*%
%*-*-*-*-*-*-*-*-*-*-* GUI OBJECT CREATION *-*-*-*-*-*-*-*-*-*-*-*-*-*-*%
%*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*%




% --- Executes during object creation, after setting all properties.
function edit_dist_thresh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_dist_thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edit_vignette_weight_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_vignette_weight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edit_vignette_sigma_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_vignette_sigma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edit_target_rate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit29 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function edit_speed_thresh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_speed_thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit_area_min_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_area_min (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function edit_area_max_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_area_max (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in speed_thresh_radiobutton.
function speed_thresh_radiobutton_Callback(hObject, eventdata, handles)
% hObject    handle to speed_thresh_radiobutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on button press in distance_thresh_radiobutton.
function distance_thresh_radiobutton_Callback(hObject, eventdata, handles)
% hObject    handle to distance_thresh_radiobutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of distance_thresh_radiobutton



% --- Executes on button press in area_radiobutton.
function area_radiobutton_Callback(hObject, eventdata, handles)
% hObject    handle to area_radiobutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of area_radiobutton


% --- Executes on selection change in sort_mode_popupmenu.
function sort_mode_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to sort_mode_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

gui_fig = handles.track_fig.UserData.gui_handles.gui_fig;

gui_fig.UserData.sort_mode = hObject.String{hObject.Value};
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function sort_mode_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sort_mode_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_ROI_cluster_tolerance_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ROI_cluster_tolerance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

gui_fig = handles.track_fig.UserData.gui_handles.gui_fig;

gui_fig.UserData.ROI_tol = str2num(get(hObject,'string'));
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_ROI_cluster_tolerance_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ROI_cluster_tolerance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in roi_mode_popupmenu.
function roi_mode_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to roi_mode_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

gui_fig = handles.track_fig.UserData.gui_handles.gui_fig;

gui_fig.UserData.ROI_mode = hObject.String{hObject.Value};
switch gui_fig.UserData.ROI_mode
    case 'auto'
        handles.sort_mode_popupmenu.Enable = 'on';
    case 'grid'
        handles.sort_mode_popupmenu.Enable = 'off';
        activemode = find(strcmp('bounds',handles.sort_mode_popupmenu.String));
        handles.sort_mode_popupmenu.Value = activemode;
end
guidata(hObject,handles);




% --- Executes during object creation, after setting all properties.
function roi_mode_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to roi_mode_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
