classdef RawDataMap < handle
% class definition for raw data maps container
    
    properties (Hidden = true)
        map;
    end
    
    methods
        function obj = RawDataMap
                   
        end
        
        function out = subsref(obj,S)
            
            if isempty(obj.map)
                error(['raw data file unattached - run attach(RawDataMap)' ...
                        ' before indexing raw data']);
            end
        end
        
        function ans = display(obj)
            
            if isempty(obj.map)
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
                                size(obj.map.Data.raw,1),...
                                size(obj.map.Data.raw,2),...
                                obj.map.Format{1})
                    case 3
                        ans = sprintf(['\traw data file\n\n' ...
                                '\tsize: \t\t(%ix%ix%i)\n'...
                                '\tprecision: \t%s\n'],...
                                size(obj.map.Data.raw,1),...
                                size(obj.map.Data.raw,2),...
                                size(obj.map.Data.raw,3),...
                                obj.map.Format{1})
                end
            end
        end
        
    end
    
    
    
    
end