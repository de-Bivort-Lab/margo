function expmt = getRawData(expmt,options)

% attempt to autofix aborted expmt files
if ~isfield(expmt,'nFrames')
    
    expmt = updatefID(expmt,'Time');
    
    if isfield(expmt.Time,'precision')
        expmt.Time.raw = memmapfile(expmt.Time.path, 'Format',expmt.Time.precision);
    else
        expmt.Time.raw = memmapfile(expmt.Time.path, 'Format','double');
        expmt.Time.precision = 'double';
    end
    
    expmt.nFrames = length(expmt.Time.raw.Data);
    
end

% convert drop count to fraction of total frames
if isfield(expmt,'drop_ct') && any(expmt.drop_ct > 1)
    expmt.drop_ct = expmt.drop_ct ./ expmt.nFrames;
end

%% calculate decimation factor if relevant

if isfield(options,'decimate')
    
    % get subfields
    path = expmt.Time.path;
    if isfield(expmt.Time,'dim')
        dim = expmt.Time.dim;
    else
        dim = 1;
    end
    if isfield(expmt.Time,'precision')
        prcn = expmt.Time.precision;
    else
        prcn = 'double';
        expmt.Time.precision = prcn;
    end
    
    expmt = updatefID(expmt,'Time');
    expmt.Time.raw = memmapfile(expmt.Time.path, 'Format',expmt.Time.precision);
    expmt.FrameRate = 1/nanmedian(expmt.Time.raw.Data);
    options.decfac = round(expmt.FrameRate/options.decfac);
    
    % cancel decimation if decimation factor is less than 2
    % since it will not actually decimate the data
    if options.decfac < 2
        options = rmfield(options,'decfac');
        options = rmfield(options,'decimate');
    end
    
    % create decimation mask
    if isfield(options,'decimate')
        
        options.decmask = mod(1:expmt.nFrames,options.decfac)==1;
        options.decsz = sum(options.decmask);
        
    end
    
end
    

%% sequentially initialize memmap files for each field

for i = 1:length(expmt.fields)
    
 
    f = expmt.fields{i};
    expmt = updatefID(expmt,f);    
 
    % get subfields
    path = expmt.(f).path;
    dim = [expmt.(f).dim expmt.nFrames];
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

expmt.DecFrames = size(expmt.Centroid.data,1);