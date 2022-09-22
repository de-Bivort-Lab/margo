function [lightBoard,ports,devices]=identifyMicrocontrollers

IR_white_panel_handshake=[1 1 0 0 1 0 1]';

if ~isempty(instrfindall)
    fclose(instrfindall);           % Make sure that the COM port is closed
    delete(instrfindall);           % Delete any serial objects in memory
end

% Detect available ports
serialInfo = instrhwinfo('serial');
ports=serialInfo.AvailableSerialPorts;
panelNum=[];
devices = cell(numel(ports),1);

if ~isempty(ports)
    for i=1:size(ports,1)

        serial_obj = serial(ports{i});    % Create Serial Object
        set(serial_obj ,'BaudRate',9600);         % Set baud rate
        try
            fopen(serial_obj);                       % Open the port
            devices{i} = serial_obj;

            panel=2;
            level=2;
            writeData=char([level panel 23 23]);

            fwrite(serial_obj ,writeData,'uchar');
            pause(0.1);

            if serial_obj.BytesAvailable == numel(IR_white_panel_handshake)
            handshake=fread(serial_obj,7);
                if length(handshake) == length(IR_white_panel_handshake)
                    panelNum=i;
                end
            end

            if strcmpi(serial_obj.Status,'open')
                fclose(serial_obj);
            end
        catch
            ports{i} = [ports{i} ' (unavailable)'];
        end
    end
end

% remove empty devices from list
devices = devices(~cellfun(@isempty, devices));

if ~isempty(panelNum)
    lightBoard = devices{panelNum};
    if strcmpi(lightBoard.Status,'closed')
       fopen(lightBoard); 
    end
elseif ~isempty(devices)
    lightBoard = devices{1};
else
    lightBoard = [];
end
