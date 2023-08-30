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
props = {'n';'sequence';'switchiness';'pBias';'active'};
addprops(expmt.data.LightChoice, props);
expmt.data.Turns.n = sum(turns~=0)-1;
expmt.data.Turns.t = NaN(max(expmt.data.Turns.n),expmt.meta.num_traces);
expmt.data.Turns.sequence = ...
    NaN(max(expmt.data.Turns.n),expmt.meta.num_traces);
expmt.data.LightChoice.sequence = ...
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
    
    idx = turns(:,i) ~= 0;        % get turn indices
    expmt.data.Turns.t(1:length(tElapsed(idx)),i) = tElapsed(idx);         % record timestamps of turns
    
    % calculate turn sequence
    tSeq = turns(idx,i);
    lSeq = expmt.data.LightChoice.raw(idx,i);
    tSeq=diff(tSeq);  
    if expmt.meta.roi.orientation(i)
        expmt.data.Turns.sequence(1:length(tSeq),i)=tSeq==1|tSeq==-2;
    elseif ~expmt.meta.roi.orientation(i)
        expmt.data.Turns.sequence(1:length(tSeq),i)=tSeq==-1|tSeq==2;
    end
    
    expmt.data.LightChoice.sequence(1:length(lSeq),i) = lSeq;
    
end

% Calculate right turn probability from tSeq
expmt.data.Turns.n = nansum(~isnan(expmt.data.Turns.sequence));
expmt.data.Turns.rBias = ...
    nansum(expmt.data.Turns.sequence) ./ expmt.data.Turns.n;


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
    
    expmt.data.Turns.switchiness(i) = sum((s(1:end-1)+s(2:end))==1)/(2*r*(1-r)*n);
    expmt.data.Turns.clumpiness(i) = std(iti) / mean(iti);
    
end

expmt.data.Turns.active = expmt.data.Turns.n > 39;

if isfield(options,'handles')
    gui_notify('processing complete',options.handles.disp_note);
end


%% Calculate light choice probability

expmt.data.LightChoice.n = sum(expmt.data.LightChoice.raw()~=0);
expmt.data.LightChoice.active = expmt.data.LightChoice.n > 39;
expmt.data.LightChoice.switchiness = NaN(expmt.meta.num_traces,1);
expmt.data.LightChoice.pBias = ...
    sum(expmt.data.LightChoice.raw()==1)./expmt.data.LightChoice.n;

for i = 1:expmt.meta.num_traces
    
    idx = ~isnan(expmt.data.Turns.sequence(:,i));
    s = expmt.data.LightChoice.sequence(idx,i)==1;
    r = expmt.data.LightChoice.pBias(i);
    n = expmt.data.LightChoice.n(i);
    t = expmt.data.Turns.t(idx,i);
    
    expmt.data.LightChoice.switchiness(i) = ...
        sum((s(1:end-1)+s(2:end))==1)/(2*r*(1-r)*n);
    
end

expmt.data.LightChoice.active = expmt.data.LightChoice.n > 39;

% bootstrap resample data
if isprop(expmt.data.LightChoice,'active') && ...
        any(expmt.data.LightChoice.active)
    
    addprops(expmt.data.LightChoice,'bs');
    [expmt.data.LightChoice.bs, f] = bootstrap_ledymaze(expmt,200);
    
    fname = [expmt.meta.path.fig expmt.meta.date '_bs_light'];
    if ~isempty(expmt.meta.path.fig) && options.save
        hgsave(f,fname);
        close(f);
    end

end

% Compute psychometric curves if applicable
switch expmt.parameters.led_mode
    case 'random'
        [expmt.meta.psychometrics, fhs] = ...
            ledymaze_psychometrics(expmt.data.led_pwm.raw(),expmt.data.LightChoice.raw());
        
        % save psychmetric curve figure
        fname = [expmt.meta.path.fig expmt.meta.date '_avg_psycho_curve'];
        if ~isempty(expmt.meta.path.fig) && options.save
            hgsave(fhs(1),fname);
            close(fhs(1));
        end
        
        % save individual psychometric curves
        fname = [expmt.meta.path.fig expmt.meta.date '_ind_psycho_curves'];
        if ~isempty(expmt.meta.path.fig) && options.save
            hgsave(fhs(2),fname);
            close(fhs(2));
        end
end

%% Create histogram plots of turn bias and light choice probability

if isprop(expmt.data.LightChoice,'active') &&...
        any(expmt.data.LightChoice.active)
    
inc=0.05;
bins=-inc/2:inc:1+inc/2;   % Bins centered from 0 to 1 

c=histc(expmt.data.Turns.rBias(expmt.data.Turns.active),bins); % turn histogram
mad(expmt.data.Turns.rBias(expmt.data.Turns.active))           % MAD of right turn prob
c=c./(sum(c));
c(end)=[];

f=figure();
plot(c,'Linewidth',2);

hold on
c=histc(expmt.data.LightChoice.pBias(expmt.data.Turns.active),bins); % histogram
mad(expmt.data.LightChoice.pBias(expmt.data.Turns.active))           % MAD of light choice prob
c=c./(sum(c));
c(end)=[];
plot(c,'Linewidth',2);
set(gca,'Xtick',(1:2:length(c)),'XtickLabel',0:inc*2:1);
axis([1 length(bins)-1 0 max(c)+0.05]);

% Generate legend labels
if isfield(expmt.meta,'Strain')
    strain=expmt.meta.strain;
else
    strain = '';
end
if isfield(expmt.meta,'Treatment')
    treatment=expmt.meta.treatment;
else
    treatment = '';
end

legendLabel(1)={['Turn Choice: ' strain ' ' treatment ...
    ' (u=' num2str(nanFilteredMean(expmt.data.Turns.rBias(expmt.data.Turns.active)))...
    ', n=' num2str(nansum(expmt.data.Turns.active)) ')']};
legendLabel(2)={['Light Choice: ' strain ' ' treatment ...
    ' (u=' num2str(nanFilteredMean(expmt.data.LightChoice.pBias(expmt.data.Turns.active)))...
    ', n=' num2str(nansum(expmt.data.Turns.active)) ')']};
legend(legendLabel);

title('Phototaxis and Right Turn Histogram');

fname = [expmt.meta.path.fig expmt.meta.date '_hist_photo'];
if ~isempty(expmt.meta.path.fig) && options.save
    hgsave(f,fname);
    close(f);
end

end

clearvars -except expmt options

%% Clean up files and wrap up analysis

autoFinishAnalysis(expmt,options);