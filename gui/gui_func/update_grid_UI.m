function handles = update_grid_UI(handles,mode)
    
% Adds and sets properties for new UI controls for grid based ROI detection


% get handles to first ROI grid controls as reference
hs = handles.ROI_shape_popupmenu1;
hr = handles.row_num_edit1;
hc = handles.col_num_edit1;
hsc = handles.scale_edit1;
hd = handles.remove_ROI_pushbutton;
ha = handles.add_ROI_pushbutton;
n = ha.UserData.nGrids;
q = 12;
par = ha.Parent;


if ~isfield(ha.UserData,'grids') || isempty(ha.UserData.grid(1).hs)
    ha.UserData.grid(1).hs = hs;
    ha.UserData.grid(1).hr = hr;
    ha.UserData.grid(1).hc = hc;
    ha.UserData.grid(1).hsc = hsc;
end


switch mode
    case 'add'
        % copy handle properties into new UI controls
        ha.UserData.grid(n).hs = copyobj(hs,par);
        ha.UserData.grid(n).hc = copyobj(hc,par);
        ha.UserData.grid(n).hr = copyobj(hr,par);
        ha.UserData.grid(n).hsc = copyobj(hsc,par);
        ha.UserData.grid(n).hs.Callback = ha.UserData.grid(n-1).hs.Callback;
        ha.UserData.grid(n).hc.Callback = ha.UserData.grid(n-1).hc.Callback;
        ha.UserData.grid(n).hr.Callback = ha.UserData.grid(n-1).hr.Callback;
        ha.UserData.grid(n).hsc.Callback = ha.UserData.grid(n-1).hsc.Callback;

        % set handle value to grid number
        ha.UserData.grid(n).hs.UserData = n;
        ha.UserData.grid(n).hr.Value = n;
        ha.UserData.grid(n).hc.Value = n;
        ha.UserData.grid(n).hsc.Value = n;
        ha.UserData.grid(n).shape = ha.UserData.grid(n).hs.String{ha.UserData.grid(n).hs.Value};
        ha.UserData.grid(n).nRows = str2double(ha.UserData.grid(n).hr.String);
        ha.UserData.grid(n).nCols = str2double(ha.UserData.grid(n).hc.String);
        ha.UserData.grid(n).scale= str2double(ha.UserData.grid(n).hsc.String);
    
    case 'subtract'
        
        if n > numel(ha.UserData.grid)
            return
        end
        
        delete(ha.UserData.grid(n).hs);
        delete(ha.UserData.grid(n).hr);
        delete(ha.UserData.grid(n).hc);
        delete(ha.UserData.grid(n).hsc);
        if ~isempty(ha.UserData.grid(n).hp)
            delete(ha.UserData.grid(n).hp);
        end
        ha.UserData.grid(n) = [];
        n = n-1;
        ha.UserData.nGrids = n;
    
end

xShift = sum(hsc.Position([1 3])) - ...
    hs.Position(1) + hd.Position(3)*1.5;   % full length of single grid controls
yShift = hs.Position(4)+handles.text54.Position(4);% height of the controls + spacer

if strcmp(mode,'add') && n < q
    
    % adjust position
    ha.UserData.grid(n).hs.Position(2) = ha.UserData.grid(n).hs.Position(2) - (n-1)*yShift;
    ha.UserData.grid(n).hr.Position(2) = ha.UserData.grid(n).hr.Position(2) - (n-1)*yShift;
    ha.UserData.grid(n).hc.Position(2) = ha.UserData.grid(n).hc.Position(2) - (n-1)*yShift;
    ha.UserData.grid(n).hsc.Position(2) = ha.UserData.grid(n).hsc.Position(2) - (n-1)*yShift;
    
end

% shift position of the add button
ha.Position(2) = ha.UserData.grid(n).hs.Position(2) - yShift;


if n < q
    ha.Visible = 'on';
else
    ha.Visible = 'off';
end

% update remove grid button
hd.Position(2) = ha.UserData.grid(n).hc.Position(2);
if n < q
    hd.Position(1) = hs.Position(1) + xShift - hd.Position(3);
end
if n == 1
    hd.Visible = 'off';              
else
    hd.Visible = 'on'; 
end