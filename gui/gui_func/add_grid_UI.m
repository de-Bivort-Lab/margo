function handles = add_grid_UI(handles)


% get handles to first ROI grid controls as reference
hs = handles.ROI_shape_popupmenu1;
hr = handles.row_num_edit1;
hc = handles.col_num_edit1;
hd = handles.remove_ROI_pushbutton;
ha = handles.add_ROI_pushbutton;
n = ha.UserData.nGrids;
par = ha.Parent;

if ~isfield(ha.UserData,'grids') || isempty(ha.UserData.grids(1).hs)
    ha.UserData.grid(1).hs = hs;
    ha.UserData.grid(1).hr = hr;
    ha.UserData.grid(1).hc = hc;
end


% copy handle properties into new UI controls
ha.UserData.grid(n).hs = copyobj(hs,par);
ha.UserData.grid(n).hc = copyobj(hc,par);
ha.UserData.grid(n).hr = copyobj(hr,par);

% set handle value to grid number
ha.UserData.grid(n).hs.UserData = n;
ha.UserData.grid(n).hr.Value = n;
ha.UserData.grid(n).hc.Value = n;

xShift = sum(hc.Position([1 3])) - ...
    hs.Position(1) + hd.Position(3) + 10;  % full length of single grid controls

if n < 5
    
    % adjust position
    yShift = hs.Position(4)+10;
    ha.UserData.grid(n).hs.Position(2) = ha.UserData.grid(n).hs.Position(2) - (n-1)*yShift;
    ha.UserData.grid(n).hr.Position(2) = ha.UserData.grid(n).hr.Position(2) - (n-1)*yShift;
    ha.UserData.grid(n).hc.Position(2) = ha.UserData.grid(n).hc.Position(2) - (n-1)*yShift;
    hd.Position(2) = ha.UserData.grid(n).hc.Position(2);
    hd.Position(1) = hs.Position(1) + xShift - hd.Position(3);
    
else
    
    % adjust position
    yShift = ha.UserData.grid(n).hs.Position(4)+10;
    ha.UserData.grid(n).hs.Position(1) = hs.Position(1) + xShift;
    ha.UserData.grid(n).hr.Position(1) = hr.Position(1) + xShift;
    ha.UserData.grid(n).hc.Position(1) = hc.Position(1) + xShift;
    ha.UserData.grid(n).hs.Position(2) = ha.UserData.grid(n).hs.Position(2) - (n-4)*yShift;
    ha.UserData.grid(n).hr.Position(2) = ha.UserData.grid(n).hr.Position(2) - (n-4)*yShift;
    ha.UserData.grid(n).hc.Position(2) = ha.UserData.grid(n).hc.Position(2) - (n-4)*yShift;
    hd.Position(2) = ha.UserData.grid(n).hc.Position(2);
    hd.Position(1) = hs.Position(1) + xShift*2 - hd.Position(3);
    
end

if n==4
    ha.Position(2) = hs.Position(2);
    ha.Position(1) = hs.Position(1) + xShift;  
else
    ha.Position(2) = ha.Position(2) - yShift;
end

if n==8
    ha.Visible = 'off';
end

hd.Visible = 'on';              % ensure that remove ROI button is shown