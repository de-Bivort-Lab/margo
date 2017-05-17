function expmt = analyze_ledymaze(expmt, varargin)
%
% This function provides a sample analysis function to run after the
% sample bare-bones template 'experimental_template.m'. It takes the
% experimental master data struct (expmt) as an input, processes the data
% to extract features and store them to file. This sample also shows how to
% automatically zip the raw data files after analysis to reduce file size.

%% Parse inputs, read data from hard disk, format in master struct, process centroid data

[expmt,~,meta] = autoDataProcess(expmt,varargin{:});

clearvars -except expmt trackProps meta

%% Find index of first turn for each fly and discard to eliminate tracking artifacts

turn_idx = ~isnan(expmt.Turns.data);

for i=1:expmt.nTracks;
    col = find(turn_idx(i,:),1);
    expmt.Turns.data(i,col)=NaN;
end

%% Calculate turn probability
expmt.Turns.n = sum(turn_idx)-1;
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
    tSeq = expmt.Turns.data(~isnan(expmt.Turns.data(:,i)),i);
    tSeq=diff(tSeq);
    if expmt.ROI.orientation(i)
        expmt.Turns.seqence(1:length(tSeq),i)=tSeq==1|tSeq==-2;
    elseif ~expmt.ROI.orientation(i)
        expmt.Turns.seqence(1:length(tSeq),i)=tSeq==-1|tSeq==2;
    end
end

% Calculate right turn probability from tSeq
expmt.Turns.rBias = nansum(expmt.Turns.seqence)./nansum(~isnan(expmt.Turns.seqence));

if isfield(meta,'handles')
    gui_notify('processing complete',meta.handles.disp_note);
end


%% Calculate light choice probability

expmt.LightChoice.n = sum(~isnan(expmt.LightChoice.data));
expmt.LightChoice.pBias = sum(expmt.LightChoice.data==1)./expmt.LightChoice.n;
expmt.LightChoice.active = expmt.LightChoice.n > 40;

% bootstrap resample data
[expmt.LightChoice.bs, f] = bootstrap_ledymaze(expmt,200);

fname = [expmt.figdir expmt.date '_bs_light'];
if ~isempty(expmt.figdir) && meta.save
    hgsave(f,fname);
    close(f);
end


%% Create histogram plots of turn bias and light choice probability

if isfield(meta,'plot') && meta.plot
    
    inc=0.05;
    bins=-inc/2:inc:1+inc/2;   % Bins centered from 0 to 1 

    c=histc(expmt.Turns.rBias(expmt.Turns.n>40),bins); % turn histogram
    mad(expmt.Turns.rBias(expmt.Turns.n>40))           % MAD of right turn prob
    c=c./(sum(c));
    c(end)=[];
    
    f=figure();
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
    if isfield(expmt,'Strain')
        strain=expmt.Strain;
    else
        strain = '';
    end
    if isfield(expmt,'Treatment')
        treatment=expmt.Treatment;
    else
        treatment = '';
    end

    legendLabel(1)={['Turn Choice Probability: ' strain ' ' treatment ...
        ' (u=' num2str(mean(expmt.Turns.rBias(expmt.Turns.n>40)))...
        ', n=' num2str(sum(expmt.Turns.n>40)) ')']};
    legendLabel(2)={['Light Choice Probability: ' strain ' ' treatment ...
        ' (u=' num2str(mean(expmt.LightChoice.pBias(expmt.Turns.n>40)))...
        ', n=' num2str(sum(expmt.Turns.n>40)) ')']};
    legend(legendLabel);
    
    fname = [expmt.figdir expmt.date '_hist_photo'];
    if ~isempty(expmt.figdir) && meta.save
        hgsave(f,fname);
        close(f);
    end

end


clearvars -except expmt meta

%% Clean up files and wrap up analysis

autoFinishAnalysis(expmt,meta);