classdef SerialDevice < SerialDeviceInterface
    %SERIALPORTDEVICE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access = private)
        deviceConstructor (1,1) function_handle = getConstructor();
        device (1,1) handle;
    end

    properties(Constant)
        SERIAL_FIRST_RELEASE = "R2006a";
        SERIAL_DEPRECATED_RELEASE = "R2022a";
    end

    methods
        function this = SerialDevice(port, varargin)
            this.port = port;

            if (nargin > 1)
                this.baudRate = varargin{1};
            end

            this.constructDevice();
        end

        function constructDevice(this)
            this.device = this.deviceConstructor(this.port, this.baudRate);
        end
        
        function this = open(this)
            this.device.open();
        end

        function this = close(this)
            this.device.close();
        end

        function write(this, data, dataType)
            this.device.write(data, dataType);
        end

        function out = read(this, numBytes, dataType)
            out = this.device.read(numBytes, dataType);
        end
    end

    methods(Static)

        function constructor = getConstructor()

            if SerialDevice.isSerialUnsupported()
                error("Cannot instantiate serial device. Serial not supported prior to %s", ...
                    SerialDevice.SERIAL_FIRST_RELEASE);
            end

            if SerialDevice.isSerialDeprecated()
                constructor = @SerialDeviceR2022a;
            else
                constructor = @SerialDeviceR2006a;
            end
        end

        function ports = getAvailablePorts()
            if SerialDevice.isSerialUnsupported()
                error("Cannot list serial devices. Serial not supported prior to %s", ...
                    SerialDevice.SERIAL_FIRST_RELEASE);
            end

            if SerialDevice.isSerialDeprecated()
                ports = serialportlist();
            else
                serialInfo = instrhwinfo('serial');
                ports = serialInfo.AvailableSerialPorts;
            end
        end
        
        function isSerialUnsupported = isSerialUnsupported()
            isSerialUnsupported = isMATLABReleaseOlderThan(SerialDevice.SERIAL_FIRST_RELEASE);
        end

        function isSerialDeprecated = isSerialDeprecated()
            isSerialDeprecated = ~isMATLABReleaseOlderThan(SerialDevice.SERIAL_DEPRECATED_RELEASE);
        end
    end
end

