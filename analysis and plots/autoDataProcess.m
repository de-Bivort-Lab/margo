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
options.slide = true;           % slide window over Circadian speed data
options.regress = false;        % regress out camera distortion from speed data
options.handedness = false;     % calculate handedness metrics

for i = 1:length(varargin)
    
    arg = varargin{i};
    
    if ischar(arg)
        switch arg
            case 'Plot'
                i=i+1;
                options.plot = varargin{i};             
            case 'Dir'
                i=i+1;
                expmt.fdir = varargin{i};              
            case 'Save'
                i=i+1;
                options.save = varargin{i};             
            case 'Handles'
                i=i+1;
                options.handles = varargin{i};
            case 'Decimate'
                i=i+1;
                options.decimate = varargin{i};
            case 'DecFac'
                i=i+1;
                options.decfac = varargin{i};
            case 'Raw'
                i=i+1;
                options.raw = varargin{i};
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
        end
    end
end

% print gui update
if isfield(options,'handles')
    gui_notify('importing and processing data...',options.handles.disp_note)
end

expmt.nTracks = size(expmt.ROI.centers,1);

%% initialize raw data memmap files
    
expmt = getRawData(expmt,options);

%% extract centroid features
[expmt] = processCentroid(expmt,options);

% record distance from camera center
if ~isfield(expmt.ROI,'cam_dist')
    cc = [size(expmt.ref,2)/2 size(expmt.ref,1)/2];
    expmt.ROI.cam_dist = sqrt((expmt.ROI.centers(:,1)-cc(1)).^2 + ...
        (expmt.ROI.centers(:,2)-cc(2)).^2);
end

% regress out lens distance distortion with linear model
if options.regress
    if isfield(options,'handles')
        gui_notify('modeling lens distortion',...
            options.handles.disp_note)
    end
    expmt = modelLensDistortion(expmt);
end

expmt.figdir = [expmt.fdir 'figures_' expmt.date '/'];
if ~exist(expmt.figdir,'dir') && options.save
    [mkst,~]=mkdir(expmt.figdir);
    if ~mkst
       expmt.figdir=[];
    end
end

if isfield(expmt,'Speed') && isfield(expmt.Speed,'map') ...
        && options.bootstrap
    
    if isfield(options,'handles')
        gui_notify('resampling speed data, may take a few minutes',...
            options.handles.disp_note)
    end
    
    % chunk speed data into individual movement bouts
    block_indices = blockActivity(expmt.Speed.map.Data.raw);
    
    % bootstrap resample speed data to generate null distribution
    [expmt.Speed.bs,f]=bootstrap_speed_blocks(expmt,block_indices,100);
    
    % save bootstrap figure to file
    fname = [expmt.figdir expmt.date '_bs_logspeed'];
    if ~isempty(expmt.figdir) && options.save
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

            
            
            
            