function autoFinishAnalysis(expmt,options)


%% Clean up the workspace

% temporarily remove vid obj/source from struct for saving
if isfield(expmt.camInfo,'vid')
    expmt.camInfo = rmfield(expmt.camInfo,'src');
    expmt.camInfo = rmfield(expmt.camInfo,'vid');
end

expmt = orderfields(expmt);

% re-save updated expmt data struct to file
if options.save
    save([expmt.fdir expmt.fLabel '.mat'],'expmt','-v7.3');
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
disp(['load(',char(39),strcat(expmt.fdir,expmt.fLabel,'.mat'),char(39),');'])

%% Set MATLAB priority to Above Normal via Windows Command line
OS = computer;
switch OS
    case 'PCWIN64'
        cmd_str = 'wmic process where name="MATLAB.exe" CALL setpriority 32768';
        [~,~] = system(cmd_str);
end



