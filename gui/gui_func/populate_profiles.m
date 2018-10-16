function populate_profiles(handles)

% Get existing profile list
gui_dir = which('margo');
gui_dir = gui_dir(1:strfind(gui_dir,'/gui/'));
load_path =[gui_dir 'profiles/'];
tmp_profiles = ls(load_path);
profiles = cell(size(tmp_profiles,1),1);
remove = [];

for i = 1:size(profiles,1)
    k = strfind(tmp_profiles(i,:),'.mat');
    if isempty(k)
        remove = [remove i];
    else
        profiles(i) = {tmp_profiles(i,1:k-1)};
    end
end

profiles(remove)=[];

if size(profiles,1) > 0
    handle.profiles = profiles;
else
    handle.profiles = {'No profiles detected'};
end

hParent = findobj('Tag','saved_presets_menu');

for i = 1:length(profiles)
    menu_items(i) = uimenu(hParent,'Label',profiles{i},...
        'Callback',@saved_preset_Callback,'UserData',i);
end

handles.saved_presets_menus = menu_items;

function saved_preset_Callback(src,event)
disp('hello')


