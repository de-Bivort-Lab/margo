function [fPaths] = getHiddenMatDir(fDir,varargin)

% This function recursively digs up all .mat files in subdirectories of fDir

target_ext = '.mat';

for i=1:length(varargin)
    
    arg = varargin{i};
    if ischar(arg)
        switch arg
            case 'ext', target_ext = varargin{i+1};
        end
    end
end

% get directory info and restrict contents to subdirectories
dir_info = dir(fDir);
dirs = dir_info([dir_info.isdir]);
files = dir_info(~[dir_info.isdir]);
fPaths = {};

for i=1:length(files)
    
    [path,name,ext]=fileparts([fDir '\' files(i).name]);
    
    if strcmp(ext,target_ext)
        path = [path '\' name ext];
        fPaths = [fPaths {path}];
    end
    
end

ignore = {'.';'..';};
for i=1:length(dirs)
    
    if ~any(strcmp(dirs(i).name,ignore))
        
        subdir = [fDir '\' dirs(i).name];
        subpaths = getHiddenMatDir(subdir,'ext',target_ext);
        
        if ~isempty(subpaths)
            fPaths = [fPaths subpaths];
        end
        
    end
end

