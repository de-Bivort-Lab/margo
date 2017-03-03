function [camInfo] = refresh_cam_list(handles)
    
% Query available camera and modes
imaqreset
c = imaqhwinfo;

if ~isempty(c.InstalledAdaptors)

    % Select default adaptor for connected camera(s)
    ct=0;   
    cam_list = struct('name','','adaptor','','index',[]);

    for i = 1:length(c.InstalledAdaptors)
        camInfo = imaqhwinfo(c.InstalledAdaptors{i});
        if ~isempty(camInfo.DeviceIDs) && ~exist('adaptor','var')
            adaptor = i;
            for j = 1:length(camInfo.DeviceIDs)
                ct = ct + 1;
                cam_list(ct).name = camInfo.DeviceInfo(j).DeviceName;
                cam_list(ct).adaptor = c.InstalledAdaptors{adaptor};
                cam_list(ct).index = j;
            end
        end
    end
    handles.cam_list = cam_list;

    % populate camera select menu
    if exist('adaptor','var')
        camInfo = imaqhwinfo(c.InstalledAdaptors{adaptor});
        set(handles.cam_select_popupmenu,'string',{cam_list(:).name});
    end 


    % Set the device to default format and populate mode pop-up menu
    if ~isempty(camInfo.DeviceInfo);
        set(handles.cam_mode_popupmenu,'String',camInfo.DeviceInfo(1).SupportedFormats);
        default_format = camInfo.DeviceInfo.DefaultFormat;

        for i = 1:length(camInfo.DeviceInfo(1).SupportedFormats)
            if strcmp(default_format,camInfo.DeviceInfo(1).SupportedFormats{i})
                set(handles.cam_mode_popupmenu,'Value',i);
                camInfo.ActiveMode = camInfo.DeviceInfo(1).SupportedFormats(i);
            end
        end
        camInfo.activeID = 1;
    else
        camInfo.activeID = [];
        set(handles.cam_select_popupmenu,'String','Camera not detected');
        set(handles.cam_mode_popupmenu,'String','No camera modes available');
    end


    camInfo;

else
    camInfo=[];
    set(handles.cam_select_popupmenu,'String','No camera adaptors installed');
    set(handles.cam_mode_popupmenu,'String','');
end

