function expmt = autoUpdatePaths(expmt)

savefile = false;
if exist(expmt.meta.path.dir)~=7
    expmt.meta.path.dir = uigetdir('','Select parent directory containing master struct .mat file');
    expmt.meta.path.dir = [expmt.meta.path.dir '/'];
    savefile = true;
end
    
if isfield(expmt,'rawdir') && exist(expmt.rawdir)~=7
    dinfo = dir(expmt.meta.path.dir);
    for i=1:length(dinfo)
        if dinfo(i).isdir && ~isempty(strfind(dinfo(i).name,'raw_data'))
            expmt.rawdir = [expmt.meta.path.dir dinfo(i).name '/'];
        end
    end
    
    if exist(expmt.rawdir)~=7
        warning('Raw data directory not found, searching parent directory for raw data files');
    end
end

if isfield(expmt.data,'speed') && isattached(expmt.data.speed) &&...
        ~any(strcmp(expmt.meta.fields,'speed'))
    expmt.meta.fields = [expmt.meta.fields;'speed'];
end
        
for i=1:length(expmt.meta.fields)
    f=expmt.meta.fields{i};
    path = recursiveSearch(expmt.meta.path.dir,'keyword',f,'ext','.bin');
    
    if ~isempty(path)
       if ~strcmp(path,expmt.(f).path)
           expmt.(f).path = path{1};
           savefile = true;
       end

        if isfield(expmt.(f),'map') && exist(expmt.(f).map.Filename)~=2
           expmt.(f).map.Filename = path{1};
           savefile = true;
        end

    else
       error(['Unable to locate ' f ' raw data file in parent directory']);
    end
end


if savefile
    % save the updated information to file
    save([expmt.meta.path.dir expmt.meta.path.name '.mat'],'expmt');
end

                