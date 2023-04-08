classdef SerialDeviceR2022a < SerialDeviceInterface
    %SERIALPORTDEVICE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access = private)
        serialDevice handle;
    end

    methods
        function this = SerialDeviceR2022a(port, varargin)
            this.port = port;

            if (nargin > 1)
                this.baudRate = varargin{1};
            end
        end
        
        function this = open(this)

            if this.isOpen()
                return;
            end

            try
                this.serialDevice = serialport(this.port, this.baudRate);
                this.status = SerialDeviceStatuses.OPEN;
            catch exception
                warning('Failed to open serial device on port: %s', this.port);
                rethrow(exception);
            end
        end

        function this = close(this)

            if this.isClosed()
                return;
            end

            try
                delete(this.serialDevice);
                this.status = SerialDeviceStatuses.CLOSED;
            catch exception
                warning('Failed to close serial device on port: %s', this.port);
                rethrow(exception);
            end
        end

        function write(this, data, dataType)

            if this.isClosed()
                error('Cannot write data over serial port: %s. Connection is closed.', this.port);
            end

            try
                this.serialDevice.write(data, dataType);
            catch exception
                warning('Serial write failed on port: %s.', this.port);
                rethrow(exception);
            end
            
        end

        function out = read(this, numBytes, dataType)

            if this.isClosed()
                error('Cannot read data over serial port: %s. Connection is closed.', this.port);
            end

            try
                out = this.serialDevice.read(numBytes, dataType);
            catch exception
                warning('Serial read failed on port: %s.', this.port);
                rethrow(exception);
            end
            
        end

        function out = bytesAvailable(this)
            out = this.serialDevice.NumBytesAvailable;
        end
    end
end

