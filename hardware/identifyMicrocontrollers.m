function [lightBoardPort,ports]=identifyMicrocontrollers

IR_white_panel_handshake=[1 1 0 0 1 0 1]';

if ~isempty(instrfindall)
fclose(instrfindall);           % Make sure that the COM port is closed
delete(instrfindall);           % Delete any serial objects in memory
end

% Detect available ports
serialInfo = instrhwinfo('serial');
ports=serialInfo.AvailableSerialPorts;
panelNum=[];

for i=1:size(ports,1)
    s = serial(ports{i});    % Create Serial Object
    set(s,'BaudRate',9600);         % Set baud rate
    fopen(s);                       % Open the port

    panel=2;
    level=2;
    writeData=char([level panel 23 23]);

    fwrite(s,writeData,'uchar');
    pause(0.25);
    
    if s.BytesAvailable>0
    handshake=fread(s,7);
        if sum(handshake==IR_white_panel_handshake)
            panelNum=i;
        end
    end
    
    fclose(s);
    delete(s);
end

if ~isempty(panelNum)
    lightBoardPort=ports(panelNum);
else
    lightBoardPort={'COM not detected'};
end
ports(panelNum)=[];
