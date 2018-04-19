function expmt = autoUpdatePaths(expmt)

if exist(expmt.fdir)~=7
    expmt.fdir = uigetdir('','Select parent directory containing master struct .mat file');
end
    
if exist(expmt.rawdir)~=7
    dinfo = dir(expmt.fdir);
    for i=1:length(dinfo)
        if dinfo(i).isdir && ~isempty(strfind(dinfo(i).name,'raw_data'))
            expmt.rawdir = [expmt.fdir '/' dinfo(i).name '/'];
        end
    end
    
    if exist(expmt.rawdir)~=7
        warning('Raw data directory not found, searching parent directory for raw data files');
    end
end
        
for i=1:length(expmt.fields)
    f=expmt.fields{i};

   if exist(expmt.(f).map.Filename)~=2
       path = getHiddenMatDir(expmt.fdir,'keyword',f,'ext','.bin');
       if ~isempty(path)
           expmt.(f).map.Filename = path{1};
           expmt.(f).path = path{1};
       else
           error(['Unable to locate ' f ' raw data file in parent directory']);
       end
   end
end
                