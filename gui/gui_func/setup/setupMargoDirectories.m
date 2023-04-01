function handles = setupMargoDirectories(handles)
%UNTITLED Summary of this function goes here

PROJECTOR_FIT_DIR = 'hardware/projector_fit/';
PROFILES_DIR = 'profiles';

% get gui directory and ensure all dependencies are added to path
handles.gui_dir = which('margo');
[par_dir, ~, ~] = fileparts(handles.gui_dir);
[par_dir, ~, ~] = fileparts(par_dir);
addpath([genpath(par_dir) '/']);
handles.gui_dir = [par_dir '/'];
handles.gui_dir = unixify(handles.gui_dir);
addpath(genpath(handles.gui_dir));

if ~exist([handles.gui_dir PROFILES_DIR],'dir')
    mkdir([handles.gui_dir PROFILES_DIR]);
end

if ~exist([handles.gui_dir PROJECTOR_FIT_DIR],'dir')
    mkdir([handles.gui_dir PROJECTOR_FIT_DIR]);
end

end

