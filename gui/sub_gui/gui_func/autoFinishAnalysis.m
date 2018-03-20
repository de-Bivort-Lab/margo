function autoFinishAnalysis(expmt,options)


%% Clean up the workspace

% temporarily remove vid obj/source from struct for saving
if isfield(expmt.camInfo,'vid')
    expmt.camInfo = rmfield(expmt.camInfo,'src');
    expmt.camInfo = rmfield(expmt.camInfo,'vid');
end

% re-save updated expmt data struct to file
if options.save
    save([expmt.fdir expmt.fLabel '.mat'],'expmt');
    if isfield(options,'handles')
        gui_notify('processed data saved to file',options.handles.disp_note)
    end
end

%% Zip raw data files to reduce file size and clean up directory

open_IDs = fopen('all');
for i = 1:length(open_IDs)
    fclose(open_IDs(i));
end
%{
if isfield(options,'handles')
    gui_notify('zipping raw data',options.handles.disp_note)
else
    disp('zipping raw data... may take a few minutes');
end

flist = [];
for i = 1:length(expmt.fields)
    f = expmt.fields{i};
    if ~strcmp(f,'VideoData')
        path = expmt.(f).path;
        if exist(path,'file')
            flist = [flist;{path}];
        end
    end
end

if ~isempty(flist)
    zip([expmt.fdir expmt.fLabel '_RawData.zip'],flist);
end

for i = 1:length(flist)
    delete(flist{i});
end
%}
%% Display command to load data struct into workspace

disp('Execute the following command to load your data into the workspace:')
disp(['load(',char(39),strcat(expmt.fdir,expmt.fLabel,'.mat'),char(39),');'])

%% Set MATLAB priority to Above Normal via Windows Comman
OS = computer;
switch OS
    case 'PCWIN64'
        cmd_str = 'wmic process where name="MATLAB.exe" CALL setpriority 32768';
        [~,~] = system(cmd_str);
end


