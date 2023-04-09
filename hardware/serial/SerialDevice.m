classdef SerialDevice < SerialDeviceInterface
    %SERIALPORTDEVICE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access = private)
        deviceConstructor function_handle = SerialDevice.getConstructor();
        device;
    end

    properties(Constant, Access = private)
        SERIAL_FIRST_RELEASE = string('2006a');
        SERIAL_DEPRECATED_RELEASE = string('2022a');
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
            this.updateStatus();
        end

        function this = close(this)
            this.device.close();
            this.updateStatus();
        end

        function write(this, data, dataType)
            this.device.write(data, dataType);
        end

        function out = read(this, numBytes, dataType)
            out = this.device.read(numBytes, dataType);
        end
        
        function out = bytesAvailable(this)
            
           if this.isClosed() || this.device.isClosed()
               warning('No bytes available on serial port: %s because the port is not open.', this.port);
               out = 0;
               return;
           end
           
           if SerialDevice.isSerialDeprecated()
               out = this.device.bytesAvailable;
           else
               out = this.device.bytesAvailable;
           end
        end
        
        function updateStatus(this)
            this.status = this.device.status;
        end
    end

    methods(Static)

        function constructor = getConstructor()

            if SerialDevice.isSerialUnsupported()
                error('Cannot instantiate serial device. Serial not supported prior to %s', ...
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
                error('Cannot list serial devices. Serial not supported prior to %s', ...
                    SerialDevice.SERIAL_FIRST_RELEASE);
            end

            if SerialDevice.isSerialDeprecated()
                ports = arrayfun(@char, serialportlist('available'), 'UniformOutput', false);
            else
                serialInfo = instrhwinfo('serial');
                ports = serialInfo.AvailableSerialPorts;
            end
        end
        
        function isSerialUnsupported = isSerialUnsupported()
            isSerialUnsupported = MatlabVersionChecker.isReleaseOlderThan(SerialDevice.SERIAL_FIRST_RELEASE);
        end

        function isSerialDeprecated = isSerialDeprecated()
            isSerialDeprecated = ~MatlabVersionChecker.isReleaseOlderThan(SerialDevice.SERIAL_DEPRECATED_RELEASE);
        end
        
        function closeOpenConnections()
           if ~SerialDevice.isSerialDeprecated()
               delete(instrfindall);
           end
        end
    end
end

