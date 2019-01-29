function analyze_multiFile(varargin)

% This script reprocesses the expmt data structs from a user-selected set
% of files with the function specified by funstr. 

keyarg = {};
fDir = '';
for i=1:length(varargin)
    arg = varargin{i};
    if ischar(arg)
        switch arg
            case 'Keyword'
                keyidx = i;
                i=i+1;
                keyarg = {'keyword';varargin{i}};
            case 'Dir'
                i=i+1;
                fDir = varargin{i};
                dir_idx = i;
        end
    end
end

if exist('keyidx','var')
    varargin(keyidx:keyidx+1)=[];
end


if isempty(fDir) || strcmpi(dir,'getdir')

    % Get paths to data files
    [fDir] = autoDir;

    fPaths = getHiddenMatDir(fDir,keyarg{:});
    dir_idx = i+1;
    fDir=cell(size(fPaths));
    for j=1:length(fPaths)
        [tmp_dir,~,~]=fileparts(fPaths{j});
        fDir(j) = {[tmp_dir '/']};
    end

else
    fPaths = getHiddenMatDir(fDir,keyarg{:});
end                  

    %% reprocess data
    
    if ~iscell(fPaths)
        fPaths = {fPaths};
    end
    if ~iscell(fDir)
        fDir = {fDir};
    end
    
    hwb = waitbar(0,'loading files');
    
    for i=1:length(fPaths)
        
        hwb = waitbar(i/length(fPaths),hwb,['processing file ' num2str(i) ' of ' num2str(length(fPaths))]);
        
        disp(['processing file ' num2str(i) ' of ' num2str(length(fPaths))]);
        load(fPaths{i});
        varargin(dir_idx)=fDir(i);
        expmt = autoAnalyze(expmt,varargin{:});
        clearvars -except varargin fPaths dir_idx fDir hwb
    end
    
    delete(hwb);