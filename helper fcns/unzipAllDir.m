function unzipAllDir(varargin)

for i=1:length(varargin)
    arg = varargin{i};
    if ischar(arg)
        switch arg
            case 'Dir'
                i=i+1;
                fDir=varargin{i};
        end
    end
end

if ~exist('fDir','var')
    [fDir] = uigetdir('C:\Users\debivort\Documents\MATLAB\Decathlon Raw Data',...
    'Select directory containing expmt structs to be analyzed');
end

fPaths = getHiddenMatDir(fDir,'ext','.zip');

wh=waitbar(0,['unzipping file 0 out of ' num2str(length(fPaths))]);
wh.Name = 'unzipping files, please wait...';

for i = 1:length(fPaths)
    
    tmpdir = find(fPaths{i}=='\');
    tmpdir = fPaths{i}(1:tmpdir(end));
    
    if ishghandle(wh)
    waitbar(i/length(fPaths),wh,['unzipping file ' ...
        num2str(i) ' out of ' num2str(length(fPaths))]);
    end
    
    unzip(fPaths{i},tmpdir);
    delete(fPaths{i});
end

    if ishghandle(wh)
        close(wh);
    end