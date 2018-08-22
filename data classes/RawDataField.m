classdef RawDataField < dynamicprops
% class definition for raw data maps container

    properties
        raw;
        path;
        fID;
        dim;
        precision;
    end
    
    properties(Hidden = true)
        Parent;
    end
    
    methods
        function obj = RawDataField(varargin)
            
            % set default values
            obj.raw = RawDataMap;
            obj.path = '';
            obj.precision = 'single';
            obj.dim = 0;
            obj.fID = -1;
            obj.Parent = [];
            
            % parse and assign variable inputs
            for i=1:length(varargin)
                if ischar(varargin{i})
                    switch varargin{i}
                        case 'Path'
                            i = i+1;
                            obj.path = varargin{i};
                        case 'Dim'
                            i = i+1;
                            obj.dim = varargin{i};
                        case 'Precision'
                            i = i+1;
                            obj.precision = varargin{i};
                        case 'fID'
                            i = i+1;
                            obj.fID = varargin{i};
                        case 'Parent'
                            i = i+1;
                            obj.Parent = varargin{i};
                    end
                end
            end
            
        end
            
            
        % initialize raw data memmap from raw data file
        function obj = attach(obj)
            try        
                
                if ~isfield(obj.Parent.meta,'num_traces')
                    obj.Parent.meta.num_traces = ...
                        sum(obj.Parent.meta.roi.num_traces);
                end
                
                % ensure correct dimensions
                nTraces = obj.Parent.meta.num_traces;
                nFrames = obj.Parent.meta.num_frames;
                valid_dim = [2 nTraces nFrames];
                obj.dim(~ismember(obj.dim,valid_dim)) = [];
                if isempty(obj.dim)
                    obj.dim = [nFrames 1];
                elseif numel(obj.dim) == 1 && obj.dim == nFrames;
                    obj.dim = [nFrames 1];
                elseif (any(obj.dim == obj.Parent.meta.num_traces) &&...
                        obj.dim(end) ~= nTraces) || ...
                        ~any(obj.dim == nFrames)
    
                    tmp_dim = [frame_dim ...
                        obj.dim(obj.dim~=nTraces & obj.dim~= nFrames) ...
                        nTraces];
                    obj.dim = tmp_dim;
                end
                
                if exist(obj.path,'file')==2
                    
                    fInfo = dir(obj.path);
                    if ~fInfo(1).bytes
                        return
                    end
                    
                    prcn = obj.precision;
                    if strcmpi(prcn,'logical')
                        attach_binary(obj);
                    else
                        obj.raw.map = memmapfile(obj.path,...
                            'Format',{pcn,fliplr(obj.dim),'raw'});
                    end

                    % resize if necessary
                    sz = size(obj.raw.map.Data);
                    if any(sz>1)
                        frame_num = sz(sz>1);
                        obj.dim = [frame_num obj.dim];
                        obj.raw.map = memmapfile(obj.path, ...
                            'Format',{obj.precision,fliplr(obj.dim),'raw'});
                    end
                end
                
            catch 
                % try to automatically repair the file path
                try
                    p = obj.Parent.meta.path;
                    updatepaths(obj.Parent,[p.dir p.name],false);
                    obj.raw.map = memmapfile(obj.path, ...
                                'Format',{obj.precision,fliplr(obj.dim),'raw'});
                catch ME
                    switch ME.identifier
                        case 'MATLAB:memmapfile:inaccessibleFile'
                            error(['Failed to initialize raw data map. '...
                                'No such file or directory:\n'...
                                '\t%s'],obj.path);
                    end
                end
            end
            if ~isattached(obj)
                error('failed to attach raw data map');
            end
            obj.raw.Parent = obj;
        end
        
        function obj = detach(obj)
            obj.raw.map = [];
        end
        
        function obj = reset(obj)
            detach(obj);
            attach(obj);
        end
        
        function obj = attach_binary(obj)
            
            obj.fID = fopen(obj.path,'r');           
            if obj.fID ~= -1
                obj.raw.map.Data.raw = ...
                    fread(obj.fID,fliplr(obj.dim),'logical=>logical');
                obj.raw.map.Format = {'logical'};
            else
                error('invalid fileID');
            end
            
        end
        
        function out = isattached(obj)
            try
                out = ~any(~size(obj.raw));
            catch
                out = false;
            end
        end
        
        function out  = size(obj)
            out = obj.dim;
            if numel(out) == 1
                out = [out 1];
            end
        end
        
        function addprops(obj,props)
            
            if ~iscell(props)
                props = {props};
            end
            
            % remove pre-existing properties from list
            exclude = cellfun(@(p) isprop(obj,p), props);
            props(exclude) = [];
            
            % initialize new properties
            if ~isempty(props)
                cellfun(@(p) addprop(obj,p), props, 'UniformOutput', false);
            end
            
        end
        

        
    end
    
    
    
    
    
end