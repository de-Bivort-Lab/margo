function slice_data = autoSlice(expmt,f,roi_num)

% returns a single full frame number slice of the raw data field (f) and
% specified ROI (roi_num)


% renaming vars for shorthand
if isfield(expmt.(f),'precision')
    p = expmt.(f).precision;
elseif strcmp(f,'Speed')
    expmt.(f).precision = expmt.data.centroid.precision;
    p = expmt.(f).precision;
end
format = [p '=>' p];
skip = expmt.meta.num_traces - 1;

% query num bytes per data point
switch p
    case 'uint8',   nb = 1;
    case 'int8',    nb = 1;
    case 'uint16',  nb = 2;
    case 'int16',   nb = 2;
    case 'uint32',  nb = 4;
    case 'int32',   nb = 4;
    case 'single',  nb = 4;
    case 'double',  nb = 8;
    otherwise
        error('unsupported data precision');
end

% update fID if necessary
open_files = fopen('all');
if ~ismember(expmt.(f).fID,open_files)
    expmt = updatefID(expmt,f);
end

fseek(expmt.(f).fID,(roi_num-1)*nb,'bof');
slice_data = fread(expmt.(f).fID,expmt.meta.num_frames,format,skip*nb);



