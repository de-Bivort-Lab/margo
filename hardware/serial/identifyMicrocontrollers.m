function [lightBoard, ports, devices]=identifyMicrocontrollers

LIGHT_PANEL_HANDSHAKE = [1 1 0 0 1 0 1]';

% Detect available ports
ports = serialportlist();
panelNum=[];
devices = cell(numel(ports),1);
BAUD_RATE = 9600;
HANDSHAKE_PANEL_VAL = 2;
HANDSHAKE_LEVEL_VAL = 2;

if ~isempty(ports)
    for i=1:size(ports,1)

        try
            serialPortObj = serialport(ports{i}, BAUD_RATE);    % Create Serial Object
            devices{i} = serialPortObj;
    
            writeData = char([HANDSHAKE_LEVEL_VAL HANDSHAKE_PANEL_VAL 23 23]);
            serialPortObj.writeline(writeData);
            pause(0.1);
    
            if serialPortObj.NumBytesAvailable == numel(LIGHT_PANEL_HANDSHAKE)
                handshake = serialPortObj.read(numel(LIGHT_PANEL_HANDSHAKE));
                if all(handshake == LIGHT_PANEL_HANDSHAKE)
                    panelNum = i;
                end
            end
        catch
            ports{i} = strcat(ports{i}, ' (unavailable)');
        end

    end
end

% remove empty devices from list
devices = devices(~cellfun(@isempty, devices));

if ~isempty(panelNum)
    lightBoard = devices{panelNum};
elseif ~isempty(devices)
    lightBoard = devices{1};
else
    lightBoard = [];
end
