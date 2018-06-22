function expmt = getRawData(expmt,options)

% attempt to autofix aborted expmt files
if ~isfield(expmt,'nFrames')
    
    expmt = updatefID(expmt,'time');
    
    if isfield(expmt.data.time,'precision')
        expmt.data.time.raw = memmapfile(expmt.data.time.path, 'Format',expmt.data.time.precision);
    else
        expmt.data.time.raw = memmapfile(expmt.data.time.path, 'Format','double');
        expmt.data.time.precision = 'double';
    end
    
    expmt.meta.num_frames = length(expmt.data.time.raw.Data);
    
end

% convert drop count to fraction of total frames
if isfield(expmt,'drop_ct') && any(expmt.drop_ct > 1)
    expmt.drop_ct = expmt.drop_ct ./ expmt.meta.num_frames;
end

%% calculate decimation factor if relevant

if isfield(options,'decimate')
    
    % get subfields
    path = expmt.data.time.path;
    if isfield(expmt.data.time,'dim')
        dim = expmt.data.time.dim;
    else
        dim = 1;
    end
    if isfield(expmt.data.time,'precision')
        prcn = expmt.data.time.precision;
    else
        prcn = 'double';
        expmt.data.time.precision = prcn;
    end
    
    expmt = updatefID(expmt,'time');
    expmt.data.time.raw = memmapfile(expmt.data.time.path, 'Format',expmt.data.time.precision);
    expmt.FrameRate = 1/nanmedian(expmt.data.time.raw.Data);
    options.decfac = round(expmt.FrameRate/options.decfac);
    
    % cancel decimation if decimation factor is less than 2
    % since it will not actually decimate the data
    if options.decfac < 2
        options = rmfield(options,'decfac');
        options = rmfield(options,'decimate');
    end
    
    % create decimation mask
    if isfield(options,'decimate')
        
        options.decmask = mod(1:expmt.meta.num_frames,options.decfac)==1;
        options.decsz = sum(options.decmask);
        
    end
    
end
    

%% sequentially initialize memmap files for each field

for i = 1:length(expmt.meta.fields)
    
 
    f = expmt.meta.fields{i};
    expmt = updatefID(expmt,f);    
 
    % get subfields
    path = expmt.(f).path;
    dim = expmt.(f).dim;
    dim(find(dim==1,1,'last'))=[];
    dim = [dim expmt.meta.num_frames];
    prcn = expmt.(f).precision;
    
    % initialize the memmap
    switch prcn
        % just read raw data if data is logical
        case 'logical'
            expmt.(f).data = fread(expmt.(f).fID,dim,'logical=>logical');
            
        % otherwise create a memmap
        otherwise
            expmt.(f).map = memmapfile(expmt.(f).path, 'Format',{prcn,dim,'raw'});
            
    end
    
end

