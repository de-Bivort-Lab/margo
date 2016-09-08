function writeInfraredWhitePanel(COM_port,panel,level)

% Write intensity values to either the infrared or white light channels of 
% the dual infrared/white LED illumination panels

% PANEL=0=IR, PANEL=1=White

no_COM={'COM not detected'};

if sum(COM_port{:})~=sum(no_COM{:})

s = serial(COM_port{:});    % Create Serial Object
    set(s,'BaudRate',9600);         % Set baud rate
    fopen(s);                       % Open the port
    
    if panel==0
        panel=9;
    else
        panel=10;
    end

    writeData=char([level panel]);
    fwrite(s,writeData,'uchar');
    
    fclose(s);              % Close and delete COM object
    delete(s);
end