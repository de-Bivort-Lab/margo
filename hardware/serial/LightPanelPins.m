classdef LightPanelPins
    %LIGHTPANELPINS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        pinNumber uint32;
    end

    properties(Constant, Access = private)
        WHITE_LIGHT_PIN_NUMBER uint32 = 9;
        INFRARED_LIGHT_PIN_NUMBER uint32 = 10; 
    end
    
    methods
        function this = LightPanelPins(pinNumber)
            this.pinNumber = pinNumber;
        end
    end

    enumeration
        WHITE(LightPanelPins.WHITE_LIGHT_PIN_NUMBER),
        INFRARED(LightPanelPins.INFRARED_LIGHT_PIN_NUMBER);
    end
end

