%% Define filepath and create Placeholder files
[fpath] = uigetdir('C:\Users\OEB131-B\Desktop\AutoTracker Test','Select a save destination');

% Create temp data files for each feature to record
t = datestr(clock,'mm-dd-yyyy_HH-MM-SS');

% Define file path
handles.cenID = [fpath '\' t '_Centroid.dat'];            % File ID for centroid data
%assignin('base', 'cenID', handles.cenID)
handles.oriID = [fpath '\' t '_Orientation.dat'];
%assignin('base', 'oriID', handles.oriID)                  % File ID for orientation angle
handles.turnID = [fpath '\' t '_RightTurns.dat'];  
%assignin('base', 'turnID', handles.turnID)                % File ID for turn data

dlmwrite(handles.cenID, [])                          % create placeholder ASCII file
dlmwrite(handles.oriID, [])                          % create placeholder ASCII file
dlmwrite(handles.turnID, [])                         % create placeholder ASCII file


