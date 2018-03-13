function handles = update_grid_UI(handles,mode)
    
% Adds and sets properties for new UI controls for grid based ROI detection


% get handles to first ROI grid controls as reference
hs = handles.ROI_shape_popupmenu1;
hr = handles.row_num_edit1;
hc = handles.col_num_edit1;
hd = handles.remove_ROI_pushbutton;
ha = handles.add_ROI_pushbutton;
n = ha.UserData.nGrids;
par = ha.Parent;

if ~isfield(ha.UserData,'grids') || isempty(ha.UserData.grids(1).hs)
    ha.UserData.grids = struct('shape','Circular','nRows',8,'nCols',12,...
    'hs',[],'hr',[],'hc',[]);
    ha.UserData.grid(1).hs = hs;
    ha.UserData.grid(1).hr = hr;
    ha.UserData.grid(1).hc = hc;
end


switch mode
    case 'add'
    % copy handle properties into new UI controls
    ha.UserData.grid(n).hs = copyobj(hs,par);
    ha.UserData.grid(n).hc = copyobj(hc,par);
    ha.UserData.grid(n).hr = copyobj(hr,par);
    ha.UserData.grid(n).hs.Callback = ha.UserData.grid(n-1).hs.Callback;
    ha.UserData.grid(n).hc.Callback = ha.UserData.grid(n-1).hc.Callback;
    ha.UserData.grid(n).hr.Callback = ha.UserData.grid(n-1).hr.Callback;

    % set handle value to grid number
    ha.UserData.grid(n).hs.UserData = n;
    ha.UserData.grid(n).hr.Value = n;
    ha.UserData.grid(n).hc.Value = n;
    ha.UserData.grid(n).shape = ha.UserData.grid(n).hs.String{ha.UserData.grid(n).hs.Value};
    ha.UserData.grid(n).nRows = str2double(ha.UserData.grid(n).hr.String);
    ha.UserData.grid(n).nCols = str2double(ha.UserData.grid(n).hc.String);
    
    case 'subtract'
    delete(ha.UserData.grid(n).hs);
    delete(ha.UserData.grid(n).hr);
    delete(ha.UserData.grid(n).hc);
    if ~isempty(ha.UserData.grid(n).hp)
        delete(ha.UserData.grid(n).hp);
    end
    ha.UserData.grid(n) = [];
    n = n-1;
    ha.UserData.nGrids = n;
    
end

xShift = sum(hc.Position([1 3])) - ...
    hs.Position(1) + hd.Position(3) + 10;   % full length of single grid controls
yShift = hs.Position(4)+10;                 % height of the controls + spacer

if strcmp(mode,'add') && n < 4
    
    % adjust position
    ha.UserData.grid(n).hs.Position(2) = ha.UserData.grid(n).hs.Position(2) - (n-1)*yShift;
    ha.UserData.grid(n).hr.Position(2) = ha.UserData.grid(n).hr.Position(2) - (n-1)*yShift;
    ha.UserData.grid(n).hc.Position(2) = ha.UserData.grid(n).hc.Position(2) - (n-1)*yShift;
    
elseif strcmp(mode,'add')
    
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

switch n
    case 2
        ha.Position(1) = hs.Position(1);
        ha.Position(2) = ha.UserData.grid(n).hs.Position(2) - yShift;
    case 3
        ha.Position(2) = hs.Position(2);
        ha.Position(1) = hs.Position(1) + xShift;  
    otherwise
        ha.Position(2) = ha.UserData.grid(n).hs.Position(2) - yShift;
end

if n==6
    ha.Visible = 'off';
else
    ha.Visible = 'on';
end

% update remove grid button
hd.Position(2) = ha.UserData.grid(n).hc.Position(2);
if n < 4
    hd.Position(1) = hs.Position(1) + xShift - hd.Position(3);
else
    hd.Position(1) = hs.Position(1) + 2*xShift - hd.Position(3);
end

if n == 1
    hd.Visible = 'off';              
else
    hd.Visible = 'on'; 
end