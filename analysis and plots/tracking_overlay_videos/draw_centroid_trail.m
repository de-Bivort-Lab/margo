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
    handles.centroid = plot(cen(1,:),cen(2,:),options.centroid{:});
    pause(0.1);
else
    handles.centroid.XData = cen(1,:);
    handles.centroid.YData = cen(2,:);
end

if trail_length > 0
    
    % find inactive centroids with NaNs and replace with placeholder
    inactive = isnan(cen(1,:));
    center = [size(expmt.meta.ref.im,2);size(expmt.meta.ref.im,1)]./2;
    cen(:,inactive) = repmat(center,1,sum(inactive));
    
    % initialize trail coordinates
    if ~isfield(handles,'trail') || isempty(handles.trail)
        trail = repmat(cen,1,1,trail_length);
        trail = permute(trail,[3,2,1]);
        xidx = 1:numel(trail)/2;
        yidx = numel(trail)/2+1:numel(trail);
    
        handles.trail = plot(trail(xidx),trail(yidx),options.trail{:});
        pause(0.01);
        handles.trail.Edge.ColorType = 'truecoloralpha';
        uistack(handles.trail,'down');
    else
        % get current positions from trail handle
        x = handles.trail.XData;
        y = handles.trail.YData;
        trail_x = reshape(x, trail_length, numel(x)/trail_length);
        trail_y = reshape(y, trail_length, numel(y)/trail_length);
        
        % determine if trace was previously inactive
        prev_inactive = trail_x == center(1);
        
        % initialize all coordinates to new position for previously
        % inactive traces
        x_mat = repmat(cen(1,:),size(trail_x,1),1);
        y_mat = repmat(cen(2,:),size(trail_y,1),1);
        trail_x(prev_inactive) = x_mat(prev_inactive);
        trail_y(prev_inactive) = y_mat(prev_inactive);
        
        % shift the current trail positions back by one frame
        trail_x = circshift(trail_x,1,1);
        trail_y = circshift(trail_y,1,1);
        
        % insert new centroid positions at front of trail
        trail_x(1,:) = cen(1,:);
        trail_y(1,:) = cen(2,:);
        
        % update positions in trail handle
        handles.trail.XData = trail_x(:);
        handles.trail.YData = trail_y(:);
    end
    
    % initialize trail color data (fade transparency with alpha blend)
    trail_color = handles.trail.Edge.ColorData(1:3,1);
    trail_cdata = repmat(trail_color,1,trail_length);
    trail_cdata(4,:) = uint8(linspace(255,0,trail_length));
    trail_cdata(4,1) = 0;
    trail_cdata = repmat(trail_cdata,1,1,expmt.meta.num_traces);
    
    % set alpha of inactive traces to zero
    trail_cdata(4,:,inactive) = 0;
    trail_cdata = reshape(trail_cdata(:),4,numel(trail_cdata)/4);

    % update the color data
    set(handles.trail.Edge,'ColorBinding','interpolated','ColorData',trail_cdata);
end






function options = set_options(options)

if ~isfield(options,'centroid') || isempty(options.centroid)
    options.centroid = {'Marker'; 'o'; 'LineStyle'; 'none';...
        'MarkerFaceColor'; 'g'; 'MarkerEdgeColor'; 'none';...
        'MarkerSize'; 3; 'LineWidth'; 2.5};
end
if ~isfield(options,'trail') || isempty(options.trail)
    options.trail = {'LineStyle'; '-'; 'Color'; 'c'; 'LineWidth'; 2};
end



