function [expmt] = processCentroid(expmt,opt)


if isempty(opt.raw) && ~opt.handedness
    return
end

% initialize tracking properties struct
nf = expmt.meta.num_frames;

% initialize raw data files if necessary
if ~isempty(opt.raw)
    rawdir = [expmt.meta.path.dir 'raw_data/'];
    if ~exist(rawdir,'dir')
        mkdir(rawdir);
    end
    for i=1:length(opt.raw)
        
        % create new raw data object
        path = [rawdir expmt.meta.date opt.raw{i} '.bin'];
        expmt.data.(opt.raw{i}) = RawDataField;
        
        % delete any existing contents
        expmt.data.(opt.raw{i}).fID = fopen(path,'w');
        if expmt.data.(opt.raw{i}).fID ~= -1
            fclose(expmt.data.(opt.raw{i}).fID);
        end
        
        % intialize new raw file
        expmt.data.(opt.raw{i}).fID = fopen(path,'a');
        expmt.data.(opt.raw{i}).precision = 'single';
        expmt.data.(opt.raw{i}).dim = [expmt.meta.num_traces];
        expmt.data.(opt.raw{i}).path = path;
    end
end
        

% query available memory to determine how many batches to process data in
[~,msz] = memory;
msz = msz.PhysicalMemory.Available;
switch expmt.data.centroid.precision
    case 'double'
        cen_prcn = 8;
    case 'single'
        cen_prcn = 4;
end
bytes_per = 16;
rsz = expmt.meta.num_traces * expmt.meta.num_frames * (cen_prcn*2 + bytes_per);
nBatch = ceil(rsz/msz * 2);
bsz = ceil(expmt.meta.num_frames/nBatch);
    
%% calculate track properties
for j = 1:nBatch
    
    % get x and y coordinates of the centroid and normalize to ROI
    if j==nBatch
        inx = expmt.data.centroid.raw((j-1)*bsz+1:nf,:,1) - ...
            repmat(expmt.meta.roi.centers(:,1)',nf-(j-1)*bsz,1);
        iny = expmt.data.centroid.raw((j-1)*bsz+1:nf,:,2) - ...
            repmat(expmt.meta.roi.centers(:,2)',nf-(j-1)*bsz,1);
    else
        inx = expmt.data.centroid.raw((j-1)*bsz+1:j*bsz,:,1) - ...
            repmat(expmt.meta.roi.centers(:,1)',nf-(j-1)*bsz,1);
        iny = expmt.data.centroid.raw((j-1)*bsz+1:j*bsz,:,2) - ...
            repmat(expmt.meta.roi.centers(:,2)',nf-(j-1)*bsz,1);
    end
    
    % calculate speed        
    trackProps.speed = single([zeros(1,expmt.meta.num_traces); ...
        sqrt(diff(inx).^2+diff(iny).^2)]);   
    trackProps.speed(trackProps.speed > 12) = NaN;

    % calculate handedness dependencies and metrics
    if opt.handedness
        trackProps.Theta = single(atan2(iny,inx));
        trackProps.Direction = single([zeros(1,expmt.meta.num_traces); ...
            atan2(diff(iny),diff(inx))]);
        tmp(j) = getHandedness(trackProps);
    end    
    
    % write raw data from batch
    for i = 1:length(opt.raw)
        f = opt.raw{i};
        switch f
            case 'Direction',
                if ~opt.handedness
                    trackProps.Direction = ...
                        single([zeros(1,expmt.meta.num_traces); ...
                            atan2(diff(iny),diff(inx))]);
                end
            case 'Theta'
                if ~opt.handedness
                    trackProps.Theta = single(atan2(iny,inx));
                end
            case 'Radius'
                trackProps.Radius = sqrt(inx.^2 + iny.^2);
        end
        fwrite(expmt.data.(f).fID,trackProps.(f),expmt.data.(f).precision);
    end
    
    clear trackProps inx iny   
end


% close raw data and initialize new memmap for raw data
for i = 1:length(opt.raw)
    f = opt.raw{i};
    fclose(expmt.data.(f).fID);
    attach(expmt.data.(f));
end


% concatenate handedness data
if nBatch>1 && opt.handedness
    weight = NaN(expmt.meta.num_traces,nBatch);
    for i = 1:nBatch
        weight(:,i) = sum(tmp(i).include,2);
    end
    weight = weight ./ repmat(sum(weight,2),1,nBatch);
    
    for i = 1:nBatch
        tmp(i).angle_histogram = tmp(i).angle_histogram .* ...
            repmat(weight(:,i)',length(tmp(i).bins),1);
    end
    
    handedness = tmp(1);
    for i = 2:nBatch
        handedness.angle_histogram =  handedness.angle_histogram + ...
            tmp(i).angle_histogram ;
        handedness.include = [handedness.include tmp(i).include];
    end
    handedness.mu = -sin(sum(handedness.angle_histogram .*...
        repmat((handedness.bins' + handedness.bin_width/2),1,expmt.meta.num_traces)))';
    
    expmt.meta.handedness = handedness;
    
end
    
    



