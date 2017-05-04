function expmt = analyze_basictracking(expmt,varargin)
%
% This function provides a sample analysis function to run after the
% sample bare-bones template 'experimental_template.m'. It takes the
% experimental master data struct (expmt) as an input, processes the data
% to extract features and store them to file. This sample also shows how to
% automatically zip the raw data files after analysis to reduce file size.

%% Parse inputs, read data from hard disk, format in master struct, process centroid data

[expmt,trackProps,meta] = autoDataProcess(expmt,varargin{:});

clearvars -except expmt trackProps meta

%% Generate plots

if isfield(meta,'plot') && meta.plot
    if isfield(meta,'handles')
        gui_notify('generating plots',meta.handles.disp_note)
    end
    plotArenaTraces(expmt);
end

clearvars -except expmt meta

%% Clean up files and wrap up analysis

autoFinishAnalysis(expmt,meta)
