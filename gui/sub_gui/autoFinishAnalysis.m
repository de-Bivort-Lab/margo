function autoFinishAnalysis(expmt,varargin)

%% parse inputs
varargin = varargin{1};

for i = 1:length(varargin)
    if ischar(varargin{i})
        plot_mode = varargin{i};
    else
        handles = varargin{i};
    end
end

%% Clean up the workspace

% temporarily remove vid obj/source from struct for saving
if isfield(expmt.camInfo,'vid')
    expmt.camInfo = rmfield(expmt.camInfo,'src');
    expmt.camInfo = rmfield(expmt.camInfo,'vid');
end

% re-save updated expmt data struct to file
save([expmt.fdir expmt.fLabel '.mat'],'expmt');

if exist('handles','var')
    gui_notify('processed data saved to file',handles.disp_note)
end

%% Zip raw data files to reduce file size and clean up directory

open_IDs = fopen('all');
for i = 1:length(open_IDs)
    fclose(open_IDs(i));
end

if exist('handles','var')
    gui_notify('zipping raw data',handles.disp_note)
end

flist = [];
for i = 1:length(expmt.fields)
    f = expmt.fields{i};
    if ~strcmp(f,'VideoData')
        path = expmt.(f).path;
        flist = [flist;{path}];
    end
end

zip([expmt.fdir expmt.fLabel '_RawData.zip'],flist);

for i = 1:length(flist)
    delete(flist{i});
end

%% Display command to load data struct into workspace

disp('Execute the following command to load your data into the workspace:')
disp(['load(',char(39),strcat(expmt.fdir,expmt.fLabel,'.mat'),char(39),');'])

%% Set MATLAB priority to Above Normal via Windows Command Line
cmd_str = 'wmic process where name="MATLAB.exe" CALL setpriority 32768';
[~,~] = system(cmd_str);
