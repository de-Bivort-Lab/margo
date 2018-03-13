function [varargout] = autoDataProcess(expmt,varargin)

% This function does basic data processing common to all autotracker
% experiments such as reading the data from the hard disk, formating it into
% the master data struct, and processing centroid coordinates and time
% variables.

%% parse inputs

meta.save = true;
meta.raw = false;
meta.bootstrap = true;
meta.slide = true;
meta.regress = false;

for i = 1:length(varargin)
    
    arg = varargin{i};
    
    if ischar(arg)
        switch arg
            case 'Plot'
                i=i+1;
                meta.plot = varargin{i};
            case 'Dir'
                i=i+1;
                expmt.fdir = varargin{i};
            case 'Save'
                i=i+1;
                meta.save = varargin{i};
            case 'Handles'
                i=i+1;
                meta.handles = varargin{i};
            case 'Decimate'
                i=i+1;
                meta.decimate = varargin{i};
            case 'DecFac'
                i=i+1;
                meta.decfac = varargin{i};
            case 'Raw'
                meta.raw = true;
            case 'Bootstrap'
                i=i+1;
                meta.bootstrap = varargin{i};
            case 'Slide'
                i=i+1;
                meta.slide = varargin{i};
            case 'Regress'
                i=i+1;
                meta.regress = varargin{i};
        end
    end
end

%% Pull in ASCII data, format into vectors/matrices

if isfield(meta,'handles')
    gui_notify('importing and processing data...',meta.handles.disp_note)
end

expmt.nTracks = size(expmt.ROI.centers,1);


%% attempt to autofix aborted expmt files

