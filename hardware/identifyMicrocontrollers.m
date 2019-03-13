function [lightBoard,ports]=identifyMicrocontrollers

IR_white_panel_handshake=[1 1 0 0 1 0 1]';

if ~isempty(instrfindall)
    fclose(instrfindall);           % Make sure that the COM port is closed
    delete(instrfindall);           % Delete any serial objects in memory
end

% Detect available ports
serialInfo = instrhwinfo('serial');
ports=serialInfo.AvailableSerialPorts;
panelNum=[];

if ~isempty(ports)
    for i=1:size(ports,1)

        s = serial(ports{i});    % Create Serial Object
        set(s,'BaudRate',9600);         % Set baud rate
        try
            fopen(s);                       % Open the port

            panel=2;
            level=2;
            writeData=char([level panel 23 23]);

            fwrite(s,writeData,'uchar');
            pause(0.1);

            if s.BytesAvailable == numel(IR_white_panel_handshake)
            handshake=fread(s,7);
                if length(handshake) == length(IR_white_panel_handshake)
                    panelNum=i;
                end
            end

            fclose(s);
            delete(s);
        catch
            ports{i} = [ports{i} ' (unavailable)'];
        end
    end
end

if ~isempty(panelNum)
    lightBoard = serial(ports{panelNum});
else
    lightBoard = [];
end
