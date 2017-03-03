function analyze_ymaze(expmt,handles,plot_mode)
%
% This function provides a sample analysis function to run after the
% sample bare-bones template 'experimental_template.m'. It takes the
% experimental master data struct (expmt) as an input, processes the data
% to extract features and store them to file. This sample also shows how to
% automatically zip the raw data files after analysis to reduce file size.

%% Pull in ASCII data, format into vectors/matrices

gui_notify('importing and processing data...',handles.disp_note)

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
        expmt.(f).data = reshape(expmt.(f).data,dim(1),dim(2),length(expmt.(f).data)/(prod(dim)));
        expmt.(f).data = permute(expmt.(f).data,[3 2 1]);
        expmt.drop_ct = expmt.drop_ct ./ expmt.nFrames;
    
    % if area, orientation, or speed, reshape to (frames x nTracks)
    elseif any(strmatch(f,{'Area' 'Orientation' 'Speed'}))
        expmt.(f).data = fread(expmt.(f).fID,prcn);
        expmt.(f).data = reshape(expmt.(f).data,expmt.nTracks,length(expmt.(f).data)/(prod(dim)))';
    
    elseif strcmp(f,'Time')
        expmt.(f).data = fread(expmt.(f).fID,prcn);
        
    elseif ~strcmp(f,'VideoData') || ~strcmp(f,'VideoIndex')
        expmt.(f).data = fread(expmt.(f).fID,[expmt.(f).dim(1) expmt.nFrames],prcn);
    end
    
    fclose(expmt.(f).fID);
    
end

%% Find index of first turn for each fly and discard to eliminate tracking artifacts

turn_idx = ~isnan(expmt.Turns.data);

for i=1:expmt.nTracks;
    col = find(turn_idx(i,:),1);
    expmt.Turns.data(i,col)=NaN;
end

%% Calculate turn probability
expmt.Turns.n = sum(turn_idx,2)-1;
expmt.Turns.seqence = NaN(max(expmt.Turns.n),expmt.nTracks);

%{
Start by converting arm number turn sequence into compressed right turn
sequence by taking difference between subsequent maze arms. For either orientation 
of a maze, arms are 1 to 3 left to right. For example, for a rightside-up Y, 
right turns would be 1-3=-2, 3-2=1, and 2-1=1. The opposite is true for the
opposite orientation of a maze. In the output, tSeq, Right turns = 1, Left
turns = 0.
%}
for i=1:expmt.nTracks
    tSeq = expmt.Turns.data(i,~isnan(expmt.Turns.data(i,:)));
    tSeq=diff(tSeq);
    if expmt.ROI.orientation(i)
        expmt.Turns.seqence(1:length(tSeq),i)=tSeq==1|tSeq==-2;
    elseif ~expmt.ROI.orientation(i)
        expmt.Turns.seqence(1:length(tSeq),i)=tSeq==-1|tSeq==2;
    end
end

% Calculate right turn probability from tSeq
expmt.Turns.rBias = nansum(expmt.Turns.seqence)./nansum(~isnan(expmt.Turns.seqence));

gui_notify('processing complete',handles.disp_note)

clearvars -except handles expmt

%% Clean up the workspace
expmt.strain(ismember(expmt.strain,' ')) = [];
save([expmt.fdir expmt.date expmt.Name '_' expmt.strain '_' expmt.treatment '.mat'],'expmt');
gui_notify('processed data saved to file',handles.disp_note)
%% Generate plots

if strcmp(plot_mode,'plot')
    gui_notify('generating plots',handles.disp_note)
    plotArenaTraces(expmt);
end

%% Zip raw data files to reduce file size and clean up directory

open_IDs = fopen('all');
for i = 1:length(open_IDs)
    fclose(open_IDs(i));
end

gui_notify('zipping raw data',handles.disp_note)
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