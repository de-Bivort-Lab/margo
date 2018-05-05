function expmt = autoUpdatePaths(expmt)

savefile = false;
if exist(expmt.fdir)~=7
    expmt.fdir = uigetdir('','Select parent directory containing master struct .mat file');
    expmt.fdir = [expmt.fdir '/'];
    savefile = true;
end
    
if isfield(expmt,'rawdir') && exist(expmt.rawdir)~=7
    dinfo = dir(expmt.fdir);
    for i=1:length(dinfo)
        if dinfo(i).isdir && ~isempty(strfind(dinfo(i).name,'raw_data'))
            expmt.rawdir = [expmt.fdir dinfo(i).name '/'];
        end
    end
    
    if exist(expmt.rawdir)~=7
        warning('Raw data directory not found, searching parent directory for raw data files');
    end
end

if isfield(expmt,'Speed') && isfield(expmt.Speed,'map') &&...
        ~any(strcmp(expmt.fields,'Speed'))
    expmt.fields = [expmt.fields;'Speed'];
end
        
for i=1:length(expmt.fields)
    f=expmt.fields{i};
    path = getHiddenMatDir(expmt.fdir,'keyword',f,'ext','.bin');
    
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
    save([expmt.fdir expmt.fLabel '.mat'],'expmt');
end

                