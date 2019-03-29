function [expmt] = processCentroid(expmt,opt)


% initialize tracking properties struct
nf = expmt.meta.num_frames;

del = addRawDataFiles(opt.raw, expmt);
is_speed = cellfun(@(nf) strcmpi(nf,'speed'), opt.raw);
opt.raw(is_speed) = {'speed'};

% remove existing raw data fields
for i=1:numel(del)
    if numel(opt.raw) >= del(i)
        opt.raw(del)=[];
    end
    if numel(expmt.meta.options.raw) >= del(i)
        expmt.meta.options.raw(del) = [];
    end
end
if isempty(opt.raw) && ~opt.handedness
    return
end
        

% query available memory to determine how many batches to process data in
bytes_available = bytesAvailableMemory;
switch expmt.data.centroid.precision
    case 'double'
        cen_prcn = 8;
    case 'single'
        cen_prcn = 4;
end
bytes_per = 16;
rsz = expmt.meta.num_traces * expmt.meta.num_frames * (cen_prcn*2 + bytes_per);
nBatch = ceil(rsz/bytes_available * 2);
bsz = ceil(expmt.meta.num_frames/nBatch);
    
%% calculate track properties
msg = 'batch %i of %i';
hwb = waitbar(0,sprintf(msg,0,nBatch),'Name','Processing Centroid Data');
for j = 1:nBatch
    
    if ishghandle(hwb)
        hwb = waitbar((j-1)/nBatch,hwb,sprintf(msg,j,nBatch));
    end
    % refresh centroid data map
    detach(expmt.data.centroid);
    attach(expmt.data.centroid);
    
    % get x and y coordinates of the centroid and normalize to ROI
    if j==nBatch
        inx = expmt.data.centroid.raw((j-1)*bsz+1:nf,1,:) - ...
            repmat(expmt.meta.roi.centers(:,1)',nf-(j-1)*bsz,1);
        iny = expmt.data.centroid.raw((j-1)*bsz+1:nf,2,:) - ...
            repmat(expmt.meta.roi.centers(:,2)',nf-(j-1)*bsz,1);
    else
        inx = expmt.data.centroid.raw((j-1)*bsz+1:j*bsz,1,:) - ...
            repmat(expmt.meta.roi.centers(:,1)',bsz,1);
        iny = expmt.data.centroid.raw((j-1)*bsz+1:j*bsz,2,:) - ...
            repmat(expmt.meta.roi.centers(:,2)',bsz,1);
    end
    
    % calculate speed        
    trackProps.speed = single([zeros(1,expmt.meta.num_traces); ...
        sqrt(diff(inx).^2+diff(iny).^2)]);
    trackProps.speed = trackProps.speed .* expmt.parameters.mm_per_pix;

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
        if j==1
            fprintf('\n\tgenerating new %s raw data file',f);
            fprintf(['\n\tprocessing times may be slow'...
                ' for large tracking sessions']);
        end
        switch f
            case 'Direction'
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
                trackProps.Radius = single(sqrt(inx.^2 + iny.^2));
        end
        fwrite(expmt.data.(f).fID,trackProps.(f)',expmt.data.(f).precision);
        trackProps.(f) = [];
    end
    
    clear trackProps inx iny   
end

% close waitbar
if ishghandle(hwb)
    delete(hwb);
end

% clear centroid map
detach(expmt.data.centroid);

% close raw data and initialize new memmap for raw data
for i = 1:length(opt.raw)
    f = opt.raw{i};
    fclose(expmt.data.(f).fID);
    attach(expmt.data.(f));
end

% re-inititialize maps
reset(expmt);

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
        repmat((handedness.bins' + handedness.bin_width/2),...
            1,expmt.meta.num_traces)))';
    
    expmt.meta.handedness = handedness;

elseif exist('tmp','var')
    expmt.meta.handedness = tmp;
end


    
    



