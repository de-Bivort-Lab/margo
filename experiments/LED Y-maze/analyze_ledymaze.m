function expmt = analyze_ledymaze(expmt, varargin)
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
    gui_notify('importing and processing data...',handles.disp_note);
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

if exist('handles','var')
    gui_notify('processing complete',handles.disp_note);
end


%% Calculate light choice probability

expmt.LightChoice.n = sum(~isnan(expmt.LightChoice.data),2);
expmt.LightChoice.pBias = sum(expmt.LightChoice.data==1,2)./expmt.LightChoice.n;


%% Create histogram plots of turn bias and light choice probability

if exist('plot_mode','var') && strcmp(plot_mode,'plot')
    
    inc=0.05;
    bins=-inc/2:inc:1+inc/2;   % Bins centered from 0 to 1 

    c=histc(expmt.Turns.rBias(expmt.Turns.n>40),bins); % turn histogram
    mad(expmt.Turns.rBias(expmt.Turns.n>40))           % MAD of right turn prob
    c=c./(sum(c));
    c(end)=[];
    plot(c,'Linewidth',2);

    hold on
    c=histc(expmt.LightChoice.pBias(expmt.Turns.n>40),bins); % histogram
    mad(expmt.LightChoice.pBias(expmt.Turns.n>40))           % MAD of light choice prob
    c=c./(sum(c));
    c(end)=[];
    plot(c,'Linewidth',2);
    set(gca,'Xtick',(1:length(c)),'XtickLabel',0:inc:1);
    axis([0 length(bins) 0 max(c)+0.05]);

    % Generate legend labels
    if iscellstr(expmt.labels{1,1})
        strain=expmt.labels{1,1}{:};
    end
    if iscellstr(expmt.labels{1,3})
        treatment=expmt.labels{1,3}{:};
    end

    legendLabel(1)={['Turn Choice Probability: ' strain ' ' treatment ...
        ' (u=' num2str(mean(expmt.Turns.rBias(expmt.Turns.n>40)))...
        ', n=' num2str(sum(expmt.Turns.n>40)) ')']};
    legendLabel(2)={['Light Choice Probability: ' strain ' ' treatment ...
        ' (u=' num2str(mean(expmt.LightChoice.pBias(expmt.Turns.n>40)))...
        ', n=' num2str(sum(expmt.Turns.n>40)) ')']};
    legend(legendLabel);
    shg
end


clearvars -except handles expmt plot_mode varargin

%% Clean up files and wrap up analysis

autoFinishAnalysis(expmt,varargin);