classdef SerialDeviceStatuses
    %SERIALDEVICESTATUSES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        status string;
    end
    
    methods
        function this = SerialDeviceStatuses(status)
            this.status = status;
        end
    end

    enumeration
        OPEN(string('open')), CLOSED(string('closed'));
    end
end

