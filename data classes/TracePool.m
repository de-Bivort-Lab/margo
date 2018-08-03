classdef TracePool < matlab.mixin.Copyable
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
        function obj = TracePool(n, max_num, max_duration, varargin)
            
            setMax(obj,max_num(1));
            obj.max_duration  = max_duration;
            obj.max_num = max_num(1);
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
            
            out = [];
            for i = 1:n
                tmp = copy(obj);
                if numel(max_num)>1
                    setMax(tmp,max_num(i));
                end
                out = [out;tmp];
            end

            obj = out;
        end
        
        function updateDuration(obj)
            
            mm = obj.max_duration;
            obj.duration(obj.updated) = obj.duration(obj.updated) + 1;
            obj.duration(~obj.updated) = obj.duration(~obj.updated) - 1;
            obj.duration(obj.duration > mm) = mm;
            obj.duration(obj.duration == 0) = NaN;
            active = obj.duration > 0;
            
            if obj.bounded
                obj.cen(~active,:) = NaN;
                obj.t(~active,:) = NaN;
                obj.updated(~active) = false;
            else
                obj.cen(~active,:) = [];
                obj.t(~active) = [];
                obj.updated(~active) = [];
                obj.duration(~active) = [];
            end
        end
        
        function reviveTrace(obj, new_cen, new_t)
            
            if ~obj.bounded
                return
            end
            if iscell(new_cen)
                new_cen = new_cen{1};
            end
            if ~isempty(new_cen)
                dead_traces = find(isnan(obj.cen(:,1)), size(new_cen,1), 'first');
                obj.cen(dead_traces,:) = new_cen(1:numel(dead_traces),:);
                obj.duration(dead_traces) = obj.max_duration;
                obj.t(dead_traces) = new_t;
            end
        end
        
        function setMax(obj, max_num)
            
            obj.cen = single(NaN(max_num,2));
            obj.t = single(NaN(max_num,1));
            obj.duration = single(NaN(max_num,1));
            obj.updated = false(max_num,1);
            obj.max_num = max_num;
        end
        
    end   

        
end
    
    
    