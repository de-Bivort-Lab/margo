classdef ComHardware < handle
    %MARGOHARDWARE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        light SerialDevice;
        aux SerialDevice;
        ports cell;
        devices SerialDevice;
        settings;
        statuses SerialDeviceStatuses;
    end

    properties(Constant, Access = private)
        HANDSHAKE logical = [true true false false true false true];
        HANDSHAKE_PANEL uint8 = 2;
        HANDSHAKE_LEVEL uint8 = 2;
    end
    
    methods
        function this = ComHardware()
            this.updatePortsList();
        end

        function findDevices(this)
                        
            % Detect available ports
            this.closeOpenConnections();
            this.updatePortsList();
            
            for i = 1:size(this.ports, 1)
                this.devices(i) = SerialDevice(this.ports{i});
                isSuccessful = ComHardware.handshakeDevice(this.devices(i));
                if isSuccessful
                    this.light = this.devices(i);
                    this.light.open();
                end
            end
            
        end

        function closeOpenConnections(this)
            for i = 1:numel(this.devices)
                this.devices(i).close();
            end
            SerialDevice.closeOpenConnections();
        end

        function updatePortsList(this)
            this.ports = SerialDevice.getAvailablePorts();
        end

        function writeLightPanel(this, lightPanel, value)

            if isempty(this.light)
                warning('Cannot write light panel: %s. No light panel set.', lightPanel);
                return;
            end

            if this.light.isClosed()
                this.light.open();
            end

            this.light.write(char([value lightPanel.pinNumber]), 'char');
        end

        function objectToSave = saveobj(this)
            objectToSave = ComHardware();
            objectToSave.ports = this.ports;
        end
    end

    methods(Static, Access = private)
        function isHandshakeSuccessful = handshakeDevice(device)

            try
                device.open();
                writeData = char([ComHardware.HANDSHAKE_LEVEL ComHardware.HANDSHAKE_PANEL 0 0]);
                pause(2);
                device.write(writeData, 'char');
                pause(0.1);
        
                if device.bytesAvailable ~= numel(ComHardware.HANDSHAKE)
                    isHandshakeSuccessful = false;
                    device.close();
                    return;
                end

                handshake = device.read(numel(ComHardware.HANDSHAKE), 'uint8');
                device.close();
                isHandshakeSuccessful = all(handshake == ComHardware.HANDSHAKE);
            catch exception
                warning('Serial device handshake failed on port: %s. Skipping port.', device.port);
                device.close();
                isHandshakeSuccessful = false;
            end
        end
    end
end


