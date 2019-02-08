function expmt = analyze_basictracking(expmt,varargin)
%
% This function provides a sample pre-processing and 
% analysis function to execute after following run_basictracking.m. It 
% takes the ExperimentData object (expmt) as an input, processes the data
% to extract features and store them to file.

% Parse inputs, read data from hard disk, format in master struct, process centroid data
[expmt,options] = autoDataProcess(expmt,varargin{:});

% Clean up files and wrap up analysis
autoFinishAnalysis(expmt,options);
