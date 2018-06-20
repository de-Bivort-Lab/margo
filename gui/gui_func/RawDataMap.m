classdef RawDataField < handle
% class definition for raw data maps container

    properties
        raw;
        path;
        fID;
        dim;
        precision;
    end
    
    properties (Hidden = true)
        map;
    end
    
    methods
        function obj = RawDataField(varargin)
            
            % set default values
            obj.path = '';
            obj.precision = 'single';
            obj.dim = 0;
            obj.fID = -1;
            
            % parse and assign variable inputs
            for i=1:length(varargin)
                if ischar(varargin{i})
                    switch varargin{i}
                        case 'Path'
                            i = i+1;
                            obj.path = varargin{i};
                        case 'Dim'
                            i = i+1;
                            obj.path = varargin{i};
                        case 'Precision'
                            i = i+1;
                            obj.path = varargin{i};
                        case 'fID'
                            i = i+1;
                            obj.path = varargin{i};
                    end
                end
            end
            
            
        end
        
        function obj = 
        
    end
    
    
    
    
end