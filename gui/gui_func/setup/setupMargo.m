function [expmt, handles] = setupMargo(handles)
%INITIALIZEMARGO Margo GUI initialization

% initialize required directories
handles = setupMargoDirectories(handles);

% configure the figure window, display, and handles
handles = defaultConfigureGUI(handles);

% initialize ExperimentData obj
expmt = ExperimentData;

% initialize camera settings and controls
[expmt, handles] = setupCameras(expmt, handles);

% query ports and initialize COM objects
[expmt, handles] = refreshCOM(expmt, handles);

% Initialize experiment parameters from text boxes in the GUI
handles = updateExperimentParameterControls(expmt.parameters, handles);

end

