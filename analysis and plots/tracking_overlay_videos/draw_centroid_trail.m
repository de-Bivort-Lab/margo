function handles = draw_centroid_trail(expmt, frame_num, trail_length, varargin)
% draw an centroid marker with comet trail on each tracked object in
% tracking overlay video
%
% Inputs
%   expmt           - ExperimentData for the tracking session
%   frame_num       - index of the acquisition frame
%   trail_length    - length of the centroid comet trail (number of frames)
%   varargin
%       handles     - handles to update (leave blank to initialize handles)
%       options     - struct of plotting options (leave blank to use defaults)
% Outputs
%   handles         - struct of plot handles
%
% Plotting Options
%   These struct fields are name value pairs for the various plots below.
%   Eeach field should take the form of a cell array of name value pairs
%   (eg. options.heading = {'Color'; 'r'; 'MarkerSize', ...}
%
%   centroid        - Name-Value pairs for heading indicator plot (type=line)
%   trail           - Name-Value pairs for ellipse patch plot (type=line)
%

% parse inputs
handles = struct();
options = struct();
for i=1:numel(varargin)
    switch i
        case 1, handles = varargin{i};
        case 2, options = varargin{i};
    end
end

% set default plotting options for missing fields 
options = set_options(options);

% initialization
cen = [expmt.data.centroid.raw(frame_num,1,:);...
    expmt.data.centroid.raw(frame_num,2,:)];
if isfield(options,'x_pad')
   cen(1,:) = cen(1,:)+options.x_pad; 
end

% draw patches
hold on
if ~isfield(handles,'centroid') || isempty(handles.centroid)
    handles.centroid = scatter(cen(1,:),cen(2,:),options.centroid{:});
    pause(0.1);
else
    handles.centroid.XData = cen(1,:);
    handles.centroid.YData = cen(2,:);
end

if trail_length > 0

    % initialize trail coordinates
    if ~isfield(handles,'trail') || isempty(handles.trail)
        
        % initialize empty coords
        trail_x = num2cell(NaN(trail_length,size(cen,2)),1);
        trail_y = num2cell(NaN(trail_length,size(cen,2)),1);

        % initialize plotting data
        plot_xdata = cat(1,trail_x{:});
        plot_ydata = cat(1,trail_y{:});
        handles.trail = plot(plot_xdata,plot_ydata,options.trail{:});
        pause(0.01);
        
        handles.trail.Edge.ColorType = 'truecoloralpha';
        uistack(handles.trail,'down');
        
        handles.trail.UserData.x = trail_x;
        handles.trail.UserData.y = trail_y;
    end
    
    % retrieve trail coordinate data
    trail_x = handles.trail.UserData.x;
    trail_y = handles.trail.UserData.y;
    
    % update trail marker position data
    [trail_x, trail_y] = cellfun(@(c,tx,ty) update_trail_coords(c(1),c(2),tx,ty),...
        num2cell(cen,1), trail_x, trail_y, 'UniformOutput', false);
        
    % initialize plotting data
    plot_xdata = cat(1,trail_x{:});
    plot_ydata = cat(1,trail_y{:});

    % restrict to valid coordinates
    plot_xdata = plot_xdata(~isnan(plot_xdata));
    plot_ydata = plot_ydata(~isnan(plot_ydata));
    
    % update trail color data
    trail_cdata = cellfun(@(tx) ...
    update_trail_cdata(~isnan(tx), handles.trail.Edge.ColorData(1:3,1)),...
    trail_x, 'UniformOutput', false);
    trail_cdata = cat(2,trail_cdata{:});
    set(handles.trail.Edge,'ColorBinding','none');
    set(handles.trail,'XData',plot_xdata,'YData',plot_ydata);
    set(handles.trail.Edge,'ColorBinding','interpolated',...
        'ColorData',trail_cdata);
    
    % store trail coordinates in the trail handle user data
    handles.trail.UserData.x = trail_x;
    handles.trail.UserData.y = trail_y;
end






function options = set_options(options)

if ~isfield(options,'centroid') || isempty(options.centroid)
    options.centroid = {'Marker'; 'o';'MarkerFaceColor'; 'g';...
        'MarkerEdgeColor'; 'none';'MarkerSize'; 3; 'LineWidth'; 2.5};
end
if ~isfield(options,'trail') || isempty(options.trail)
    options.trail = {'LineStyle'; '-'; 'Color'; 'c'; 'LineWidth'; 2};
end



