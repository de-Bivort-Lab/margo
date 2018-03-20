function [expmt]=updatefID(expmt,field)


path = expmt.(field).path;

% get .bin file ID
expmt.(field).fID = fopen(path,'r');

% if .bin file isn't found, search for .zip file and unzip
if expmt.(field).fID == -1
    [fPaths] = getHiddenMatDir(expmt.fdir,'ext','.zip');
    if ~isempty(fPaths)
        unzipAllDir('Dir',expmt.fdir);
        expmt.(field).fID = fopen(path,'r');
    end
end

% if .bin file still isn't found, try updating data path
if expmt.(field).fID == -1
    
    rawdir = [expmt.fdir 'raw_data/'];
    if exist(rawdir,'dir')
        dinfo = dir(rawdir);
        fnames = {dinfo.name};
        newpath = ~cellfun(@isempty,strfind(fnames,field));
        expmt.(field).path = [rawdir dinfo(newpath).name];
        expmt.(field).fID = fopen(expmt.(field).path,'r');
    else    
        dinfo = dir(expmt.fdir);
        fnames = {dinfo.name};
        newpath = ~cellfun(@isempty,strfind(fnames,field));
        expmt.(field).path = [expmt.fdir '/' dinfo(newpath).name];
        expmt.(field).fID = fopen(expmt.(field).path,'r');
    end

end



