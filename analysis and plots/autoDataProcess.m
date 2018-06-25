function [varargout] = autoDataProcess(expmt,varargin)

% This function does basic data processing common to all autotracker
% experiments such as reading the data from the hard disk, formating it into
% the master data struct, and processing centroid coordinates and time
% variables.

%% parse input properties

% set defaults property values
options.plot = false;           % plots raw centroid traces
options.save = true;            % toggles file/figure saving
options.raw = {};               % set fields to create raw data files for
options.bootstrap = false;      % bootstrap metrics to generate null model
options.slide = false;           % slide window over Circadian speed data
options.regress = false;        % regress out camera distortion from speed data
options.handedness = false;     % calculate handedness metrics
options.area_threshold = false;

for i = 1:length(varargin)
    
    arg = varargin{i};
    
    if ischar(arg)
        switch arg
            case 'Plot'
                i=i+1;
                options.plot = varargin{i};             
            case 'Dir'
                i=i+1;
                expmt.meta.path.dir= varargin{i};
                expmt = autoUpdatePaths(expmt);
     
            case 'Save'
                i=i+1;
                options.save = varargin{i};             
            case 'Handles'
                i=i+1;
                options.handles = varargin{i};
            case 'Raw'
                i=i+1;
                options.raw = varargin{i};
                if ~iscell(options.raw)
                    options.raw = {options.raw};
                end
            case 'Bootstrap'
                i=i+1;
                options.bootstrap = varargin{i};
            case 'Slide'
                i=i+1;
                options.slide = varargin{i};
            case 'Regress'
                i=i+1;
                options.regress = varargin{i};
            case 'Handedness'
                i=i+1;
                options.handedness = varargin{i};
            case 'AreaThresh'
                i=i+1;
                options.area_threshold = varargin{i};
        end
    end
end

% print gui update
if isfield(options,'handles')
    gui_notify('importing and processing data...',options.handles.disp_note)
end

expmt.meta.num_traces = size(expmt.meta.roi.centers,1);

%% initialize raw data memmap files

% query available memory
memInfo=memory;
nGigs = memInfo.MemAvailableAllArrays/1E9;
if nGigs < 1
    msg = {['WARNING: low available memory (' num2str(nGigs,2) 'GB)'];...
    'processing times may be slow'};
    if isfield(options,'handles')
        gui_notify(msg,options.handles.disp_note);
    else
        disp(msg);
    end
end

% initialize memmaps
expmt = getRawData(expmt,options);

% query centroid file size
if isattached(expmt.data.centroid)
    sz = numel(expmt.data.centroid.raw);
    switch expmt.data.centroid.precision
        case 'double', sz = sz*8;
        case 'single', sz = sz*4;
    end
    if sz > 1E9
        msg = {['WARNING: large raw data file (' num2str(sz/1E9,2) 'GB)'];...
            'processing times may be slow'};
        if isfield(options,'handles')
            gui_notify(msg,options.handles.disp_note);
        else
            disp(msg);
        end
    end       
end

%% extract centroid features
[expmt] = processCentroid(expmt,options);

% record distance from camera center
if ~isfield(expmt.meta.roi,'cam_dist')
    cc = [size(expmt.meta.ref.im,2)/2 size(expmt.meta.ref.im,1)/2];
    expmt.meta.roi.cam_dist = ...
        sqrt((expmt.meta.roi.centers(:,1)-cc(1)).^2 + ...
            (expmt.meta.roi.centers(:,2)-cc(2)).^2);
end

% regress out lens distance distortion with linear model
if options.regress
    if isfield(options,'handles')
        gui_notify('modeling lens distortion',...
            options.handles.disp_note)
    end
    expmt = modelLensDistortion(expmt);
end

expmt.meta.path.figdir = [expmt.meta.path.dir 'figures_' expmt.meta.date '/'];
if ~exist(expmt.meta.path.fig,'dir') && options.save
    [mkst,~]=mkdir(expmt.meta.path.fig);
    if ~mkst
       expmt.meta.path.fig=[];
    end
end

if isfield(expmt.data,'speed') && isattached(expmt.data.speed) ...
        && options.bootstrap
    
    if isfield(options,'handles')
        gui_notify('resampling speed data, may take a few minutes',...
            options.handles.disp_note)
    end
    
    % chunk speed data into individual movement bouts
    [block_indices, lag_thresh, speed_thresh] = blockActivity(expmt.data.speed.map);
    expmt.data.speed.thresh = speed_thresh;
    expmt.data.speed.bouts.thresh = lag_thresh;
    expmt.data.speed.bouts.idx = block_indices;
    
    % bootstrap resample speed data to generate null distribution
    [expmt.data.speed.bs,f] = bootstrap_speed_blocks(expmt,block_indices,100);
    
    % save bootstrap figure to file
    fname = [expmt.meta.path.fig expmt.meta.date '_bs_logspeed'];
    if ~isempty(expmt.meta.path.fig) && options.save
        hgsave(f,fname);
        close(f);
    end

end

if isfield(options,'handles')
    gui_notify('processing complete',options.handles.disp_note)
end


for i=1:nargout
    switch i
        case 1, varargout{i} = expmt;
        case 2, varargout{i} = options;
    end
end

            
            
            
            