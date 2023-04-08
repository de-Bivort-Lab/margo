classdef SerialDeviceInterface < handle
    %SERIALDEVICEINTERFACE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        port string;
        baudRate double = 9600;
        status SerialDeviceStatuses = SerialDeviceStatuses.CLOSED;
    end
    
    methods (Abstract)
        open;
        close;
        read;
        write;
    end

    methods

        function isOpen = isOpen(this)
            isOpen = this.status == SerialDeviceStatuses.OPEN;
        end

        function isClosed = isClosed(this)
            isClosed = this.status == SerialDeviceStatuses.CLOSED;
        end

    end
end

