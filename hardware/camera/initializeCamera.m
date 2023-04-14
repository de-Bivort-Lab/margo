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
        
        % if property in settings list
        if ~isempty(camInfo.settings.(set_names{i_set(i)}))
            
            % query property value and constraints
            val = camInfo.settings.(set_names{i_set(i)});
            constr = info.(set_names{i_set(i)}).ConstraintValue;
            set_prop = false;
            
            % check to see if value falls in constraints
            switch info.(set_names{i_set(i)}).Constraint
                case 'enum'
                    if ismember(val,constr)
                        set_prop = true;
                    end
                case 'bounded'
                    if all(val(:) > constr(1)) && all(val(:) < constr(2))
                        set_prop = true;
                    end
            end
            
            % set the property
            if set_prop
                try
                    src.(names{i_src(i)}) = val;
                catch
                end
            end
        end
    end
    
end

try
    vid.ReturnedColorSpace = 'grayscale';
catch
    warning('Tried and failed to agjust the colorspace to grayscale');
end

triggerconfig(vid,'manual');

camInfo.vid = vid;
camInfo.src = src;




