function expmt = analyze_arenacircling(expmt,varargin)
%
% This function provides a sample analysis function to run after the
% sample bare-bones template 'experimental_template.m'. It takes the
% experimental master data struct (expmt) as an input, processes the data
% to extract features and store them to file. This sample also shows how to
% automatically zip the raw data files after analysis to reduce file size.

%% Parse inputs, read data from hard disk, format in master struct, process centroid data

[expmt,trackProps,meta] = autoDataProcess(expmt,varargin{:});

clearvars -except expmt trackProps meta


%% Generate trace plots

expmt.Speed.avg = nanmean(trackProps.speed);
expmt.handedness.active = expmt.Speed.avg > 0.1;

% generate handedness histogram
f=figure();
m = expmt.handedness.mu(expmt.handedness.active);
bins = linspace(-1,1,11);
c = histc(m,bins);
c = c./sum(c);
b = bins + median(diff(bins))/2;
plot(b,c,'m','Linewidth',2);
set(gca,'Xtick',linspace(-1,1,11));
title('handedness histogram');
xlabel('\mu arena circling score');
legend(['\mu score (mean=' num2str(nanmean(expmt.handedness.mu),2)...
    ', n=' num2str(sum(expmt.handedness.active)) ')']);
axis([-1 1 0 max(c)*1.2]);

fname = [expmt.figdir expmt.date '_handedness'];
if ~isempty(expmt.figdir) && meta.save
    hgsave(f,fname);
    close(f);
end

% compare first and second half handedness as control
first_half = false(size(trackProps.speed));
first_half(1:round(length(first_half)/2),:) = true;
inc = first_half & trackProps.speed >0.8;
expmt.handedness_First = getHandedness(trackProps,'Include',inc);
inc = ~first_half & trackProps.speed >0.8;
expmt.handedness_Second = getHandedness(trackProps,'Include',inc);

% plot intra-experiment handedness correlation
f=figure(); 
[r,p]=corrcoef([expmt.handedness_First.mu' expmt.handedness_Second.mu'],'rows','pairwise');
sh=scatter(expmt.handedness_First.mu,expmt.handedness_Second.mu,...
    'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[0.5 0.5 0.5]);
sh.Parent.XLim = [-1 1];
sh.Parent.YLim = [-1 1];
xlabel('first half \mu');
ylabel('second half \mu');
dim = [.65 .78 .1 .1];
str = ['r = ' num2str(round(r(2,1)*100)/100) ', p = ' num2str(round(p(2,1)*10000)/10000)...
    ' (n=' num2str(expmt.nTracks) ')'];
annotation('textbox',dim,'String',str,'FitBoxToText','on');
title('arena circling - handedness');

fname = [expmt.figdir expmt.date '_intra-handedness'];
if ~isempty(expmt.figdir) && meta.save
    hgsave(f,fname);
    close(f);
end


% Plot raw circling traces
if isfield(meta,'plot') && meta.plot
    if isfield(meta,'handles')
        gui_notify('generating plots',meta.handles.disp_note)
    end
    plotArenaTraces(expmt);
end

clearvars -except expmt meta

%% Clean up files and wrap up analysis

autoFinishAnalysis(expmt,meta);


