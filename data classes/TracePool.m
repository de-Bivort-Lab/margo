classdef TracePool < handle
% class definition for raw data maps container
    
    properties
        cen;
        t;
        duration;
        updated;
    end
    
    properties (Hidden = true)
        max_num;
        max_duration;
        bounded;
    end
    
    methods
        function obj = TracePool(n, max_duration, varargin)
            
            obj.cen = single(NaN(n,2));
            obj.t = single(NaN(n,1));
            obj.duration = single(NaN(n,1));
            obj.updated = false(n,1);
            obj.max_duration  = max_duration;
            obj.max_num = n;
            obj.bounded = true;
            
            for i = 1:numel(varargin)
                arg = varargin{i};
                switch arg
                    case 'Bounded'
                        i = i+1;
                        obj.bounded = varargin{i};
                end
            end
            
            if ~obj.bounded
                obj.max_num = -1;              
            end
            
        end
    end   

        
end
    
    
    
