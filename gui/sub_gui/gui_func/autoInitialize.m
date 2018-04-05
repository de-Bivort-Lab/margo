function [trackDat,expmt] = autoInitialize(trackDat,expmt,gui_handles)


%% house-keeping intialization - executes even with initialization flag set OFF

% reset the handles state of the gui
%set(gui_handles.on_objs,'Enable','on');
%set(gui_handles.off_objs,'Enable','off');

% Initialize infrared and white illuminators
expmt.COM = writeInfraredWhitePanel(expmt.COM,1,expmt.light.infrared);
expmt.COM = writeInfraredWhitePanel(expmt.COM,0,expmt.light.white);

% clear any objects drawn to gui window
clean_gui(gui_handles.axes_handle);

% set colormap and enable display control
colormap('gray');
set(gui_handles.display_menu.Children,'Checked','off')
set(gui_handles.display_menu.Children,'Enable','on')
gui_handles.display_raw_menu.Checked = 'on';
gui_handles.display_menu.UserData = 1;

if strcmp(expmt.source,'camera') && ~isvalid(expmt.camInfo.vid)
    expmt = getVideoInput(expmt,gui_handles);
end

if ~expmt.Initialize
    return
end

%% estimate num data entries

nDataPoints = expmt.parameters.duration * ...
    expmt.parameters.target_rate * 3600 * length(expmt.ROI.centers);
if nDataPoints > 1E7
    msg = {'WARNING: high estimated number of data points';...
        ['ROIs x Target Rate x Duration = ' num2str(nDataPoints,2)];...
        'consider lowering acquisition rate to reduce file size'};
    gui_notify(msg,gui_handles.disp_note);
end

%% update de-bivort monitor server

if isfield(gui_handles,'deviceID')
    
    webop = weboptions('Timeout',0.65);
    status=true;
    try
        minstr = num2str(round(expmt.parameters.duration * 60));
        minstr = [repmat('0',1,4-length(minstr)) minstr];
        webread(['http://lab.debivort.org/mu.php?id=' gui_handles.deviceID '&st=1' minstr],webop);
    catch
        status = false;
    end
    if ~status
        gui_notify('unable to connect to http://lab.debivort.org',gui_handles.disp_note);
    end
end


%% Initialize tracking variables

trackDat.Centroid = single(expmt.ROI.centers);              % last known centroid of the object in each ROI
trackDat.tStamp = ...
    single(zeros(size(expmt.ROI.centers(:,1),1),1));        % time stamps of centroid updates
trackDat.t = 0;                                             % time elapsed, initialize to zero
trackDat.ct = 0;                                            % frame count
trackDat.drop_ct = zeros(size(expmt.ROI.centers(:,1),1),1); % number of frames dropped for each obj
trackDat.ref = expmt.ref;                                   % referencing properties
trackDat.px_dist = zeros(10,1);                             % distribution of pixels over threshold  
trackDat.pix_dev = zeros(10,1);                             % stdev of pixels over threshold
trackDat.lastFrame = false;

cam_center = repmat(fliplr(size(expmt.ref)./2),size(expmt.ROI.centers));
expmt.ROI.cam_dist = sqrt((expmt.ROI.centers(:,1)-cam_center(:,1)).^2 + ...
    (expmt.ROI.centers(:,2)-cam_center(:,2)).^2);

%% Initialize labels, file paths, and files for tracked fields

expmt.date = datestr(clock,'mm-dd-yyyy-HH-MM-SS_');         % get date string
expmt.labels_table = labelMaker(expmt);                           % convert labels cell into table format

% Query label fields and set label for file
lab_fields = expmt.labels_table.Properties.VariableNames;
expmt.fLabel = [expmt.date '_' expmt.Name];
for i = 1:length(lab_fields)
    switch lab_fields{i}
        case 'Strain'
            expmt.(lab_fields{i}) = expmt.labels_table{1,i}{:};
            expmt.fLabel = [expmt.fLabel '_' expmt.labels_table{1,i}{:}];
        case 'Sex'
            expmt.(lab_fields{i}) = expmt.labels_table{1,i}{:};
            expmt.fLabel = [expmt.fLabel '_' expmt.labels_table{1,i}{:}];
        case 'Treatment'
            expmt.(lab_fields{i}) = expmt.labels_table{1,i}{:};
            expmt.fLabel = [expmt.fLabel '_' expmt.labels_table{1,i}{:}];
        case 'Day'
            expmt.(lab_fields{i}) = expmt.labels_table{1,i};
            expmt.fLabel = [expmt.fLabel '_Day' num2str(expmt.labels_table{1,i})];
        case 'ID'
            ids = expmt.labels_table{:,i};
            expmt.fLabel = [expmt.fLabel '_' num2str(ids(1)) '-' num2str(ids(end))];
    end
end

% make a new directory for the files
expmt.fdir = [expmt.fpath '/' expmt.fLabel '/'];
mkdir(expmt.fdir);
expmt.rawdir = [expmt.fpath '/' expmt.fLabel '/raw_data/'];
mkdir(expmt.rawdir);

% generate file ID for files to write
for i = 1:length(trackDat.fields)                           
    expmt.(trackDat.fields{i}).path = ...                   % initialize path for new file    
        [expmt.rawdir expmt.fLabel '_' trackDat.fields{i} '.bin'];
    expmt.(trackDat.fields{i}).fID = ...
        fopen(expmt.(trackDat.fields{i}).path,'w');         % open fileID with write permission
end

% save current parameters to .mat file prior to experiment
params = fieldnames(gui_handles.gui_fig.UserData);
for i = 1:length(params)
    expmt.parameters.(params{i}) = gui_handles.gui_fig.UserData.(params{i});
end
save([expmt.fdir expmt.fLabel '.mat'],'expmt');


%% Setup the camera and/or video object

expmt = getVideoInput(expmt,gui_handles);

% initialize video recording if enabled
if strcmp(expmt.source,'camera') && strcmp(gui_handles.record_video_menu.Checked,'on')
    [trackDat,expmt] = initializeVidRecording(trackDat,expmt,gui_handles);
else
   gui_handles.record_video_menu.Checked = 'off'; 
end

expmt.Initialize = false;

% start the timer for the experiment
tic;
gui_notify('tracking initialized',gui_handles.disp_note);