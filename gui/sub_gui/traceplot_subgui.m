function varargout = traceplot_subgui(varargin)
% TRACEPLOT_SUBGUI MATLAB code for traceplot_subgui.fig
%      TRACEPLOT_SUBGUI, by itself, creates a new TRACEPLOT_SUBGUI or raises the existing
%      singleton*.
%
%      H = TRACEPLOT_SUBGUI returns the handle to a new TRACEPLOT_SUBGUI or the handle to
%      the existing singleton*.
%
%      TRACEPLOT_SUBGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRACEPLOT_SUBGUI.M with the given input arguments.
%
%      TRACEPLOT_SUBGUI('Property','Value',...) creates a new TRACEPLOT_SUBGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before traceplot_subgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to traceplot_subgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help traceplot_subgui

% Last Modified by GUIDE v2.5 18-Apr-2018 16:04:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @traceplot_subgui_OpeningFcn, ...
                   'gui_OutputFcn',  @traceplot_subgui_OutputFcn, ...
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


% --- Executes just before traceplot_subgui is made visible.
function traceplot_subgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to traceplot_subgui (see VARARGIN)

% get expmt struct and generate vector mask
expmt = varargin{1};
handles.trace_fig.UserData.expmt = expmt;
[~,p] = memory;
mem = p.PhysicalMemory.Available;
n = mem/(8*expmt.meta.num_frames*2*6) * expmt.meta.num_frames * 0.1;
if expmt.meta.num_frames > n
    frame_rate = median(expmt.data.time.raw);
    handles.trace_fig.UserData.idx = 1:round(frame_rate):expmt.meta.num_frames;
    if numel(handles.trace_fig.UserData.idx) > n
        handles.trace_fig.UserData.idx = floor(linspace(1,expmt.meta.num_frames,n));
    end
else
    handles.trace_fig.UserData.idx = 1:expmt.meta.num_frames;
end

% set slider min-max values
for i=1:6
    tag = ['roi_num_slider' num2str(i)];
    handles.(tag).Min = 1;
    handles.(tag).Max = expmt.ROI.n;
    handles.(tag).SliderStep(1) = 1/(expmt.ROI.n-1);
    if i <= expmt.ROI.n
        dispTrace(i,i,handles);
    end
end


% Choose default command line output for traceplot_subgui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes traceplot_subgui wait for user response (see UIRESUME)
% uiwait(handles.trace_fig);


% --- Outputs from this function are returned to the command line.
function varargout = traceplot_subgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
%{
while ishghandle(hObject)
    pause(0.001);
end
%}
varargout{1} = handles.output;


% --- Executes on slider movement.
function roi_num_slider_Callback(hObject, eventdata, handles)
% hObject    handle to roi_num_slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% query plot number
plot_num = str2double(hObject.Tag(end));

% update edit box display
hObject.Value = round(hObject.Value);
handles.(['edit_ROI_num' num2str(plot_num)]).String = num2str(hObject.Value);

% update plot
dispTrace(hObject.Value,plot_num,handles);

guidata(hObject,handles);



% --- Executes during object creation, after setting all properties.
function roi_num_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to roi_num_slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function edit_ROI_num_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ROI_num1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% query plot and ROI numbers
plot_num = str2double(hObject.Tag(end));
hObject.Value = str2double(hObject.String);
handles.(['roi_num_slider' num2str(plot_num)]).Value = hObject.Value;

% update plot
dispTrace(hObject.Value,plot_num,handles);



% --- Executes during object creation, after setting all properties.
function edit_ROI_num_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ROI_num1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function dispTrace(idx,plot_num,handles)


ah = handles.(['pos_axes' num2str(plot_num)]);
lh = findobj(ah.Children,'Type','Line','-depth',1);
expmt = handles.trace_fig.UserData.expmt;
ii = handles.trace_fig.UserData.idx;
x = squeeze(expmt.data.centroid.raw(idx,1,ii));
y = squeeze(expmt.data.centroid.raw(idx,2,ii));
handles.(['roi_num_slider' num2str(plot_num)]).Value = idx;
handles.(['edit_ROI_num' num2str(plot_num)]).String = num2str(idx);

% update position plot
if ~isempty(lh)
    lh.XData = x;
    lh.YData = y;
    ah.XTick = [ah.XLim(1) mean(ah.XLim) ah.XLim(2)];
    ah.XTickLabel = [-1 0 1];
    ah.YTick = [ah.YLim(1) mean(ah.YLim) ah.YLim(2)];
    ah.YTickLabel = [-1 0 1];
    ylabel(ah,'Position','FontSize',12);
else
    ph=plot(ah,x(:),y(:),'k','LineWidth',0.5);
    axis(ah,'equal');
    ah.XTick = [ah.XLim(1) mean(ah.XLim) ah.XLim(2)];
    ah.XTickLabel = [-1 0 1];
    ah.YTick = [ah.YLim(1) mean(ah.YLim) ah.YLim(2)];
    ah.YTickLabel = [-1 0 1];
    ylabel(ah,'Position','FontSize',12);
end

% update speed plot
s = sqrt(diff(x).^2+diff(y).^2);
ah = handles.(['speed_axes' num2str(plot_num)]);
lh = findobj(ah.Children,'Type','Line','-depth',1);
if ~isempty(lh)
    lh.YData = s;
    ah.XTick = [];
    ah.XTickLabel = [];
    if max(s) > 0
        ah.YLim = [0 ceil(max(s))];
        ah.YTick = ah.YLim;
        ah.YTickLabel = ah.YLim;
    end
    ylabel(ah,'Spd','FontSize',12);
else
    ph=plot(ah,s(:),'k','LineWidth',0.75);
    ah.XTick = [];
    ah.XTickLabel = [];
    if max(s) > 0
        ah.YLim = [0 ceil(max(s))];
        ah.YTick = ah.YLim;
        ah.YTickLabel = ah.YLim;
    end
    ylabel(ah,'Spd','FontSize',12);
end

clear s x y

switch handles.roi_num_slider1.Value
    case 1
        handles.prev_pushbutton.Enable = 'off';
    case handles.roi_num_slider1.Max - 5
        handles.next_pushbutton.Enable = 'off';
    otherwise
        handles.prev_pushbutton.Enable = 'on';
        handles.next_pushbutton.Enable = 'on';
end


% --- Executes on button press in prev_pushbutton.
function prev_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to prev_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% query value of virst plot
start = handles.roi_num_slider1.Value;
min_idx = handles.roi_num_slider1.Min;
start = start-6;
if start < min_idx
    start = start + (min_idx - start);
end

for i = 1:6
    dispTrace(start+i-1,i,handles);
end


% --- Executes on button press in next_pushbutton.
function next_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to next_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB

% query value of virst plot
start = handles.roi_num_slider1.Value;
max_idx = handles.roi_num_slider1.Max;
start = start+6;
if start + 5 > max_idx
    start = start - (start + 5 - max_idx);
end

for i = 1:6
    dispTrace(start+i-1,i,handles);
end
