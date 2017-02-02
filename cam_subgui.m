function settings=cam_subgui(fh)
settings = fh.UserData;
while ishghandle(fh)
settings = fh.UserData;
end
end


function uictl1_popupmenu_Callback(hObject, evenData, handles)
str_list = get(uictl(i),'string');
expmt.camInfo.(names{i}) = str_list(get(uictl(i),'value'));
end


function uictl2_slider_Callback(hObject, evenData, handles)
expmt.camInfo.(names{i}) = get(uictl(i),'value');
set(uilbl(i),'string',num2str(get(uictl(i),'value')));
end


function uictl3_slider_Callback(hObject, evenData, handles)
expmt.camInfo.(names{i}) = get(uictl(i),'value');
set(uilbl(i),'string',num2str(get(uictl(i),'value')));
end


function uictl4_popupmenu_Callback(hObject, evenData, handles)
str_list = get(uictl(i),'string');
expmt.camInfo.(names{i}) = str_list(get(uictl(i),'value'));
end


function uictl5_slider_Callback(hObject, evenData, handles)
expmt.camInfo.(names{i}) = get(uictl(i),'value');
set(uilbl(i),'string',num2str(get(uictl(i),'value')));
end


function uictl6_slider_Callback(hObject, evenData, handles)
expmt.camInfo.(names{i}) = get(uictl(i),'value');
set(uilbl(i),'string',num2str(get(uictl(i),'value')));
end


function uictl8_slider_Callback(hObject, evenData, handles)
expmt.camInfo.(names{i}) = get(uictl(i),'value');
set(uilbl(i),'string',num2str(get(uictl(i),'value')));
end


function uictl9_popupmenu_Callback(hObject, evenData, handles)
str_list = get(uictl(i),'string');
expmt.camInfo.(names{i}) = str_list(get(uictl(i),'value'));
end


function uictl10_slider_Callback(hObject, evenData, handles)
expmt.camInfo.(names{i}) = get(uictl(i),'value');
set(uilbl(i),'string',num2str(get(uictl(i),'value')));
end


function uictl14_slider_Callback(hObject, evenData, handles)
expmt.camInfo.(names{i}) = get(uictl(i),'value');
set(uilbl(i),'string',num2str(get(uictl(i),'value')));
end


function uictl15_popupmenu_Callback(hObject, evenData, handles)
str_list = get(uictl(i),'string');
expmt.camInfo.(names{i}) = str_list(get(uictl(i),'value'));
end


