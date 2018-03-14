function [expmt]=updatefID(expmt,field)


path = expmt.(field).path;

% get .bin file ID
expmt.(field).fID = fopen(path,'r');

% if .bin file isn't found, search for .zip file and unzip
if expmt.(field).fID == -1
    [fPaths] = getHiddenMatDir(expmt.fdir,'exit','.zip');
    if ~isempty(fPaths)
        unzipAllDir('Dir',expmt.fdir);
    end
end
    
expmt.(field).fID = fopen(path,'r');

% if .bin file still isn't found, try updating data path
if expmt.(field).fID == -1

    dinfo = dir(expmt.fdir);
    fnames = {dinfo.name};
    newpath = ~cellfun(@isempty,strfind(fnames,field));
    expmt.(field).path = [expmt.fdir '/' dinfo(newpath).name];
    expmt.(field).fID = fopen(expmt.(field).path,'r');

end
