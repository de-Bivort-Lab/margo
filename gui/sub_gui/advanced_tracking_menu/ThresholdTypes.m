classdef ThresholdTypes
    %THRESHOLDTYPES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name (1,1) string;
    end
    
    methods
        function this = ThresholdTypes(name)
            this.name = name;
        end
    end

    enumeration
        FLAT("flat"), DYNAMIC("dynamic");
    end
end

