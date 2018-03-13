function gui_notify(msg,text_handle)

msg = ['(' datestr(clock,'HH:MM:SS mm/dd/yyyy') ')  ' msg];
msg_list = text_handle.String;
if ~iscell(msg_list)
    msg_list = {msg_list};
end
msg_list = [{msg};msg_list];
text_handle.String = msg_list;