function analysis_template(expmt,plot_mode)
%
% This function provides a sample analysis function to run after the
% sample bare-bones template 'experimental_template.m'. It takes the
% experimental master data struct (expmt) as an input, processes the data
% to extract features and store them to file. This sample also shows how to
% automatically zip the raw data files after analysis to reduce file size.

%% Pull in ASCII data, format into vectors/matrices
disp('Experiment Complete')
disp('Importing and processing data - may take a few minutes...')

expmt.Name = 'Template';
expmt.nTracks = size(expmt.ROI.centers,1);

% read in data files sequentially and store in data struct
for i = 1:length(expmt.fields)
    
    % read .dat file
    expmt.(expmt.fields{i}) = dlmread(expmt.fpath{i});
    
    % if field is centroid, reshape to (frames x dim x nTracks)
    if strcmp(expmt.fields{i},'Centroid')
        x = expmt.Centroid(:,1);
        x = reshape(x',expmt.nTracks,length(x)/expmt.nTracks)';
        y = expmt.Centroid(:,2);
        y = reshape(y',expmt.nTracks,length(y)/expmt.nTracks)';
        rmfield(expmt,'Centroid');
        expmt.Centroid = single(NaN(size(x,1),2,size(x,2)));
        expmt.Centroid(:,1,:) = x;
        expmt.Centroid(:,2,:) = y;
        clearvars x y
        expmt.drop_ct = expmt.drop_ct ./ size(expmt.Centroid,1);
    end
    
    % if area, orientation, or speed, reshape to (frames x nTracks)
    if any(strmatch(expmt.fields{i},{'Area' 'Orientation' 'Speed'}))
        expmt.(expmt.fields{i}) = ...
            reshape(expmt.(expmt.fields{i}),expmt.nTracks,length(expmt.(expmt.fields{i}))/expmt.nTracks)';
    end
    
end

% In the example, the centroid is being processed to extract circling
% handedness for each track. Resulting handedness scores are stored in
% the master data struct.
[expmt,trackProps] = processCentroid(expmt);
disp('Processing Complete');

%% Generate plots

if strcmp(plot_mode,'plot')
    disp('Generating plots...')
    plotArenaTraces(expmt);
end

%% Clean up the workspace
disp('Saving processed data...')
expmt.strain(ismember(expmt.strain,' ')) = [];
save([expmt.fdir expmt.date expmt.Name '_' expmt.strain '_' expmt.treatment '.mat'],'expmt');

%% Zip raw data files to reduce file size and clean up directory

disp('Zipping raw data files...')
zip([expmt.fdir expmt.date expmt.Name '_' expmt.strain '_' expmt.treatment '_RawData.zip'],expmt.fpath);

for i = 1:length(expmt.fpath)
    delete(expmt.fpath{i});
end

%% Display command to load data struct into workspace

disp('Execute the following command to load your data into the workspace:')
disp(['load(',char(39),strcat(expmt.fdir,expmt.date,expmt.Name,'_',expmt.strain,'.mat'),char(39),');'])

%% Set MATLAB priority to Above Normal via Windows Command Line
cmd_str = 'wmic process where name="MATLAB.exe" CALL setpriority 32768';
[~,~] = system(cmd_str);

clearvars -except handles