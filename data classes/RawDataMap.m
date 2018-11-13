classdef RawDataMap < handle
% class definition for raw data maps container
    
    properties (Hidden = true)
        map;
        Parent;
    end
    
    methods
        function obj = RawDataMap
                   
        end
        
        % indexing and return routines
        function out = subsref(obj,S)
            
            is_subscripting = any(arrayfun(@(s) s.type~='.',S));
            if (isempty(obj.map) || ~isattached(obj.Parent)) &&...
                    is_subscripting
                try
                    attach(obj.Parent);
                catch
                    warning(['could not attach raw data map - run '...
                        'attach(RawDataMap) before indexing raw data']);
                end
            end

            out = obj;
            for i=1:length(S)
                switch S(i).type
                    case '()'
                        out = arrayindex(obj,S(i).subs);
                    case '.'
                        out = out.(S(i).subs);
                    case '{}'
                        error(['Cell contents reference '...
                            'from a non-cell array object']);
                end
            end        
        end
        
        % overload indexing
        function out = arrayindex(obj,s)
            
            if ~isattached(obj.Parent)
               [~,field_name,~] = fileparts(obj.Parent.path);
               field_name = field_name(find(field_name=='_',1,'Last')+1:end);
               msg = ['%s raw data field is not attached, '...
                   'run attach(expmt.data.%s) before accessing contents'];
               error(msg,field_name, field_name);
            end
            % pull raw data from memmap using subscripts (s)
            switch numel(s)
                case 0
                    out = obj.map.Data.raw(:,:,:,:,:,:);
                    out = squeeze(permute(out,fliplr(1:ndims(out))));
                case 1
                    out = obj.map.Data.raw(:,:,:,:,:,:);
                    out = squeeze(permute(out,fliplr(1:ndims(out))));
                    out = out(s{:});
                otherwise
                    out = obj.map.Data.raw(s{fliplr(1:numel(s))});

                    if numel(out) > 1 && sum(size(out)>1)>1 || numel(s) > 1
                        out = squeeze(permute(out,fliplr(1:ndims(out))));
                    elseif isempty(out)
                        warning(sprintf(['RawDataMap is empty.'...
                        'Must attach raw data file to access'...
                        ' contents. To attach raw data, run:\n'
                        '\tattach(RawDataField)']));
                    end
            end
        end
        
        % default display behavior
        function ans = display(obj)
            
            if isempty(obj.map)
                warning(sprintf(['RawDataMap is empty.'...
                    ' Must attach raw data file to access'...
                    ' contents. To attach raw data, run:\n'...
                    '\tattach(RawDataField)']));
                ans = []
            else
                switch ndims(obj.map.Data.raw)
                    case 1
                        ans = sprintf(['\traw data file\n\n' ...
                                '\tsize: \t\t(%ix1)\n'...
                                '\tprecision: \t%s\n'],...
                                size(obj.map.Data.raw,1),...
                                obj.map.Format{1})
                    case 2
                        ans = sprintf(['\traw data file\n\n' ...
                                '\tsize: \t\t(%ix%i)\n'...
                                '\tprecision: \t%s\n'],...
                                size(obj.map.Data.raw,2),...
                                size(obj.map.Data.raw,1),...
                                obj.map.Format{1})
                    case 3
                        ans = sprintf(['\traw data file\n\n' ...
                                '\tsize: \t\t(%ix%ix%i)\n'...
                                '\tprecision: \t%s\n'],...
                                size(obj.map.Data.raw,3),...
                                size(obj.map.Data.raw,2),...
                                size(obj.map.Data.raw,1),...
                                obj.map.Format{1})
                end
            end
        end
        
        % query parent properties
        
        % elemtemt-wise subtraction
        function out = minus(a,b)
            switch class(a)
                case 'RawDataMap'
                    out = a.map.Data.raw;
                    out = squeeze(permute(out,fliplr(1:ndims(out))));
                    out = out - b;
                otherwise
                    out = b.map.Data.raw;
                    out = squeeze(permute(out,fliplr(1:ndims(out))));
                    out = a - out;
            end
        end
        
        % element-wise addition
        function out = plus(a,b)
            switch class(a)
                case 'RawDataMap'
                    out = a.map.Data.raw;
                    out = squeeze(permute(out,fliplr(1:ndims(out))));
                    out = out + b;
                otherwise
                    out = b.map.Data.raw;
                    out = squeeze(permute(out,fliplr(1:ndims(out))));
                    out = a + out;
            end
        end
        
        % element-wise multiplication
        function out = times(a,b)
            switch class(a)
                case 'RawDataMap'
                    out = a.map.Data.raw;
                    out = squeeze(permute(out,fliplr(1:ndims(out))));
                    out = out .* b;
                otherwise
                    out = b.map.Data.raw;
                    out = squeeze(permute(out,fliplr(1:ndims(out))));
                    out = a .* out;
            end
        end
        
        % element-wise division
        function out = rdivide(a,b)
           switch class(a)
                case 'RawDataMap'
                    out = a.map.Data.raw;
                    out = squeeze(permute(out,fliplr(1:ndims(out))));
                    out = out ./ b;
                otherwise
                    out = b.map.Data.raw;
                    out = squeeze(permute(out,fliplr(1:ndims(out))));
                    out = a ./ out;
            end 
        end
        
        % size return functions
        function out = size(obj,varargin)
                if isempty(obj.map)
                    out  = [0 1];
                else
                    out = fliplr(size(obj.map.Data.raw,varargin{:})); 
                    if out(1)==1
                        out = fliplr(out);
                    end
                end
        end
        function out = numel(obj)
            if isempty(obj.map)
                out  = 0;
            else
                out = numel(obj.map.Data.raw);
            end
        end
        function out = length(obj)
            if isempty(obj.map)
                out  = 0;
            else
                out = length(obj.map.Data.raw);
            end
        end
        % override nargout assignment
        function n = numArgumentsFromSubscript(obj,S,indexingContext)
            switch S(1).type
                case '.'
                   n = 1;
                case '()'
                    n = 1;
            end
            
        end
    end   

        
end
    
    
    