if ~isfield(expmt,'nFrames')
    
    path = expmt.Time.path;
    
    % read .bin file
    expmt.Time.fID = fopen(path,'r');
    
    % if .bin file isn't found, search for .zip file and unzip
    if expmt.Time.fID == -1
        [fPaths] = getHiddenMatDir(expmt.fdir,'exit','.zip');
        if ~isempty(fPaths)
            unzipAllDir('Dir',expmt.fdir);
        end
    end

    % if .bin file still isn't found, try updating data path
    if expmt.Time.fID == -1
            
            dinfo = dir(expmt.fdir);
            fnames = {dinfo.name};
            newpath = ~cellfun(@isempty,strfind(fnames,'Time'));
            expmt.Time.path = [expmt.fdir '\' dinfo(newpath).name];
            expmt.Time.fID = fopen(expmt.Time.path,'r');
        
    end
        
    expmt.Time.data = fread(expmt.Time.fID,'single'); 
    expmt.nFrames = length(expmt.Time.data);
    
end


%% calculate decimation factor if relevant

if isfield(meta,'decimate')
    
    % get subfields
    path = expmt.Time.path;
    dim = expmt.Time.dim;
    prcn = expmt.Time.precision;
    prcn = [prcn '=>' prcn];

    % read .bin file
    expmt.Time.fID = fopen(path,'r');
    
    % if .bin file isn't found, search for .zip file and unzip
    if expmt.Time.fID == -1
        [fPaths] = getHiddenMatDir(expmt.fdir,'exit','.zip');
        if ~isempty(fPaths)
            unzipAllDir('Dir',expmt.fdir);
        end
    end

    % if .bin file still isn't found, try updating data path
    if expmt.Time.fID == -1
            
            dinfo = dir(expmt.fdir);
            fnames = {dinfo.name};
            newpath = ~cellfun(@isempty,strfind(fnames,'Time'));
            expmt.Time.path = [expmt.fdir '\' dinfo(newpath).name];
            expmt.Time.fID = fopen(expmt.Time.path,'r');
        
    end
        
    expmt.Time.data = fread(expmt.Time.fID,[expmt.Time.dim(1) expmt.nFrames],prcn);                        
    expmt.Time.data = expmt.Time.data';
    expmt.FrameRate = 1/nanmedian(expmt.Time.data);
    meta.decfac = round(expmt.FrameRate/meta.decfac);
    
    % cancel decimation if decimation factor is less than 2
    % since it will not actually decimate the data
    if meta.decfac < 2
        meta = rmfield(meta,'decfac');
        meta = rmfield(meta,'decimate');
    end
    
    % create decimation mask
    if isfield(meta,'decimate')
        
        meta.decmask = mod(1:expmt.nFrames,meta.decfac)==1;
        meta.decsz = sum(meta.decmask);
        
    end
    
    fclose(expmt.Time.fID);
    
end
    

%% read in data files sequentially and store in data struct

for i = 1:length(expmt.fields)
    
 
    f = expmt.fields{i};
        
    if ~isfield(expmt.(f),'data') || meta.raw
        
        % get subfields
        path = expmt.(f).path;
        dim = expmt.(f).dim;
        prcn = expmt.(f).precision;
        prcn = [prcn '=>' prcn];

        % read .bin file
        expmt.(f).fID = fopen(path,'r');
        
        % if .bin file isn't found, search for .zip file and unzip
        if expmt.(f).fID == -1
            [fPaths] = getHiddenMatDir(expmt.fdir,'exit','.zip');
            if ~isempty(fPaths)
                unzipAllDir('Dir',expmt.fdir);
            end
        end
        
        % if .bin file still isn't found, try updating data path
        if expmt.(f).fID == -1
            
            dinfo = dir(expmt.fdir);
            fnames = {dinfo.name};
            newpath = ~cellfun(@isempty,strfind(fnames,f));
            expmt.(f).path = [expmt.fdir '\' dinfo(newpath).name];
            expmt.(f).fID = fopen(expmt.(f).path,'r');
            
        end


        % if field is centroid, reshape to (frames x dim x nTracks)
        if strcmp(f,'Centroid')
            expmt.(f).data = fread(expmt.(f).fID,prcn);
            expmt.(f).data = reshape(expmt.(f).data,dim(1),dim(2),expmt.nFrames);
            expmt.(f).data = permute(expmt.(f).data,[3 2 1]);
            
            if isfield(expmt,'drop_ct')
                expmt.drop_ct = expmt.drop_ct ./ expmt.nFrames;
            end
            


        % import non-centroid data
        elseif ~strcmp(f,'VideoData') || ~strcmp(f,'VideoIndex')
            
            expmt.(f).data = fread(expmt.(f).fID,[expmt.(f).dim(1) expmt.nFrames],prcn);                        
            expmt.(f).data = expmt.(f).data';

        end
    
        % close the .bin file
        fclose(expmt.(f).fID);
        
        
    end
    

    % Decimate the data if specified
    do_decimation = isfield(meta,'decimate') && any(strcmp(f,meta.decimate)) &&...
            ~any(size(expmt.(f).data) == meta.decsz);
        
    if do_decimation
        
        % decimate other data as normal
        decdim = find(size(expmt.(f).data) == expmt.nFrames);
        dims = 1:ndims(expmt.(f).data);
        ndim = dims(end);
        
        % rearrange data so that time varying dimension is first dimension
        if decdim ~= 1
            perm_dim = dims;
            perm_dim(perm_dim == decdim) = [];
            expmt.(f).data = permute(expmt.(f).data,[decdim perm_dim]);
        end
        
        % decimate the data along the time dimension
        switch ndim
            case 1
                expmt.(f).data = expmt.(f).data(meta.decmask);
                
            case 2               
                if strcmp(f,'Time')

                    % convert time data from ifi to tElapsed and decimate
                    expmt.(f).data = cumsum(expmt.(f).data);              
                    expmt.(f).data = expmt.(f).data(meta.decmask,:);
                    expmt.(f).data = [0;diff(expmt.(f).data)];

                else   
                    expmt.(f).data = expmt.(f).data(meta.decmask,:);
                end
                
            case 3
                expmt.(f).data = expmt.(f).data(meta.decmask,:,:);
                
            case 4
                expmt.(f).data = expmt.(f).data(meta.decmask,:,:,:);              
        end
        
        

    end
    
    
end

expmt.DecFrames = size(expmt.Centroid.data,1);
    

% In the example, the centroid is being processed to extract circling
% handedness for each track. Resulting handedness scores are stored in
% the master data struct.
[expmt,trackProps] = processCentroid(expmt);
trackProps.turning(trackProps.speed<0.1) = NaN;
expmt.handedness.index = nansum(trackProps.turning)./nansum(abs(trackProps.turning));
expmt.Speed.data = trackProps.speed;

if ~isfield(expmt.ROI,'cam_dist')
    cc = [size(expmt.ref,2)/2 size(expmt.ref,1)/2];
    expmt.ROI.cam_dist = sqrt((expmt.ROI.centers(:,1)-cc(1)).^2 + ...
        (expmt.ROI.centers(:,2)-cc(2)).^2);
end

if meta.regress
    expmt = modelLensDistortion(expmt);
end
expmt.Speed.avg = nanmean(expmt.Speed.data);
expmt.Speed.active = expmt.Speed.avg > 0.1;

expmt.figdir = [expmt.fdir 'figures_' expmt.date '\'];
if ~exist(expmt.figdir,'dir') && meta.save
    [mkst,~]=mkdir(expmt.figdir);
    if ~mkst
       expmt.figdir=[];
    end
end

if isfield(trackProps,'speed') && meta.bootstrap
    
    % chunk speed data into individual movement bouts
    block_indices = blockActivity(trackProps.speed);
    
    % bootstrap resample speed data to generate null distribution
    [expmt.Speed.bs,f]=bootstrap_speed_blocks(expmt,trackProps,block_indices,100);
    
    % save bootstrap figure to file
    fname = [expmt.figdir expmt.date '_bs_logspeed'];
    if ~isempty(expmt.figdir) && meta.save
        hgsave(f,fname);
        close(f);
    end

end

if isfield(meta,'handles')
    gui_notify('processing complete',meta.handles.disp_note)
end


for i=1:nargout
    switch i
        case 1, varargout{i} = expmt;
        case 2, varargout{i} = trackProps;
        case 3, varargout{i} = meta;
    end
end

            
            
            
            