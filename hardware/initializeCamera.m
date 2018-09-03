function camInfo=initializeCamera(camInfo)

vid = videoinput(camInfo.AdaptorName,camInfo.DeviceIDs{camInfo.activeID},camInfo.ActiveMode{:});

src = getselectedsource(vid);
info = propinfo(src);
names = fieldnames(info);

if isfield(camInfo,'settings')
    
    % query saved cam settings
    [i_src,i_set]=cmpCamSettings(src,camInfo.settings);
    set_names = fieldnames(camInfo.settings);
    
    for i = 1:length(i_src)
        if ~isempty(camInfo.settings.(set_names{i_set(i)}))
            src.(names{i_src(i)}) = camInfo.settings.(set_names{i_set(i)});
        end
    end
    
end

triggerconfig(vid,'manual');

camInfo.vid = vid;
camInfo.src = src;




