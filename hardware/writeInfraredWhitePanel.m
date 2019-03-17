function writeInfraredWhitePanel(COM_obj,panel,level)

% Write intensity values to either the infrared or white light channels of 
% the dual infrared/white LED illumination panels

% PANEL=0=IR, PANEL=1=White

if ~isempty(COM_obj)
    
    % open com device if it is currently close
    if strcmp(COM_obj.status,'closed')
        fclose(COM_obj);
        fopen(COM_obj);
    end
    
    % choose pin to write to
    if panel==0
        panel=10;   % infrared light pin
    else
        panel=9;    % white light pin
    end

    % send data
    writeData=char([level panel]);
    fwrite(COM_obj,writeData,'uchar');
    
end