function expmt = autoUnixPath(expmt)

f = {'fdir';'fpath';'rawdir';'figdir'};
for i=1:numel(f)
    if isfield(expmt,f{i})
        expmt.(f{i})(expmt.(f{i})=='\') = '/';
    end
end

if isfield(expmt,'fields')
    f= expmt.meta.fields;
    f = [f;{'speed';'Direction';'Theta';'Radius'}];
    for i=1:numel(f)
        if isfield(expmt,f{i})
            if isfield(expmt.(f{i}),'path')
                expmt.(f{i}).path(expmt.(f{i}).path=='\') = '/';
            end
            if isfield(expmt.(f{i}),'map')
                expmt.(f{i}).map.Filename(expmt.(f{i}).map.Filename=='\') = '/';
            end
        end
    end
end