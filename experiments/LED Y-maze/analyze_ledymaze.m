function expmt = analyze_ledymaze(expmt, varargin)
%
% This function provides a sample analysis function to run after the
% sample bare-bones template 'experimental_template.m'. It takes the
% experimental master data struct (expmt) as an input, processes the data
% to extract features and store them to file. This sample also shows how to
% automatically zip the raw data files after analysis to reduce file size.

%% Parse inputs, read data from hard disk, format in master struct, process centroid data

[expmt,options] = autoDataProcess(expmt,varargin{:});

clearvars -except expmt options

%% Find index of first turn for each fly and discard to eliminate tracking artifacts

turn_idx = ~isnan(expmt.Turns.data);

for i=1:expmt.meta.num_traces
    col = find(turn_idx(i,:),1);
    expmt.Turns.data(i,col)=NaN;
end

%% Calculate turn probability
expmt.Turns.n = sum(turn_idx)-1;
expmt.Turns.sequence = NaN(max(expmt.Turns.n),expmt.meta.num_traces);
expmt.Turns.t = NaN(max(expmt.Turns.n),expmt.meta.num_traces);
expmt.LightChoice.sequence = NaN(max(expmt.Turns.n),expmt.meta.num_traces);

%{
Start by converting arm number turn sequence into compressed right turn
sequence by taking difference between subsequent maze arms. For either orientation 
of a maze, arms are 1 to 3 left to right. For example, for a rightside-up Y, 
right turns would be 1-3=-2, 3-2=1, and 2-1=1. The opposite is true for the
opposite orientation of a maze. In the output, tSeq, Right turns = 1, Left
turns = 0.
%}


tElapsed = cumsum(expmt.data.time.data);

for i=1:expmt.meta.num_traces
    
    idx = ~isnan(expmt.Turns.data(:,i));        % get turn indices
    expmt.Turns.t(1:length(tElapsed(idx)),i) = tElapsed(idx);         % record timestamps of turns
    
    % calculate turn sequence
    tSeq = expmt.Turns.data(idx,i);
    lSeq = expmt.LightChoice.data(idx,i);
    tSeq=diff(tSeq);  
    if expmt.meta.roi.orientation(i)
        expmt.Turns.sequence(1:length(tSeq),i)=tSeq==1|tSeq==-2;
    elseif ~expmt.meta.roi.orientation(i)
        expmt.Turns.sequence(1:length(tSeq),i)=tSeq==-1|tSeq==2;
    end
    
    expmt.LightChoice.sequence(1:length(lSeq),i) = lSeq;
    
end

% Calculate right turn probability from tSeq
expmt.Turns.rBias = nansum(expmt.Turns.sequence)./nansum(~isnan(expmt.Turns.sequence));

% Calculate clumpiness and switchiness
expmt.Turns.switchiness = NaN(expmt.meta.num_traces,1);
expmt.Turns.clumpiness = NaN(expmt.meta.num_traces,1);
for i = 1:expmt.meta.num_traces
    
    idx = ~isnan(expmt.Turns.sequence(:,i));
    s = expmt.Turns.sequence(idx,i);
    r = expmt.Turns.rBias(i);
    n = expmt.Turns.n(i);
    t = expmt.Turns.t(idx,i);
    iti = (t(2:end) - t(1:end-1));
    
    expmt.Turns.switchiness(i) = sum((s(1:end-1)+s(2:end))==1)/(2*r*(1-r)*n);
    expmt.Turns.clumpiness(i) = std(iti) / mean(iti);
    
end

expmt.Turns.active = expmt.Turns.n > 39;

if isfield(options,'handles')
    gui_notify('processing complete',options.handles.disp_note);
end


%% Calculate light choice probability

expmt.LightChoice.n = sum(~isnan(expmt.LightChoice.data));
expmt.LightChoice.pBias = sum(expmt.LightChoice.data==1)./expmt.LightChoice.n;
expmt.LightChoice.active = expmt.LightChoice.n > 39;
expmt.LightChoice.switchiness = NaN(expmt.meta.num_traces,1);

for i = 1:expmt.meta.num_traces
    
    idx = ~isnan(expmt.Turns.sequence(:,i));
    s = expmt.LightChoice.sequence(idx,i);
    r = expmt.LightChoice.pBias(i);
    n = expmt.LightChoice.n(i);
    t = expmt.Turns.t(idx,i);
    iti = (t(2:end) - t(1:end-1));
    
    expmt.LightChoice.switchiness(i) = sum((s(1:end-1)+s(2:end))==1)/(2*r*(1-r)*n);
    
end

expmt.LightChoice.active = expmt.LightChoice.n > 39;

% bootstrap resample data
if isfield(expmt.LightChoice,'active') && any(expmt.LightChoice.active)
    [expmt.LightChoice.bs, f] = bootstrap_ledymaze(expmt,200);


    fname = [expmt.figdir expmt.date '_bs_light'];
    if ~isempty(expmt.figdir) && options.save
        hgsave(f,fname);
        close(f);
    end

end

%% Create histogram plots of turn bias and light choice probability

if isfield(expmt.LightChoice,'active') && any(expmt.LightChoice.active)
    
inc=0.05;
bins=-inc/2:inc:1+inc/2;   % Bins centered from 0 to 1 

c=histc(expmt.Turns.rBias(expmt.Turns.active),bins); % turn histogram
mad(expmt.Turns.rBias(expmt.Turns.active))           % MAD of right turn prob
c=c./(sum(c));
c(end)=[];

f=figure();
plot(c,'Linewidth',2);

hold on
c=histc(expmt.LightChoice.pBias(expmt.Turns.active),bins); % histogram
mad(expmt.LightChoice.pBias(expmt.Turns.active))           % MAD of light choice prob
c=c./(sum(c));
c(end)=[];
plot(c,'Linewidth',2);
set(gca,'Xtick',(1:2:length(c)),'XtickLabel',0:inc*2:1);
axis([1 length(bins)-1 0 max(c)+0.05]);

% Generate legend labels
if isfield(expmt,'Strain')
    strain=expmt.meta.strain;
else
    strain = '';
end
if isfield(expmt,'Treatment')
    treatment=expmt.meta.treatment;
else
    treatment = '';
end

legendLabel(1)={['Turn Choice: ' strain ' ' treatment ...
    ' (u=' num2str(mean(expmt.Turns.rBias(expmt.Turns.active)))...
    ', n=' num2str(sum(expmt.Turns.active)) ')']};
legendLabel(2)={['Light Choice: ' strain ' ' treatment ...
    ' (u=' num2str(mean(expmt.LightChoice.pBias(expmt.Turns.active)))...
    ', n=' num2str(sum(expmt.Turns.active)) ')']};
legend(legendLabel);

title('Phototaxis and Right Turn Histogram');

fname = [expmt.figdir expmt.date '_hist_photo'];
if ~isempty(expmt.figdir) && options.save
    hgsave(f,fname);
    close(f);
end

end

clearvars -except expmt options

%% Clean up files and wrap up analysis

autoFinishAnalysis(expmt,options);