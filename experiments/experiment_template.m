function [expmt] = experiment_template(expmt,gui_handles)
%
% This is a blank experimental template to serve as a framework for new
% custom experiments. The function takes the master experiment struct
% (expmt) and the handles to the gui (gui_handles) as inputs and outputs
% the data assigned to out. In this example, object centroid, pixel area,
% and the time of each frame are output to file.

%% Initialization: Get handles and set default preferences

% clear memory
clearvars -except gui_handles expmt

% set MATLAB to highest priority via windows cmd line
cmd_str = 'wmic process where name="MATLAB.exe" CALL setpriority 128';
[~,~] = system(cmd_str);

% get handles
gui_fig = gui_handles.gui_fig;                            % gui figure handle
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','image');   % image handle

% clear any objects drawn to gui window
centroid_markers = findobj(gui_handles.axes_handle,'-depth',3,'Type','line');
delete(centroid_markers);
rect_handles = findobj(gui_handles.axes_handle,'-depth',3,'Type','rectangle');
delete(rect_handles);
text_handles = findobj(gui_handles.axes_handle,'-depth',3,'Type','text');
delete(text_handles);

% set colormap and enable display control
colormap('gray');
set(gui_handles.display_raw_menu,'Enable','on');
set(gui_handles.display_difference_menu,'Enable','on');
set(gui_handles.display_threshold_menu,'Enable','on');
set(gui_handles.display_reference_menu,'checked','on');
set(gui_handles.display_none_menu,'Enable','on');


%% Experimental Setup

% Initialize experiment parameters
ref_stack = repmat(expmt.ref, 1, 1, gui_handles.edit_ref_depth.Value);  % initialize the reference stack

% Initialize tracking variables
trackDat.lastCen=expmt.ROI.centers;                         % last known centroid of the object in each ROI 
trackDat.fields={'Centroid';'Area'};                        % properties of the tracked objects to be recorded
trackDat.tStamp = zeros(size(expmt.ROI.centers(:,1),1),1);  % time stamps of centroid updates
trackDat.t = 0;                                             % time elapsed, initialize to zero
trackDat.ct = 0;                                            % frame count
trackDat.t_ref = 0;                                         % time elapsed since last reference image
trackDat.ref_ct = 0;                                        % num references taken
trackDat.px_dist = zeros(10,1);                             % distribution of pixels over threshold  
trackDat.pix_dev = zeros(10,1);                             % stdev of pixels over threshold

% Initialize labels, file paths, and files for tracked fields
expmt.date = datestr(clock,'mm-dd-yyyy-HH-MM-SS_');
expmt.labels = cell2table(labelMaker(expmt.labels),'VariableNames',{'Strain' 'Sex' 'Treatment' 'ID' 'Day' 'Box' 'Tray' 'Comments'});
expmt.strain=expmt.labels{1,1}{:};
expmt.treatment=expmt.labels{1,3}{:};

% make a new directory for the files
expmt.fdir = [expmt.fpath '\' expmt.date expmt.strain '_' expmt.treatment '\'];
mkdir(expmt.fdir);

for i = 1:length(trackDat.fields)
    fpath(i) = {[expmt.fdir expmt.date expmt.strain '_' expmt.treatment '_' trackDat.fields{i} '.dat']};
    dlmwrite(fpath{i},[]);      % create empty placeholder
end

% Note: manually add if you want to save additional fields (eg. time stamps)
fpath = [fpath {[expmt.fdir expmt.date expmt.strain '_' expmt.treatment '_' 'tStamps.dat']}];

% assign individual file paths and field names to the expmt data struct
expmt.fpath = fpath;
expmt.fields = [trackDat.fields {'tStamps'}];

% save current parameters to .mat file prior to experiment
params = fieldnames(gui_fig.UserData);
for i = 1:length(params)
    expmt.parameters.(params{i}) = gui_fig.UserData.(params{i});
end
save([expmt.fdir expmt.date expmt.strain '_' expmt.treatment '_' 'expmt.mat'],'expmt');

%% Initialize camera

if isfield(expmt.camInfo,'vid')
    if strcmp(expmt.camInfo.vid.Running,'off')
        start(expmt.camInfo.vid);
    end
else
    errordlg(['No camera object detected. Ensure camera is connected '...
        'and camera settings are confirmed.']);
end


%% Main Experimental Loop

tic
tPrev = toc;
hold on
hMark = plot(trackDat.lastCen(:,1),trackDat.lastCen(:,2),'ro');
hold off

while trackDat.t < gui_handles.edit_exp_duration.Value * 3600
    
        % update time stamps and frame rate
        [trackDat, tPrev] = updateTime(trackDat, tPrev, gui_handles);

        % get new image from camera
        trackDat.im=peekdata(expmt.camInfo.vid,1);
        if size(trackDat.im,3)>1
            trackDat.im=trackDat.im(:,:,2);
        end
        
        % track, sort to ROIs, and output optional fields to sorted fields,
        % and sample the number of pixels above the image threshold
        [trackDat, sorted_fields] = autoTrack(trackDat,expmt,gui_handles);


        % output data to .dat files
        for i = 1:length(expmt.fpath)
            switch i
                case 1
                    dlmwrite(expmt.fpath{i},trackDat.lastCen,'-append');
                case 2
                    dlmwrite(expmt.fpath{i},sorted_fields.Area,'-append');
                case 3
                    dlmwrite(expmt.fpath{i},trackDat.t,'-append');
            end
        end
        
        % update ref at the reference frequency or reset if noise thresh is exceeded
        [trackDat, ref_stack, expmt] = updateRef(trackDat, ref_stack, expmt, gui_handles);
        
        if gui_handles.display_menu.UserData ~= 5
            % update the display
            updateDisplay(trackDat, expmt, imh, gui_handles);

            % update centroid mark position
            hMark.XData = trackDat.lastCen(:,1);
            hMark.YData = trackDat.lastCen(:,2);
        end
        
        % update the gui
        drawnow
        
end

% store number of dropped frames for each object in master data struct
expmt.drop_ct = trackDat.drop_ct;

