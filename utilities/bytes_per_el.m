function n_bytes_per_element = bytes_per_el(precision)
% returns the number of bytes in each element for a given precision

% query bytes per element
switch precision
    case 'logical'
        n_bytes_per_element = 1/8;
    case 'uint8'
        n_bytes_per_element = 1;
    case 'char'
        n_bytes_per_element = 1;
    case 'int8'
        n_bytes_per_element = 1;
    case 'uint16'
        n_bytes_per_element = 2;
    case 'int16'
        n_bytes_per_element = 2;
    case 'uint32'
        n_bytes_per_element = 4;
    case 'int32'
        n_bytes_per_element = 4;
    case 'single'
        n_bytes_per_element = 4;
    case 'double'
        n_bytes_per_element = 8;
    case 'uint64'
        n_bytes_per_element = 8;
    case 'int64'
        n_bytes_per_element = 8;
    otherwise
        error('data is not numeric');
end