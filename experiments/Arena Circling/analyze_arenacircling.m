function expmt = analyze_arenacircling(expmt,varargin)
%
% This function provides a sample analysis function to run after the
% sample bare-bones template 'experimental_template.m'. It takes the
% experimental master data struct (expmt) as an input, processes the data
% to extract features and store them to file. This sample also shows how to
% automatically zip the raw data files after analysis to reduce file size.

%% Parse inputs, read data from hard disk, format in master struct, process centroid data

[expmt,options] = autoDataProcess(expmt,varargin{:});

clearvars -except expmt options


%% Generate trace plots

if options.handedness
    if isfield(expmt,'Speed') && isfield(expmt.Speed,'map')
        expmt.Speed.avg = nanmean(expmt.Speed.raw,2);
        expmt.handedness.active = expmt.Speed.avg > 0.1;
    else
        expmt.handedness.active = true(expmt.meta.num_traces,1);
    end

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
    if ~isempty(expmt.figdir) && options.save
        hgsave(f,fname);
        close(f);
    end
end


% Plot raw circling traces
if isfield(options,'plot') && options.plot
    if isfield(options,'handles')
        gui_notify('generating plots',options.handles.disp_note)
    end
    plotArenaTraces(expmt);
end

clearvars -except expmt options

%% Clean up files and wrap up analysis

autoFinishAnalysis(expmt,options);


