function ymazetocsv(varargin)
% this function converts MARGO ymaze data to CSVs
numArgs = length(varargin);

if numArgs == 1
%the number of arguments is the number of items put within the () of the
%function that you wrote in your command window
    if isa(varargin{1}, 'ExperimentData')
        expmt = varargin{1};
     % this command allows the expmt file to be manually loaded into the
     % fuction
    elseif isa(varargin{1}, 'char') | isa(varargin{1}, 'string')
        filepath=varargin{1};
        loadedfiles=load(filepath, 'expmt');
        expmt=loadedfiles.expmt;
        %this command allows files that are not expmt to be added to the
        %path so they can be inputed into the fuction
    else
        error("Expected either an ExperimentData file or path to MARGO .mat file.")
    end


end
 
if numArgs == 3
    a = varargin{1};
    b = table(varargin{2}, VariableNames = "rBias");
    c = tbale(varargin{3}, VariableNames="nTurns");
    m = [a b c];
    %this command allows you to manually input specific variables into the
    %csv by writing the instructing the function where exactly to find the
    %data
end

if numArgs == 0
    %Open matlab file IO UI for a 
    [file_a, path_a] = uigetfile;
    loadedfiles=load(strcat(path_a,file_a), 'expmt');
    expmt=loadedfiles.expmt;
    %This command will prompt you to pick files from your computer's finder
    %window and will then run the files through this function to get the
    %.csv

    % a = file_a
    % 
    % %Open matlab file IO UI for b 
    % [file_b, path_b] = uigetfile;
    % b = table(file_b, VariableNames = "rBias")
    % 
    % %Open matlab file IO UI for c 
    % [file_c, path_c] = uigetfile;
    % c = table(file_c, VariableNames = "nTurns")

    % m = [a b c]
    
end

if ~isa(expmt, "ExperimentData")
    error("Loaded file isn't type Experiment Data, or MARGO is not in the path")
end

a = expmt.meta.labels_table;
b = table(expmt.data.Turns.rBias', VariableNames="rBias");
c = table(expmt.data.Turns.n', VariableNames="nTurns");
m = [a b c];

filename=strcat(expmt.meta.date, expmt.meta.name, ".csv");
writetable(m, filename);
%this command names the file

