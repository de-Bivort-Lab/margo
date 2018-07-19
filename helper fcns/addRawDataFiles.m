function file_exists = addRawDataFiles(new_fields, expmt)
% generates new raw data files and associated RawDataFields parented under 
% expmt for the field names in new_fields 

fclose('all');

if ~iscell(new_fields)
    new_fields = {new_fields};
end

% initialize raw data files if necessary
file_exists = [];
if ~isempty(new_fields)
    
    % intialize raw data directory
    rawdir = [expmt.meta.path.dir 'raw_data/'];
    if ~exist(rawdir,'dir')
        mkdir(rawdir);
    end
    for i=1:length(new_fields)
        
        % create new raw data object
        f = new_fields{i};
        path = [rawdir expmt.meta.date '_' f '.bin'];
        
        % delete any existing contents
        if ~any(strcmpi(fieldnames(expmt.data),f))      
            initialize = true;     
            
        elseif exist(path,'file')==2
            
            finfo = dir(path);
            if finfo.bytes
                initialize = false;
            else
                initialize = true;
            end
        end
        
        if initialize

            expmt.data.(new_fields{i}) = RawDataField('Parent',expmt);
            expmt.data.(new_fields{i}).fID = fopen(path,'w');
            expmt.data.(new_fields{i}).precision = 'single';
            expmt.data.(new_fields{i}).dim = ...
                [expmt.meta.num_frames expmt.meta.num_traces];
            expmt.data.(new_fields{i}).path = path;
        else
            file_exists = [file_exists i];
        end
    end
end

fn = fieldnames(expmt.data);
if size(new_fields,2) > size(new_fields,1)
    new_fields = new_fields';
end
expmt.meta.fields = unique([fn;new_fields]);