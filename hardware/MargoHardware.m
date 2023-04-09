classdef MargoHardware < handle
    %MARGOHARDWARE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        cam struct = struct();
        COM ComHardware;
        light struct = struct();
        projector struct = struct();
    end
    
    methods
        function this = MargoHardware()
            this.COM = ComHardware();
        end
    end
end

