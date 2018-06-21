function out_string = generateCallbackFuncStr(func_handle,style,in_string)

nl = '\n';
value = [char(39) 'value' char(39)];
string = [char(39) 'string' char(39)];

if strcmp(style,'slider')
    fdef = ['function ' func_handle '_' style '_Callback(hObject, evenData, handles)' nl];
    body = ['expmt.hardware.cam.(names{i}) = get(uictl(i),' value ');' nl...
            'set(uilbl(i),' string ',num2str(get(uictl(i),' value ')));' nl...
            'end' nl nl nl];
end

if strcmp(style,'popupmenu')
    fdef = ['function ' func_handle '_' style '_Callback(hObject, evenData, handles)' nl];
    body = ['str_list = get(uictl(i),' string ');' nl...
            'expmt.hardware.cam.(names{i}) = str_list(get(uictl(i),' value '));' nl...
            'end' nl nl nl];
end

out_string = [in_string fdef body];