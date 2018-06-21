classdef RawDataMap < handle
% class definition for raw data maps container
    
    properties (Hidden = true)
        map;
    end
    
    methods
        function obj = RawDataMap
                   
        end
        
        % indexing and return routines
        function out = subsref(obj,S)
            
            if isempty(obj.map)
                error(['raw data file unattached - run attach(RawDataMap)' ...
                        ' before indexing raw data']);
            else
                out = obj;
                for i=1:length(S)
                    switch S(i).type
                        case '()'
                            out = out.map.Data.raw(S.subs{fliplr(1:numel(S.subs))});
                            if numel(out) > 1
                                out = permute(out,fliplr(1:ndims(out)));
                            elseif isempty(out)
                                warning(sprintf(['RawDataMap is empty.'...
                                    'Must attach raw data file to access'...
                                    ' contents. To attach raw data, run:\n'
                                    '\tattach(RawDataField)']));
                            end
                        case '.'
                            out = out.(S(i).subs);
                        case '{}'
                            error(['Cell contents reference '...
                                'from a non-cell array object']);
                    end
                end
            end
            
        end       
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
        
        % size return functions
        function out = size(obj)
            if isempty(obj.map)
                out  = [];
            else
                out = fliplr(size(obj.map.Data.raw));
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
    
    
    
