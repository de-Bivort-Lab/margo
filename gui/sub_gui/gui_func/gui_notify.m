function gui_notify(msg,text_handle)

if iscell(msg)
tmp_msg = ['(' datestr(clock,'HH:MM:SS mm/dd/yyyy') ')  '];
msg(1) = {[tmp_msg msg{1}]};
for i=2:length(msg)
    msg(i) = {[repmat(' ',1,38) msg{i}]};
end
else
    msg = {msg};
end

msg_list = text_handle.String;
if ~iscell(msg_list)
    msg_list = {msg_list};
end
msg_list = [msg;msg_list];
text_handle.String = msg_list;