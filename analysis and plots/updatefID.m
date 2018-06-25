function [expmt]=updatefID(expmt,field)


path = expmt.data.(field).path;
path = unixify(path);

% get .bin file ID
expmt.data.(field).fID = fopen(path,'r');

% if .bin file isn't found, search for .zip file and unzip
if expmt.data.(field).fID == -1
    [fPaths] = recursiveSearch(expmt.meta.path.dir,'ext','.zip');
    if ~isempty(fPaths)
        unzipAllDir('Dir',expmt.meta.path.dir);
        expmt.data.(field).fID = fopen(path,'r');
    end
end

% if .bin file still isn't found, try updating data path
if expmt.data.(field).fID == -1
    
    expmt = updatepaths(expmt);
    expmt.data.(field).fID = fopen(expmt.data.(field).path,'r');

end



