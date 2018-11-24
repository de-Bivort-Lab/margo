function clean_gui(axes_handle)

% clear any drawn objects on the axes
centroid_markers = findobj(axes_handle,'-depth',3,'Type','line');
delete(centroid_markers);
rect_handles = findobj(axes_handle,'-depth',3,'Type','rectangle');
delete(rect_handles);
text_handles = findobj(axes_handle,'-depth',3,'Type','text');
delete(text_handles);
delete(findobj(axes_handle,'-depth',3,'Type','scatter'));

if strcmp(axes_handle.Visible,'off') && ~isempty(axes_handle.Children)
    axes_handle.Visible = 'on';
end

% reset display menu checkboxes
vm = findobj('Tag','view_menu');
set(vm.Children,'Checked','off');

% remove gui patch
disp_none = findobj('Tag','display_none_menu');
if ~isempty(disp_none) && ~isempty(disp_none.UserData) 
    cellfun(@(h) delete(h),disp_none.UserData); 
    disp_none.UserData = [];
end