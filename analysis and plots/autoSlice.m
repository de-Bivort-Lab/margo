function slice_data = autoSlice(expmt,f,roi_num)

% returns a single full frame number slice of the raw data field (f) and
% specified ROI (roi_num)


% renaming vars for shorthand
p = expmt.data.(f).precision;
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
expmt = updatefID(expmt,f);
fseek(expmt.data.(f).fID,(roi_num-1)*nb,'bof');
slice_data = fread(expmt.data.(f).fID,expmt.meta.num_frames,format,skip*nb);



