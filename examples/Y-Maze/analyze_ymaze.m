function expmt = analyze_ymaze(expmt,varargin)
%
% This function provides a sample analysis function to run after the
% sample bare-bones template 'experimental_template.m'. It takes the
% experimental master data struct (expmt) as an input, processes the data
% to extract features and store them to file. This sample also shows how to
% automatically zip the raw data files after analysis to reduce file size.

%% Parse inputs, read data from hard disk, format in master struct, process centroid data

[expmt,options] = autoDataProcess(expmt,varargin{:});

clearvars -except expmt trackProps options


turns = expmt.data.Turns.raw();
turn_idx = turns~=0;
turn_idx = num2cell(turn_idx,1);
first_turn_row = cellfun(@(t) find(t,1,'first'), ...
    turn_idx,'UniformOutput',false);
first_turn_col = find(~cellfun(@isempty,first_turn_row))';
first_turn_row = cat(1,first_turn_row{:});
first_turn_idx = sub2ind(size(turns),first_turn_row, first_turn_col);
turns(first_turn_idx) = 0;
turn_idx = cat(2,turn_idx{:});
clear first_turn_col first_turn_idx first_turn_row

%% Calculate turn probability

props = {'n';'t';'sequence';'switchiness';'clumpiness';'rBias';'active'};
addprops(expmt.data.Turns, props);
expmt.data.Turns.n = sum(turns~=0)-1;
expmt.data.Turns.t = NaN(max(expmt.data.Turns.n),expmt.meta.num_traces);
expmt.data.Turns.sequence = ...
    NaN(max(expmt.data.Turns.n),expmt.meta.num_traces);

%{
Start by converting arm number turn sequence into compressed right turn
sequence by taking difference between subsequent maze arms. For either orientation 
of a maze, arms are 1 to 3 left to right. For example, for a rightside-up Y, 
right turns would be 1-3=-2, 3-2=1, and 2-1=1. The opposite is true for the
opposite orientation of a maze. In the output, tSeq, Right turns = 1, Left
turns = 0.
%}


tElapsed = cumsum(expmt.data.time.raw());

for i=1:expmt.meta.num_traces
    
    % get turn indices and time stamps
    idx = turns(:,i)~=0;        
    expmt.data.Turns.t(1:length(tElapsed(idx)),i) = tElapsed(idx);         
    
    % calculate turn sequence
    tSeq = turns(idx,i);
    tSeq=diff(tSeq);  
    if expmt.meta.roi.orientation(i)
        expmt.data.Turns.sequence(1:length(tSeq),i)=tSeq==1|tSeq==-2;
    elseif ~expmt.meta.roi.orientation(i)
        expmt.data.Turns.sequence(1:length(tSeq),i)=tSeq==-1|tSeq==2;
    end
    
end

% Calculate right turn probability from tSeq
expmt.data.Turns.n = sum(~isnan(expmt.data.Turns.sequence), 'omitnan');
expmt.data.Turns.rBias = ...
    sum(expmt.data.Turns.sequence, 'omitnan') ./ expmt.data.Turns.n;

% Calculate clumpiness and switchiness
expmt.data.Turns.switchiness = NaN(expmt.meta.num_traces,1);
expmt.data.Turns.clumpiness = NaN(expmt.meta.num_traces,1);
for i = 1:expmt.meta.num_traces
    
    idx = ~isnan(expmt.data.Turns.sequence(:,i));
    s = expmt.data.Turns.sequence(idx,i);
    r = expmt.data.Turns.rBias(i);
    n = expmt.data.Turns.n(i);
    t = expmt.data.Turns.t(idx,i);
    iti = (t(2:end) - t(1:end-1));
    
    expmt.data.Turns.switchiness(i) = ...
        sum((s(1:end-1)+s(2:end))==1) / (2*r*(1-r)*n);
    expmt.data.Turns.clumpiness(i) = ...
        std(iti) / mean(iti);
    
end

expmt.data.Turns.active = expmt.data.Turns.n > 39;

if isfield(options,'handles')
    gui_notify('processing complete',options.handles.disp_note)
end

clearvars -except expmt options
disp("Try saving as csv")

%% Generate plots

% Histogram plot
inc=0.05;
bins=-inc/2:inc:1+inc/2;   % Bins centered from 0 to 1 

c=histcounts(expmt.data.Turns.rBias(expmt.data.Turns.n>40),bins); % turn histogram
% % mad(expmt.data.Turns.rBias(expmt.data.Turns.n>40))           % MAD of right turn prob
c=c./(sum(c, 'omitnan'));
c(end)=[];

f=figure();
plot(c,'Linewidth',2);

set(gca,'Xtick',(1:2:length(c)),'XtickLabel',0:inc*2:1);
axis([1 length(bins)-1 0 max(c)+0.05]);
xlabel('Right Turn Probability');
title('Y-maze Handedness Histogram');

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

legendLabel(1)={[strain ' ' treatment ...
    ' (u=' num2str(mean(expmt.data.Turns.rBias(expmt.data.Turns.n>40)),2)...
    ', n=' num2str(sum(expmt.data.Turns.n>40)) ')']};
legend(legendLabel);

fname = [expmt.meta.path.fig expmt.meta.date '_hist_handedness'];
if ~isempty(expmt.meta.path.fig) && options.save
    hgsave(f,fname);
    close(f);
end

% disp("converttocsv")
ymazetocsv(expmt);
clearvars -except expmt options

%% Clean up files and wrap up analysis

autoFinishAnalysis(expmt,options);