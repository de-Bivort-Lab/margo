function filtered_field = recursiveFilterFields(field,depth)
% Recursively search the ExperimentData object filter out MATLAB objects
% and other non-alphanumeric data types

% define valid data types
valid_objs = {'ExperimentData';'RawDataField';'struct'};
valid_data = {'logical';'char';'uint8';'int8';'uint16';'int16';...
    'uint32';'int32';'uint64';'int64';'single';'double'};
ignore = {'Parent';'Children'};

% set default status
filtered_field = [];

% update the recursion depth
depth = depth + 1;

% set recursion depth limit to prevent infinite recursion
if depth==5
    return
end

% parse field based on data type
if any(strcmpi(valid_data,class(field)))
    filtered_field = field;
    
% search each cell separately, only retain cells with valid data types
elseif iscell(field)
    filtered_field = cellfun(@(f) recursiveFilterFields(f, depth), field,...
        'UniformOutput', false);
    filtered_field(cellfun(@isempty, filtered_field)) = [];
    
% search each field/property of each object recursively
elseif any(strcmpi(valid_objs,class(field)))
    
    % convert object to struct and get property names
    props = struct(field);
    subfields = fieldnames(props);
    
    % search each property separately
    subfields(cellfun(@(sf) any(strcmpi(ignore,sf)), subfields)) = [];
    filtered_fields = cellfun(@(sf) recursiveFilterFields(props.(sf), depth),...
        subfields, 'UniformOutput', false);
    
    % create new fields from filter
    empty_field = cellfun(@isempty, filtered_fields);
    filtered_fields(empty_field) = [];
    subfields(empty_field) = [];
    filtered_field = [];
    for i=1:numel(subfields)
        filtered_field.(subfields{i}) = filtered_fields{i};
    end
end