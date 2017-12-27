function analyze_multiFile(varargin)

% This script reprocesses the expmt data structs from a user-selected set
% of files with the function specified by funstr. 

keyarg = {};
for i=1:length(varargin)
    arg = varargin{i};
    if ischar(arg)
        switch arg
            case 'Keyword'
                keyidx = i;
                i=i+1;
                keyarg = {'keyword';varargin{i}};
        end
    end
end

if exist('keyidx','var')
    varargin(keyidx:keyidx+1)=[];
end

for i=1:length(varargin)
    if any(strcmp(varargin{i},'Dir')) && strcmp(varargin{i+1},'getdir')

        % Get paths to data files
        [fDir] = uigetdir('C:\Users\debivort\Documents\MATLAB\Decathlon Raw Data',...
            'Select directory containing expmt structs to be analyzed');

        fPaths = getHiddenMatDir(fDir,keyarg{:});
        dir_idx = i+1;
        fDir=cell(size(fPaths));
        for j=1:length(fPaths)
            [tmp_dir,~,~]=fileparts(fPaths{j});
            fDir(j) = {[tmp_dir '\']};
        end

    end
end                         
            

    %% reprocess data
    
    if ~iscell(fPaths)
        fPaths = {fPaths};
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