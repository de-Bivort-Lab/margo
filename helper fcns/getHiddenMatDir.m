function [fPaths] = getHiddenMatDir(fDir,varargin)

% This function recursively digs up all .mat files in subdirectories of fDir

target_ext = '.mat';
opts={};

for i=1:length(varargin)
    
    arg = varargin{i};
    if ischar(arg)
        switch arg
            case 'ext'
                i=i+1;
                target_ext = varargin{i};   % restricts files to those with target extension
            case 'keyword'
                i=i+1;
                key = varargin{i};          % restricts files to those with keyword in the name
                opts = [opts{:},{'keyword',key}];
        end
    end
end

% pack input options into cell
opts = [opts{:} {'ext',target_ext}];

% get directory info and restrict contents to subdirectories
dir_info = dir(fDir);
dirs = dir_info([dir_info.isdir]);
files = dir_info(~[dir_info.isdir]);
fPaths = {};

for i=1:length(files)
    
    [path,name,ext]=fileparts([fDir '/' files(i).name]);
    
    if strcmp(ext,target_ext) && exist('key','var') && ~isempty(strfind(name,key))
        path = [path '/' name ext];
        fPaths = [fPaths {path}];
    elseif strcmp(ext,target_ext) && ~exist('key','var')
        path = [path '/' name ext];
        fPaths = [fPaths {path}];
    end
    
end

ignore = {'.';'..';};
for i=1:length(dirs)
    
    if ~any(strcmp(dirs(i).name,ignore))
        
        subdir = [fDir '/' dirs(i).name];
        subpaths = getHiddenMatDir(subdir,opts{:});
        
        if ~isempty(subpaths)
            fPaths = [fPaths subpaths];
        end
        
    end
end

