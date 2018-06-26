function expmt = getRawData(expmt)

% attempt to autofix aborted expmt files
if ~isfield(expmt.meta,'num_frames')
    
    expmt = updatefID(expmt,'time'); 
    attach(expmt.data.time);
    expmt.meta.num_frames = expmt.data.time.dim(1);
    
end
    

%% sequentially initialize raw data maps for each field

for i = 1:length(expmt.meta.fields) 
 
    f = expmt.meta.fields{i};
    expmt = updatefID(expmt,f);
    prcn = expmt.data.(f).precision;
    
    % initialize the memmap
    switch prcn
        % just read raw data if data is logical
        case 'logical'
            dim = expmt.data.(f).dim;
            dim(find(dim==1,1,'last'))=[];
            
            if ~any(expmt.data.(f).dim == expmt.meta.num_frames)
                dim = [dim expmt.meta.num_frames];
            end
            
            expmt.(f).data = fread(expmt.(f).fID,dim,'logical=>logical');
            expmt.data.(f).dim = dim;
            
        % otherwise create a raw data map
        otherwise
            attach(expmt.data.(f));
            
    end
    
end

