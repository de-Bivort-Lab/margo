function autoFinishAnalysis(expmt,options)


%% Clean up the workspace

% temporarily remove vid obj/source from struct for saving
if isfield(expmt.hardware.cam,'vid')
    expmt.hardware.cam = rmfield(expmt.hardware.cam,'src');
    expmt.hardware.cam = rmfield(expmt.hardware.cam,'vid');
end

expmt.data = orderfields(expmt.data);
expmt.meta = orderfields(expmt.meta);
expmt.parameters = orderfields(expmt.parameters);

% re-save updated expmt data struct to file
if options.save
    save([expmt.meta.path.dir expmt.meta.path.name '.mat'],'expmt','-v7.3');
    if isfield(options,'handles')
        gui_notify('processed data saved to file',options.handles.disp_note)
    end
end

%% Close open files

open_IDs = fopen('all');
for i = 1:length(open_IDs)
    fclose(open_IDs(i));
end

%% Display command to load data struct into workspace

disp('Execute the following command to load your data into the workspace:')
disp(['load(',char(39),strcat(expmt.meta.path.dir,expmt.meta.path.name,'.mat'),char(39),');'])

%% Set MATLAB priority to Above Normal via Windows Command line
OS = computer;
switch OS
    case 'PCWIN64'
        cmd_str = 'wmic process where name="MATLAB.exe" CALL setpriority 32768';
        [~,~] = system(cmd_str);
end



