function [expmt, handles] = refreshCOM(expmt, handles)

% Attempt handshake with light panel teensy
expmt.hardware.COM.findDevices();

% Update GUI menus with port names
if ~isempty(expmt.hardware.COM.ports)
    handles.microcontroller_popupmenu.String = expmt.hardware.COM.ports;
else
    handles.microcontroller_popupmenu.String = 'No COM detected';
end

% automatically select light COM if detected
if ~isempty(expmt.hardware.COM.light)
    handles.microcontroller_popupmenu.Value = ...
        find(strcmp(expmt.hardware.COM.ports, expmt.hardware.COM.light.port));
end
        

% Initialize light panel at default values
infraredIntensity = str2double(get(handles.edit_IR_intensity, 'string'));
whiteIntensity = str2double(get(handles.edit_White_intensity, 'string'));

% Convert intensity percentage to uint8 PWM value 0-255
expmt.hardware.light.infrared = uint8((infraredIntensity / 100) * 255);
expmt.hardware.light.white = uint8((whiteIntensity / 100) * 255);

% Write values to microcontroller
expmt.hardware.COM.writeLightPanel(LightPanelPins.WHITE, expmt.hardware.light.white);
expmt.hardware.COM.writeLightPanel(LightPanelPins.INFRARED, expmt.hardware.light.infrared);

% generate menu items for AUX COMs and config their callbacks
hParent = findobj('Tag', 'aux_com_menu');

% remove controls for existing list
del=[];
for i = 1:length(hParent.Children)
    if ~strcmp(hParent.Children(i).Label, 'refresh list')
        del = [del i];
    end
end
delete(hParent.Children(del));

        

% generate controls for new list
expmt.hardware.COM.aux = [];
for i = 1:length(expmt.hardware.COM.ports)
    menuItems(i) = uimenu(hParent,'Label',expmt.hardware.COM.ports{i},...
        'Callback',@aux_com_list_Callback);
    if i ==1
        menuItems(i).Separator = 'on';
    end
end

if ~isempty(expmt.hardware.COM.light)
    isLightPort = strcmp(expmt.hardware.COM.light.port, expmt.hardware.COM.ports);
    menuItems(isLightPort).Enable = 'off';
end