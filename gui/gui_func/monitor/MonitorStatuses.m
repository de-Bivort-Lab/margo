classdef MonitorStatuses
    %MONITORSTATUSES Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        OFFLINE(0), ACTIVE(1), IDLE(2), ERROR(3), FLAMING_ELMO(4);
    end

    properties
        code (1,1) uint32;
    end

    methods
        function status = MonitorStatuses(code)
            status.code = code;
        end
    end
end

