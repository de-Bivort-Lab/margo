function [dev, settings, props] = load_com_settings(dev, dev_idx, settings)


info = propinfo(dev);
props = fieldnames(dev);
ignore_props = {'RecordDetail';'RecordMode';'RecordName';'Port';'Name';...
    'DataTerminalReady';'UserData';'ObjectVisibility';'Tag'};
if strcmpi(dev.status,'open')
    fclose(dev);
end

if ~isempty(settings{dev_idx})

    % query saved cam settings
    [i_s_obj,i_set]=cmpCamSettings(dev,settings{dev_idx});
    set_names = fieldnames(settings{dev_idx});

    for i = 1:length(i_s_obj)
        if ~isfield(info.(props{i_s_obj(i)}),'ReadOnly') || ...
                ~strcmpi(info.(props{i_s_obj(i)}).ReadOnly,'always')

            dev.(props{i_s_obj(i)}) = settings{dev_idx}.(set_names{i_set(i)});
        end
    end
else
    has_readonly = find(cellfun(@(n) isfield(info.(n),'ReadOnly'), props));
    is_readonly = cellfun(@(n) strcmpi(info.(n).ReadOnly,'always'), ...
        props(has_readonly));
    props(has_readonly(is_readonly))=[];
    prop_vals = cellfun(@(n) dev.(n), props, 'UniformOutput', false);
    new_settings = cat(1,props',prop_vals');
    new_settings(:,ismember(new_settings(1,:),ignore_props)) = [];
    settings{dev_idx} = struct(new_settings{:});
end

props = fieldnames(dev);
has_readonly = find(cellfun(@(n) isfield(info.(n),'ReadOnly'), props));
is_readonly = cellfun(@(n) strcmpi(info.(n).ReadOnly,'always'), ...
    props(has_readonly));
props(has_readonly(is_readonly))=[];
props(ismember(props,ignore_props)) = [];

end