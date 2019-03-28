function handles = update_grid_UI(handles,mode,varargin)
% Adds and sets properties for new UI controls for grid based ROI detection

% get handles to first ROI grid controls as reference
ha = handles.add_ROI_pushbutton;
hs = findall(handles.gui_fig,'Tag','ROI_shape_popupmenu1');
hr = findall(handles.gui_fig,'Tag','row_num_edit1');
hc = findall(handles.gui_fig,'Tag','col_num_edit1');
hsc = findall(handles.gui_fig,'Tag','scale_edit1');
hd = findall(handles.gui_fig,'Tag','remove_ROI_pushbutton');

hs = hs(1);
hr = hr(1);
hc = hc(1);
hsc = hsc(1);
hd = hd(1);
n = ha.UserData.nGrids;
grid_idx = n;
q = 12;
par = ha.Parent;

% parse inputs
if ~isempty(varargin)
    grid_idx = varargin{1};
end


if ~isfield(ha.UserData,'grid') || isempty(ha.UserData.grid(1).hs) || ...
        ~isfield(ha.UserData.grid,'hd') || isempty(ha.UserData.grid(1).hd.UserData)
    ha.UserData.grid(1).hs = hs;
    ha.UserData.grid(1).hr = hr;
    ha.UserData.grid(1).hc = hc;
    ha.UserData.grid(1).hsc = hsc;
    ha.UserData.grid(1).hd = hd;
    ha.UserData.grid(1).hd.UserData = 1;
    hd.Visible = 'on';
end

% get UI spacing for controls
xShift = sum(ha.UserData.grid(1).hsc.Position([1 3])) - ...
    ha.UserData.grid(1).hs.Position(1) + ha.UserData.grid(1).hd.Position(3)*1.5;
yShift = ha.UserData.grid(1).hs.Position(4) + handles.text54.Position(4);


switch mode
    case 'add'
        % copy handle properties into new UI controls
        ha.UserData.grid(n).hs = copyobj(hs,par);
        ha.UserData.grid(n).hc = copyobj(hc,par);
        ha.UserData.grid(n).hr = copyobj(hr,par);
        ha.UserData.grid(n).hsc = copyobj(hsc,par);
        ha.UserData.grid(n).hd = copyobj(hd,par);
        ha.UserData.grid(n).hs.Callback = ha.UserData.grid(n-1).hs.Callback;
        ha.UserData.grid(n).hc.Callback = ha.UserData.grid(n-1).hc.Callback;
        ha.UserData.grid(n).hr.Callback = ha.UserData.grid(n-1).hr.Callback;
        ha.UserData.grid(n).hsc.Callback = ha.UserData.grid(n-1).hsc.Callback;
        ha.UserData.grid(n).hd.Callback = ha.UserData.grid(n-1).hd.Callback;

        % set handle value to grid number
        ha.UserData.grid(n).hs.UserData = n;
        ha.UserData.grid(n).hr.Value = n;
        ha.UserData.grid(n).hc.Value = n;
        ha.UserData.grid(n).hsc.Value = n;
        ha.UserData.grid(n).hd.UserData = n;
        ha.UserData.grid(n).shape = ha.UserData.grid(n).hs.String{ha.UserData.grid(n).hs.Value};
        ha.UserData.grid(n).nRows = str2double(ha.UserData.grid(n).hr.String);
        ha.UserData.grid(n).nCols = str2double(ha.UserData.grid(n).hc.String);
        ha.UserData.grid(n).scale= str2double(ha.UserData.grid(n).hsc.String);
    
    case 'subtract'
        
        if n > numel(ha.UserData.grid)
            return
        end
        
        delete(ha.UserData.grid(grid_idx).hs);
        delete(ha.UserData.grid(grid_idx).hr);
        delete(ha.UserData.grid(grid_idx).hc);
        delete(ha.UserData.grid(grid_idx).hsc);
        delete(ha.UserData.grid(grid_idx).hd);
        if ~isempty(ha.UserData.grid(grid_idx).hp)
            delete(ha.UserData.grid(grid_idx).hp);
        end
        ha.UserData.grid(grid_idx) = [];
        n = n-1;
        ha.UserData.nGrids = n;
    
end

if strcmp(mode,'add') && n < q
    
    % adjust position
    y = handles.text54.Position(2) - yShift + handles.text54.Position(4)/2;
    ha.UserData.grid(n).hs.Position(2) = y - (n-1)*yShift;
    ha.UserData.grid(n).hr.Position(2) = y - (n-1)*yShift;
    ha.UserData.grid(n).hc.Position(2) = y - (n-1)*yShift;
    ha.UserData.grid(n).hsc.Position(2) = y - (n-1)*yShift;
    ha.UserData.grid(n).hd.Position(2) = y - (n-1)*yShift;
    
elseif strcmp(mode,'subtract') && n > 1
    
    for i=1:n
        if ha.UserData.grid(i).hd.UserData > grid_idx
            ha.UserData.grid(i).hs.Position(2) = ha.UserData.grid(i).hs.Position(2) + yShift;
            ha.UserData.grid(i).hr.Position(2) = ha.UserData.grid(i).hr.Position(2) + yShift;
            ha.UserData.grid(i).hc.Position(2) = ha.UserData.grid(i).hc.Position(2) + yShift;
            ha.UserData.grid(i).hsc.Position(2) = ha.UserData.grid(i).hsc.Position(2) + yShift;
            ha.UserData.grid(i).hd.Position(2) = ha.UserData.grid(i).hd.Position(2) + yShift;
            ha.UserData.grid(i).hd.UserData = i;
        end
    end
    
end

% shift position of the add button
ha.Position(2) = ha.UserData.grid(n).hs.Position(2) - yShift;


if n < q
    ha.Visible = 'on';
else
    ha.Visible = 'off';
end