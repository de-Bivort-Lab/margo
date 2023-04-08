function [lightBoard, ports, devices]=identifyMicrocontrollers

LIGHT_PANEL_HANDSHAKE = [1 1 0 0 1 0 1]';

% Detect available ports
ports = SerialDevice.getAvailablePorts();
panelNum=[];
devices = cell(numel(ports),1);
BAUD_RATE = 9600;
HANDSHAKE_PANEL_VAL = 2;
HANDSHAKE_LEVEL_VAL = 2;

if ~isempty(ports)
    for i = 1:size(ports,1)

        try
            serialDevice = SerialDevice(ports{i}, BAUD_RATE);
            serialDevice.open();

            devices{i} = serialDevice;
    
            writeData = char([HANDSHAKE_LEVEL_VAL HANDSHAKE_PANEL_VAL 23 23]);
            serialDevice.write(writeData, 'char');
            pause(0.1);
    
            if serialDevice.bytesAvailable == numel(LIGHT_PANEL_HANDSHAKE)
                handshake = serialDevice.read(numel(LIGHT_PANEL_HANDSHAKE));
                if all(handshake == LIGHT_PANEL_HANDSHAKE)
                    panelNum = i;
                end
            end

            serialDevice.close();

        catch
            serialDevice.close();
            ports{i} = strcat(ports{i}, ' (unavailable)');
        end

    end
end

% remove empty devices from list
devices = devices(~cellfun(@isempty, devices));

if ~isempty(panelNum)
    lightBoard = devices{panelNum};
    lightBoard.open();
elseif ~isempty(devices)
    lightBoard = devices{1};
    lightBoard.open();
else
    lightBoard = [];
end
