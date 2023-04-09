function writeVibrationalMotors(COM_obj,motor_pin,duration,interval,number,amplitude)


if ~isempty(COM_obj)
    
    % open com device if it is currently close
    if strcmp(COM_obj.status,'closed')
        set(COM_obj,'BaudRate',9600);
        fopen(COM_obj);
    end

    % send data
    writeData=char(uint8([2 motor_pin 1 number duration interval amplitude]));
    fwrite(COM_obj,writeData,'uchar');
    
end