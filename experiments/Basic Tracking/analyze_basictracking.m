function expmt = analyze_basictracking(expmt,varargin)
%
% This function provides a sample analysis function to run after the
% sample bare-bones template 'experimental_template.m'. It takes the
% experimental master data struct (expmt) as an input, processes the data
% to extract features and store them to file. This sample also shows how to
% automatically zip the raw data files after analysis to reduce file size.

%% parse inputs

for i = 1:length(varargin)
    if ischar(varargin{i})
        plot_mode = varargin{i};
    else
        handles = varargin{i};
    end
end

%% Pull in ASCII data, format into vectors/matrices

if exist('handles','var')
    gui_notify('importing and processing data...',handles.disp_note)
end

expmt.nTracks = size(expmt.ROI.centers,1);

% read in data files sequentially and store in data struct
for i = 1:length(expmt.fields)
    
    % get subfields
    f = expmt.fields{i};
    path = expmt.(f).path;
    dim = expmt.(f).dim;
    prcn = expmt.(f).precision;
    
    % read .bin file
    expmt.(f).fID = fopen(path,'r');

    
    % if field is centroid, reshape to (frames x dim x nTracks)
    if strcmp(f,'Centroid')
        expmt.(f).data = fread(expmt.(f).fID,prcn);
        expmt.(f).data = reshape(expmt.(f).data,dim(1),dim(2),expmt.nFrames);
        expmt.(f).data = permute(expmt.(f).data,[3 2 1]);
        expmt.drop_ct = expmt.drop_ct ./ expmt.nFrames;
    end
    
    % if area, orientation, or speed, reshape to (frames x nTracks)
    if any(strmatch(f,{'Area' 'Orientation' 'Speed'}))
        expmt.(f).data = fread(expmt.(f).fID,prcn);
        expmt.(f).data = reshape(expmt.(f).data,expmt.nTracks,expmt.nFrames)';
    end
    
    if strcmp(f,'Time')
        expmt.(f).data = fread(expmt.(f).fID,prcn);
    end
    fclose(expmt.(f).fID);
    
end

% In the example, the centroid is being processed to extract circling
% handedness for each track. Resulting handedness scores are stored in
% the master data struct.
[expmt,trackProps] = processCentroid(expmt);

if exist('handles','var')
    gui_notify('processing complete',handles.disp_note)
end

clearvars -except handles expmt

%% Clean up the workspace
expmt.strain(ismember(expmt.strain,' ')) = [];
save([expmt.fdir expmt.fLabel '.mat'],'expmt');

if exist('handles','var')
    gui_notify('processed data saved to file',handles.disp_note)
end

%% Generate plots

if exist('plot_mode','var') && strcmp(plot_mode,'plot')
    if exist('handles','var')
        gui_notify('generating plots',handles.disp_note)
    end
    plotArenaTraces(expmt);
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

zip([expmt.fdir expmt.date expmt.Name '_' expmt.strain '_' expmt.treatment '_RawData.zip'],flist);

for i = 1:length(flist)
    delete(flist{i});
end

%% Display command to load data struct into workspace

disp('Execute the following command to load your data into the workspace:')
disp(['load(',char(39),strcat(expmt.fdir,expmt.date,expmt.Name,'_',expmt.strain,'.mat'),char(39),');'])

%% Set MATLAB priority to Above Normal via Windows Command Line
cmd_str = 'wmic process where name="MATLAB.exe" CALL setpriority 32768';
[~,~] = system(cmd_str);

clearvars -except handles